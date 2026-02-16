#!/usr/bin/env python3
"""
OCR Service - Flask HTTP server for equation recognition
Uses pix2tex (LaTeX-OCR) for local offline equation recognition.
Runs on port 5002, separate from SymPy service (5001).

Pipeline: Image → pix2tex → LaTeX string → SymPy validation → canonical expression
OCR is input only — no math evaluation happens here.
"""

from flask import Flask, request, jsonify
from PIL import Image
import base64
import io
import time
import traceback
import numpy as np

# SymPy LaTeX parser for validation and standardization
try:
    from sympy.parsing.latex import parse_latex
    from sympy import simplify as sympy_simplify
    # Helper imports for fallback validation
    from sympy import Symbol, Function, sin, cos, tan, log, ln, sqrt, exp, pi, E
    from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
    SYMPY_AVAILABLE = True
    print("SymPy modules loaded successfully")
except ImportError as e:
    SYMPY_AVAILABLE = False
    print(f"WARNING: SymPy components missing: {e}")

import ast


app = Flask(__name__)

# Lazy-load the model to avoid slow startup blocking health checks
_model = None

def get_model():
    """Lazy-load pix2tex LaTeX-OCR model."""
    global _model
    if _model is None:
        try:
            from pix2tex.cli import LatexOCR
            _model = LatexOCR()
            print("OCR model loaded successfully")
        except ImportError:
            print("ERROR: pix2tex not installed. Run: pip install pix2tex")
            raise
        except Exception as e:
            print(f"ERROR loading OCR model: {e}")
            raise
    return _model


def prepare_for_ocr(image: Image.Image) -> Image.Image:
    """
    Robustly prepare a PIL Image for pix2tex OCR.
    
    Handles RGBA, LA, P (palette), and other modes by compositing
    onto a white background before converting to RGB. This prevents
    the OpenCV cvtColor assertion that fires when pix2tex receives
    an image with unexpected channels or an empty numpy array.
    """
    # Handle palette images first (convert to their true mode)
    if image.mode == 'P' or image.mode == 'PA':
        image = image.convert('RGBA')
    
    # Composite images with alpha onto white background
    if image.mode in ('RGBA', 'LA'):
        background = Image.new('RGB', image.size, (255, 255, 255))
        # Use the alpha channel as mask
        if image.mode == 'LA':
            image = image.convert('RGBA')
        background.paste(image, mask=image.split()[3])  # 3 = alpha channel
        image = background
    elif image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Validate the image converts to a proper numpy array
    arr = np.array(image)
    if arr.size == 0 or arr.ndim < 2:
        raise ValueError("Image converted to an empty or invalid array")
    
    # Ensure 3-channel uint8 (what pix2tex/OpenCV expects)
    if arr.ndim == 2:
        # Grayscale — stack to 3 channels
        arr = np.stack([arr, arr, arr], axis=-1)
        image = Image.fromarray(arr, 'RGB')
    elif arr.ndim == 3 and arr.shape[2] != 3:
        # Wrong channel count — force RGB
        image = image.convert('RGB')
    
    return image


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'ok',
        'service': 'ocr',
        'model_loaded': _model is not None
    })


@app.route('/recognize', methods=['POST'])
def recognize():
    """
    Recognize equation from image.
    
    Expects JSON body:
    {
        "image": "<base64-encoded image data>",
        "format": "png"  // optional, default png
    }
    
    Returns:
    {
        "expression": "\\frac{a}{b} + c",
        "latex": "\\frac{a}{b} + c",
        "confidence": 0.95,
        "processing_time_ms": 234.5
    }
    """
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return error_response("Missing 'image' field in request body")
        
        start_time = time.time()
        
        # Decode base64 image
        try:
            image_bytes = base64.b64decode(data['image'])
            image = Image.open(io.BytesIO(image_bytes))
        except Exception as e:
            return error_response(f"Invalid image data: {str(e)}")
        
        # Robust image preparation (handles RGBA, palette, grayscale, etc.)
        try:
            image = prepare_for_ocr(image)
        except Exception as e:
            return error_response(f"Image preprocessing failed: {str(e)}")
        
        # Run OCR
        try:
            model = get_model()
            latex_result = model(image)
        except Exception as e:
            err_str = str(e)
            if 'cvtColor' in err_str or 'cv2' in err_str.lower() or '_src.empty()' in err_str:
                return error_response(
                    f"OCR image processing error — the image may be corrupted or unsupported. Details: {err_str}", 500
                )
            return error_response(f"OCR recognition failed: {err_str}", 500)
        
        processing_time = (time.time() - start_time) * 1000
        
        # Check if result is empty or likely garbage
        if not latex_result or len(latex_result.strip()) == 0:
            return error_response("No equation detected in image")
        
        # Clean up the result
        latex_clean = clean_latex_output(latex_result)
        
        # Basic confidence heuristic based on result characteristics
        confidence = estimate_confidence(latex_clean)
        
        # SymPy validation and canonical expression
        canonical, validated = validate_and_canonicalize(latex_clean)
        
        # Boost confidence if SymPy validated, penalize if not
        if validated:
            confidence = min(1.0, confidence + 0.1)
        elif SYMPY_AVAILABLE:
            confidence = max(0.0, confidence - 0.15)
        
        response = {
            'expression': canonical if validated else latex_clean,
            'latex': latex_clean,
            'canonical_expression': canonical,
            'validated': validated,
            'confidence': round(confidence, 3),
            'processing_time_ms': round(processing_time, 3)
        }
        
        #if DEBUG
        print(f"OCR result: latex='{latex_clean}', canonical='{canonical}', validated={validated}")
        
        return jsonify(response)
        
    except Exception as e:
        traceback.print_exc()
        return error_response(f"Internal error: {str(e)}", 500)


def clean_latex_output(latex: str) -> str:
    """
    Clean up raw OCR output which often contains garbage wrappers like
    \\begin{array}, hallucinated text, or multiple lines.
    """
    if not latex:
        return ""
        
    cleaned = latex.strip()
    
    # 1. Handle array/equation environments
    # OCR often outputs: \\begin{array}{l}...\\end{array}
    # We want to extract the inner content.
    if r'\begin{array}' in cleaned:
        # Remove wrapper
        cleaned = cleaned.replace(r'\begin{array}', '')
        # Remove argument like {l} or {c}
        if cleaned.startswith('{') and '}' in cleaned:
            end_brace = cleaned.find('}')
            cleaned = cleaned[end_brace+1:]
            
    if r'\end{array}' in cleaned:
        cleaned = cleaned.replace(r'\end{array}', '')
        
    # 2. Split by newlines (\\) and pick the best line
    # Sometimes OCR puts garbage on one line and the equation on another
    if r'\\' in cleaned:
        lines = [line.strip() for line in cleaned.split(r'\\') if line.strip()]
        if lines:
            # Heuristic: The "best" line usually has an equals sign or looks most like math
            best_line = lines[0]
            max_score = -1
            
            for line in lines:
                score = 0
                if '=' in line or r'\cong' in line:
                    score += 5
                # Penalize "text-like" lines (e.g. "Tie 10...")
                if r'\mathrm' in line and len(line) < 20: 
                     # Short \mathrm blocks are often noise like "Tie"
                    score -= 5
                
                # Penalize really short lines
                if len(line) < 3:
                    score -= 5
                    
                if score > max_score:
                    max_score = score
                    best_line = line
            cleaned = best_line

    # 3. Remove common garbage patterns
    # "Tie" often appears in hallucinations
    if r'\mathrm{Tie' in cleaned:
        cleaned = cleaned.replace(r'\mathrm{Tie', '')
        
    # Remove empty \mathrm{} blocks
    cleaned = cleaned.replace(r'{{\mathrm{}}}', '')
    cleaned = cleaned.replace(r'\mathrm{}', '')
    
    # 4. Standardize operators
    # Replace approx/cong/simeq with =
    cleaned = cleaned.replace(r'\cong', '=').replace(r'\simeq', '=').replace(r'\approx', '=').replace(r'\sim', '=')
    
    # Replace \sum with Sigma symbol to ensure parsing (SymPy struggles with unbounded \sum)
    # We use a capital Sigma variable which is calculator-safe
    # Replace \sum with Sigma symbol to ensure parsing (SymPy struggles with unbounded \sum)
    # We use a capital Sigma variable which is calculator-safe
    # cleaned = cleaned.replace(r'\sum', r'\Sigma')  <-- REMOVED: This causes "Sigma" text in Swift parser

    
    # Remove \text or \mathrm wrappers to avoid parsing issues
    # Standardize operators for SymPy
    # Standardize operators for SymPy
    # Replace congruence/approx with equals so it parses as an Equation
    for op in [r'\cong', r'\simeq', r'\approx']:
        cleaned = cleaned.replace(op, '=')
        
    # Generic Fix: Prevent variable splitting in subscripts by wrapping in \mathit
    # e.g. p_{h} -> p_{\mathit{h}}, r_{star} -> r_{\mathit{star}}
    # SymPy's parse_latex treats \mathit{text} as a single symbol/identifier,
    # preventing p_{h} -> p_h and r_{star} -> r_{s*t*a*r}
    import re
    cleaned = re.sub(r'_\{([a-zA-Z0-9]+)\}', r'_{\\mathit{\1}}', cleaned)

    # Handle special superscripts that SymPy dislikes (if any remain)
    # e.g. r^* -> r_{\mathit{star}}
    cleaned = cleaned.replace(r'^{*}', r'_{\mathit{star}}')
    cleaned = cleaned.replace(r'^*', r'_{\mathit{star}}')

    # Remove formatted wrappers like \text, \mathrm, \mathbf using regex for robustness
    # Simple string replace might miss \mathbf {x} (with space)
    # But for now, sticking to the existing pattern for safety
    for cmd in [r'\text', r'\mathrm', r'\mathbf', r'\mathit', r'\mathsf', r'\bold']:
        # We JUST added \mathit, so skipping it here!
        if cmd == r'\mathit': continue
        cleaned = cleaned.replace(cmd, '')
    
    cleaned = cleaned.replace(r'\left(', '(').replace(r'\right)', ')')
    cleaned = cleaned.replace(r'\left[', '[').replace(r'\right]', ']')
    
    # 5. Fix common spacing/brace issues
    # Remove {{...}} double braces often added by pix2tex
    if cleaned.startswith('{{') and cleaned.endswith('}}'):
         cleaned = cleaned[2:-2]
         
    return cleaned.strip()


def validate_and_canonicalize(latex_str: str) -> tuple:
    """
    Validate LaTeX through SymPy's parse_latex and produce a canonical
    calculator-compatible expression string.
    
    Returns: (canonical_expression: str, validated: bool)
    - If SymPy parses successfully: (calculator string, True)
    - If SymPy fails or unavailable: (original latex, False)
    """
    if not SYMPY_AVAILABLE:
        # Try fallback anyway if simple parsing libraries are available (unlikely if SYMPY_AVAILABLE is False but consistent)
        return fallback_validate(latex_str)
    
    try:
        # Parse LaTeX → SymPy expression
        expr = parse_latex(latex_str)
        
        # Transformation 1: Convert Equations to Expressions (lhs - rhs)
        if hasattr(expr, 'lhs') and hasattr(expr, 'rhs'):
             canonical = f"{expr.lhs} = {expr.rhs}"
        else:
             canonical = str(expr)
        
        # Validation Check
        if r'\sum' in latex_str and 'Sum' not in canonical and 'Add' not in str(type(expr)):
              if 'Sum' not in canonical and 'Expected' not in canonical: 
                   return (canonical, False)

        # Transformation 2: Sanitize
        canonical = canonical.replace('**', '^')
        import re
        canonical = re.sub(r'_\{?([a-zA-Z0-9]+)\}?', r'\1', canonical)
        
        if canonical.startswith('(') and canonical.endswith(')'):
            # (Simplified check for brevity, assuming standard output)
            pass 
        
        return (canonical, True)
        
    except Exception as e:
        print(f"parse_latex failed for '{latex_str}': {e}. Trying fallback...")
        return fallback_validate(latex_str)

def fallback_validate(expression_str: str) -> tuple:
    """
    Fallback validation using standard Python/SymPy parsing (like SympyService).
    Useful when latex_str is actually just a string representation that parse_expr can handle.
    """
    try:
        # Basic cleanup for parse_expr
        # Replace LaTeX-isms if any remain (though clean_latex_output removes most)
        clean_str = expression_str.replace('^', '**')
        # Remove \text, etc if present (should be gone)
        
        TRANSFORMATIONS = standard_transformations + (implicit_multiplication_application,)
        local_dict = {'Function': Function, 'Symbol': Symbol, 'sin': sin, 'cos': cos, 'tan': tan, 'log': log, 'ln': ln, 'sqrt': sqrt, 'exp': exp, 'pi': pi, 'E': E}
        
        # Detect undefined functions using AST
        try:
            tree = ast.parse(clean_str)
            for node in ast.walk(tree):
                if isinstance(node, ast.Call):
                    if isinstance(node.func, ast.Name):
                        func_name = node.func.id
                        if func_name not in local_dict:
                            local_dict[func_name] = Function(func_name)
        except Exception:
            pass
            
        expr = parse_expr(clean_str, local_dict=local_dict, transformations=TRANSFORMATIONS)
        
        # If we got here, it parsed!
        canonical = str(expr).replace('**', '^')
        return (canonical, True)
        
    except Exception as e:
        print(f"Fallback validation failed: {e}")
        return (expression_str, False)


def estimate_confidence(latex: str) -> float:
    """
    Estimate recognition confidence based on output characteristics.
    pix2tex doesn't provide confidence scores, so we use heuristics.
    """
    score = 0.9  # Base confidence
    
    # Penalize very short results (likely incomplete)
    if len(latex) < 2:
        score -= 0.3
    
    # Penalize very long results (likely garbage)
    if len(latex) > 200:
        score -= 0.2
    
    # Penalize if too many unknown/rare LaTeX commands
    unusual_count = sum(1 for c in latex if ord(c) > 127)
    if unusual_count > len(latex) * 0.3:
        score -= 0.2
    
    # Penalize unbalanced braces
    if latex.count('{') != latex.count('}'):
        score -= 0.3
    
    # Penalize unbalanced parens
    if latex.count('(') != latex.count(')'):
        score -= 0.2
    
    return max(0.0, min(1.0, score))


def error_response(message: str, status_code: int = 400):
    """Create standardized error response."""
    return jsonify({'error': message}), status_code


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='OCR Service')
    parser.add_argument('--port', type=int, default=3001, help='Port to run the service on')
    args = parser.parse_args()

    print(f"Starting OCR Service on port {args.port}...")
    print("Model will be loaded on first request (lazy loading)")
    app.run(host='127.0.0.1', port=args.port, debug=False)
