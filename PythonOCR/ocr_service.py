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

# Model is loaded eagerly at startup (not lazily in request handlers)
_model = None
_model_ready = False
_model_error = None

def load_model():
    """Load pix2tex LaTeX-OCR model. Called once at service startup."""
    global _model, _model_ready, _model_error
    try:
        from pix2tex.cli import LatexOCR
        print("OCR: Loading pix2tex model (this may take a moment)...")
        _model = LatexOCR()
        _model_ready = True
        print("OCR: Model loaded successfully")
    except ImportError:
        _model_error = "pix2tex not installed. Run: pip install pix2tex"
        print(f"ERROR: {_model_error}")
    except Exception as e:
        _model_error = str(e)
        print(f"ERROR loading OCR model: {e}")

def get_model():
    """Return the pre-loaded model instance."""
    if not _model_ready:
        raise RuntimeError(_model_error or "OCR model not loaded")
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
    """Health check endpoint reflecting model readiness."""
    return jsonify({
        'status': 'ok' if _model_ready else 'loading',
        'service': 'ocr',
        'model_loaded': _model_ready,
        'model_error': _model_error
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
        
        # Run OCR with timeout protection
        try:
            model = get_model()
            import signal
            
            def _timeout_handler(signum, frame):
                raise TimeoutError("OCR recognition timed out (>30s)")
            
            old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
            signal.alarm(30)  # 30 second timeout
            try:
                latex_result = model(image)
            finally:
                signal.alarm(0)  # Cancel timeout
                signal.signal(signal.SIGALRM, old_handler)
        except TimeoutError as e:
            return error_response(str(e), 504)
        except RuntimeError as e:
            return error_response(f"OCR model not ready: {str(e)}", 503)
        except Exception as e:
            err_str = str(e)
            if 'cvtColor' in err_str or 'cv2' in err_str.lower() or '_src.empty()' in err_str:
                return error_response(
                    f"OCR image processing error — the image may be corrupted or unsupported. Details: {err_str}", 500
                )
            return error_response(f"OCR recognition failed: {err_str}", 500)
        
        processing_time = (time.time() - start_time) * 1000
        
        if not latex_result or len(latex_result.strip()) == 0:
            return error_response("No equation detected in image")
        
        # Clean up the result
        latex_clean = clean_latex_output(latex_result)
        
        # 1. LLM Standardization (New Step)
        # Try to standardize using LLM if available
        llm_standardized = standardize_with_llm(latex_clean)
        
        # If LLM returned a result, use it as the primary candidate
        if llm_standardized:
            print(f"LLM Standardized: {latex_clean} -> {llm_standardized}")
            latex_clean = llm_standardized
            # Recalculate confidence for the new string
            confidence = 0.95 # Trust the LLM
        else:
            # Fallback to heuristic
            confidence = estimate_confidence(latex_clean)

        # 2. Refined Pass (Aggressive heuristics + SymPy)
        refined_canonical, validated = validate_and_canonicalize(latex_clean)
        
        # 3. Raw Pass (Basic cleanup only, no semantic heuristics)
        # We skip heuristic_semantic_correction() but still balance parentheses
        raw_working = balance_parentheses(latex_clean)
        raw_canonical, _ = fallback_validate(raw_working)
        
        # Boost confidence if validated, penalize if not
        if validated:
            confidence = min(1.0, confidence + 0.1)
        elif SYMPY_AVAILABLE:
            confidence = max(0.0, confidence - 0.15)
        
        response = {
            'expression': refined_canonical if validated else raw_canonical,
            'latex': latex_clean,
            'refined_expression': refined_canonical,
            'raw_expression': raw_canonical,
            'validated': validated,
            'confidence': round(confidence, 3),
            'processing_time_ms': round(processing_time, 3),
            'llm_used': llm_standardized is not None
        }
        
        # DEBUG
        print(f"OCR result: raw='{raw_canonical}', refined='{refined_canonical}', validated={validated}")
        
        return jsonify(response)
        
    except Exception as e:
        traceback.print_exc()
        return error_response(f"Internal error: {str(e)}", 500)


def standardize_with_llm(text: str) -> str:
    """
    Use local Ollama instance to standardize messy OCR output into valid SymPy code.
    Input: "S x^2 dx"
    Output: "integrate(x**2, x)"
    """
    import urllib.request
    import json
    
    # Try connecting to Ollama default port
    OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
    # Fallback models in order of preference
    MODELS = ["llama3", "phi3", "mistral", "gemma:2b"]
    
    prompt = f"""You are a mathematical syntax standardizer. 
Convert the following raw OCR text into valid SymPy Python code.
Rules:
1. Output ONLY the code. No markdown, no explanations.
2. Convert integrals 'S' or 'int' to `integrate(expression, variable)`.
3. Convert derivatives 'd/dx' to `diff(expression, variable)`.
4. Use `**` for exponents.
5. Fix common OCR errors (e.g. 'O' -> '0', 'l' -> '1').

Raw Text: "{text}"
SymPy Code:"""

    try:
        import urllib.request
        
        # Simple health check / model check could go here, but let's just try the request
        # We need to find which model is installed. 
        # For now, we'll try the first one and if it fails (404 model not found), we could try others.
        # To keep it simple, let's assume 'llama3' or allow env var override.
        import os
        model = os.environ.get("OLLAMA_MODEL", "llama3")
        
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.0
            }
        }
        
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(OLLAMA_URL, data=data, headers={'Content-Type': 'application/json'})
        
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                result = json.loads(response.read().decode('utf-8'))
                final_text = result.get('response', '').strip()
                # Remove markdown code blocks if present
                final_text = final_text.replace('```python', '').replace('```', '').strip()
                return final_text
                
    except Exception as e:
        print(f"Ollama Standardization Failed: {e}")
        return None


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
         
    # 6. Semantic Post-Processing (Heuristics for common OCR errors)
    cleaned = heuristic_semantic_correction(cleaned)
    
    # 7. Bracket Balancing
    cleaned = balance_parentheses(cleaned)
         
    return cleaned.strip()


def balance_parentheses(text: str) -> str:
    """
    Ensure parentheses and brackets are balanced.
    Fixes 'Unmatched parenthesis' errors by adding missing ones or 
    removing stray ones.
    """
    if not text:
        return text
        
    stack = []
    # Map of closing to opening for easier lookup
    pairs = {')': '(', ']': '[', '}': '{'}
    result = list(text)
    to_remove = []
    
    # Pass 1: Find unmatched closing brackets
    for i, char in enumerate(result):
        if char in pairs.values():
            stack.append((char, i))
        elif char in pairs.keys():
            if stack and stack[-1][0] == pairs[char]:
                stack.pop()
            else:
                to_remove.append(i)
                
    # Remove unmatched closing brackets (especially at the start)
    for i in reversed(to_remove):
        result.pop(i)
        
    # Pass 2: Re-evaluate stack for unmatched opening brackets
    # If they are at the end, just close them. 
    # If they are complex, we might want to remove them, but for math, closing is usually safer.
    # Recalculate stack after removals
    stack = []
    final_result = "".join(result)
    for i, char in enumerate(final_result):
        if char in pairs.values():
            stack.append((char, i))
        elif char in pairs.keys():
            if stack and stack[-1][0] == pairs[char]:
                stack.pop()
                
    # Add missing closing brackets in reverse order of opening
    rev_pairs = {'(': ')', '[': ']', '{': '}'}
    for char, i in reversed(stack):
        final_result += rev_pairs[char]
        
    return final_result


def heuristic_semantic_correction(latex_str: str) -> str:
    """
    Apply semantic heuristics to fix common LaTeX-OCR misidentifications.
    Addresses: x vs chi, missing/fragmented function backslashes, etc.
    """
    import re
    result = latex_str
    
    # 0. Pre-cleaning (Generic noise)
    # Remove \quad, \qquad, \, etc that are noise early
    for space in [r'\quad', r'\qquad', r'\;', r'\!', r'\:', r'\,', r'~']:
        result = result.replace(space, ' ')

    # 1. Visual Wrapper Removal (Aggressive + Nested Support)
    # Commands where we want to keep the inner content
    keep_inner = [r'\underline', r'\overline', r'\dot', r'\hat', r'\tilde', r'\vec', r'\bold', r'\mathbf', r'\mathit', r'\mathrm', r'\textmd', r'\textrm']
    # Commands where we want to strip the entire thing including contents (usually purely metadata or text noise)
    strip_all = [r'\text', r'\textsf', r'\texttt', r'\textsl', r'\textsc']
    
    for wrap in (keep_inner + strip_all):
        pattern_braced = wrap.replace('\\', '\\\\') + r'\s*\{'
        while True:
            match = re.search(pattern_braced, result)
            if not match: break
            start_idx = match.start()
            brace_count = 0
            found = False
            for i in range(match.end() - 1, len(result)):
                if result[i] == '{': brace_count += 1
                elif result[i] == '}': 
                    brace_count -= 1
                    if brace_count == 0:
                        if wrap in keep_inner:
                            inner = result[match.end():i]
                            result = result[:start_idx] + inner + result[i+1:]
                        else:
                            # Strip entirely if it's metadata/text
                            result = result[:start_idx] + result[i+1:]
                        found = True
                        break
            if not found: break
            
        # Non-braced versions
        result = re.sub(wrap.replace('\\', '\\\\') + r'\s+([a-zA-Z0-9])', r'\1' if wrap in keep_inner else '', result)
        result = re.sub(wrap.replace('\\', '\\\\') + r'([a-zA-Z0-9])', r'\1' if wrap in keep_inner else '', result)

    # 1.1 Redundant Brace Stripping (Careful)
    # We want to strip {{3}} -> 3, but maybe keep content of exponents if needed.
    # Actually, for SymPy, we replace { } with ( ) at the end anyway, or it handles it.
    # Let's just strip double braces specifically.
    result = re.sub(r'\{\{([^{}]+)\}\}', r'{\1}', result)
    # And then single braces that aren't preceded by ^ or _ or function
    result = re.sub(r'(?<![\^_])\{([a-zA-Z0-9\+\-\*\/]+)\}', r'(\1)', result)

    # 2. Character Confusions & Hallucinations
    # hteta/htete/htet -> \theta
    result = re.sub(r'\bh\s*t\s*e\s*t\s*a\b', r'\\theta', result, flags=re.IGNORECASE)
    result = re.sub(r'hteta', r'\\theta', result, flags=re.IGNORECASE)
    result = re.sub(r'htet', r'\\theta', result, flags=re.IGNORECASE)
    
    # S L I / S L N / S I N (hallucinated Sin)
    result = re.sub(r'S\s*L\s*[IN]\b', r'\\sin', result, flags=re.IGNORECASE)
    # C O S
    result = re.sub(r'C\s*O\s*S\b', r'\\cos', result, flags=re.IGNORECASE)
    # T A N
    result = re.sub(r'T\s*A\s*N\b', r'\\tan', result, flags=re.IGNORECASE)
    # L N / L I M / S Q R T / E X P
    result = re.sub(r'L\s*N\b', r'\\ln', result, flags=re.IGNORECASE)
    result = re.sub(r'L\s*I\s*M\b', r'\\lim', result, flags=re.IGNORECASE)
    result = re.sub(r'S\s*Q\s*R\s*T\b', r'\\sqrt', result, flags=re.IGNORECASE)
    result = re.sub(r'E\s*X\s*P\b', r'\\exp', result, flags=re.IGNORECASE)
    
    # 2. Greek Letter Prefixing (Missing backslashes)
    greek_letters = [
        'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta', 
        'iota', 'kappa', 'lambda', 'mu', 'nu', 'xi', 'omicron', 'pi', 'rho', 
        'sigma', 'tau', 'upsilon', 'phi', 'chi', 'psi', 'omega'
    ]
    for greek in greek_letters:
        # Case insensitive prefixing (e.g., "Theta" -> "\theta")
        pattern = r'(?<!\\)\b' + greek + r'\b'
        result = re.sub(pattern, r'\\' + greek.lower(), result, flags=re.IGNORECASE)

    # \chi is almost always intended to be 'x'
    result = result.replace(r'\chi', 'x')
    
    # Fix (*) or ( X ) or ( * ) as function arguments
    result = re.sub(r'\(\s*[\*X]\s*\)', r'(x)', result)
    # Fix (\ X) or ( \ *) noise
    result = re.sub(r'\(\s*\\\s*[xX\*]\s*\)', r'(x)', result)

    # O vs 0 (Digit confusion) - Use lookbehind to avoid corrupting LaTeX commands
    # If O is at the start of a word followed by a digit, OR at the end of a word preceded by a digit
    result = re.sub(r'(\d)\s*[oO]\b', r'\1 0', result)
    result = re.sub(r'\b[oO]\s*(\d)', r'0 \1', result)
    # Surroundings with digits
    result = re.sub(r'(\d)\s*[oO]\s*(\d)', r'\1 0 \2', result)

    # 3. Symbol Normalization (Operators)
    result = result.replace(r'\times', '*').replace(r'\cdot', '*').replace(r'\star', '*')
    
    # Heuristic: digit + 'x' + digit -> digit * digit
    result = re.sub(r'(\d)\s*[xX]\s*(\d)', r'\1 * \2', result)
    # Heuristic: a x b where a, b are variables (like simple linear equations)
    result = re.sub(r'([a-zA-Z])\s+[xX]\s+([a-zA-Z])', r'\1 * \2', result)

    # 4. Decimal & Digit Joining
    for _ in range(3): 
        result = re.sub(r'(\d)\s+(\d)', r'\1\2', result)
    
    result = re.sub(r'(\d)\s*[:,\.]\s*(\d)', r'\1.\2', result)

    # 5. Function Normalization (Case-Insensitive)
    functions = ['cos', 'sin', 'tan', 'log', 'ln', 'lim', 'sqrt', 'exp', 'det', 'min', 'max']
    for func in functions:
        # Regex for missing backslash (case-insensitive)
        pattern = r'(?<!\\)\b' + func + r'\b'
        result = re.sub(pattern, r'\\' + func, result, flags=re.IGNORECASE)
        
        # Fragmented detection: e.g., "c o s" -> "\cos"
        if len(func) > 1:
            fragmented = "\\s+".join(list(func))
            result = re.sub(fragmented, r'\\' + func, result, flags=re.IGNORECASE)
            # Clean up potential double backslashes
            result = result.replace(r'\\' + r'\\' + func, r'\\' + func)

    # 6. Logarithmic Specifics
    result = re.sub(r'\bIn\b', r'\\ln', result, flags=re.IGNORECASE)
    result = re.sub(r'(?<!\\)\bln\b', r'\\ln', result, flags=re.IGNORECASE)
    
    # 7. Differentials
    for var in ['x', 'y', 'z', 't', 'u', 'v']:
        result = re.sub(r'\bd' + var + r'\b', r'\\' + ',d' + var, result)

    # 8. Limit Cleanup
    if r'lim' in result:
        result = re.sub(r'(?<!\\)\blim\b', r'\\lim', result)
        result = re.sub(r'\\lim\s*_\s*\{', r'\\lim_{', result)

    # 9. Parenthesis Cleanup (Redundancy)
    # Remove nested redundant parens: ((x)) -> (x)
    for _ in range(3):
        result = re.sub(r'\(\s*\(([^\(\)]+)\)\s*\)', r'(\1)', result)
    
    # 10. Final Cleanup
    # Remove raw braces if they accompany standard functions (SymPy likes \cos(x) not \cos{x})
    for func in functions:
        result = re.sub(r'\\' + func + r'\s*\{([^{}]+)\}', r'\\' + func + r'(\1)', result)

    # Remove braces around single commands: {\cos} -> \cos
    result = re.sub(r'\{(\\[a-zA-Z]+)\}', r'\1', result)

    result = re.sub(r'\{\s+', '{', result)
    result = re.sub(r'\s+\}', '}', result)
    
    # 11. Final Spacing pass
    # Remove \quad, \qquad, \, etc and now also literal '\ '
    for space in [r'\quad', r'\qquad', r'\;', r'\!', r'\:', r'\,', r'~', r'\ ']:
        result = result.replace(space, ' ')
    
    # Standardize multiple spaces to single space
    result = re.sub(r'\s+', ' ', result)
    
    # Remove space after backslashed commands if followed by paren/brace
    result = re.sub(r'(\\[a-zA-Z]+)\s+([\(\{\[])', r'\1\2', result)
    
    return result.strip()


def validate_and_canonicalize(latex_str: str) -> tuple:
    """
    Validate LaTeX through SymPy's parse_latex and produce a canonical
    calculator-compatible expression string.
    """
    if not SYMPY_AVAILABLE:
        return fallback_validate(latex_str)
    
    # CRITICAL: Apply heuristics BEFORE first parse attempt
    # This prevents parse_latex from incorrectly succeeding with split variables
    working_latex = heuristic_semantic_correction(latex_str)
    working_latex = balance_parentheses(working_latex)
    
    try:
        expr = parse_latex(working_latex)
        return (format_sympy_result(expr), True)
    except Exception as e:
        print(f"parse_latex failed for '{working_latex}': {e}. Trying Deep Clean...")
        
    # 2nd Pass: Deep Clean (Last resort)
    deep_latex = deep_clean_math(latex_str)
    try:
        # Deep clean might result in a string that we should try with fallback_validate instead
        canonical, ok = fallback_validate(deep_latex)
        if ok: return (canonical, True)
    except Exception:
        pass
        
    return fallback_validate(latex_str)


def format_sympy_result(expr) -> str:
    """Helper to convert SymPy expression to calculator-safe string."""
    if hasattr(expr, 'lhs') and hasattr(expr, 'rhs'):
         canonical = f"{expr.lhs} = {expr.rhs}"
    else:
         canonical = str(expr)
    
    canonical = canonical.replace('**', '^')
    import re
    # Remove _ subscript artifacts
    canonical = re.sub(r'_\{?([a-zA-Z0-9]+)\}?', r'\1', canonical)
    return canonical


def deep_clean_math(text: str) -> str:
    """
    Aggressively strip everything except mathematical characters.
    Good for extreme OCR failures where formatting dominates content.
    """
    import re
    result = text
    
    # 1. Strip common text blocks that shouldn't be in math at all
    # e.g. \text{Total: }, \mathrm{id}, etc.
    for cmd in [r'\text', r'\mathrm', r'\mathbf', r'\mathit']:
        # Strip the command AND its braced contents
        result = re.sub(cmd.replace('\\', '\\\\') + r'\{[^{}]*\}', ' ', result)
        # Strip command itself
        result = result.replace(cmd, ' ')

    # 2. Remove all remaining LaTeX commands: \command
    result = re.sub(r'\\[a-zA-Z]+', ' ', result)
    
    # 3. Replace { } [ ] with ( ) for SymPy compatibility
    result = result.replace('{', '(').replace('}', ')').replace('[', '(').replace(']', ')')
    
    # 4. Filter: Keep only digits, letters, . , + - * / ^ ( ) =
    result = re.sub(r'[^0-9a-zA-Z\.\+\-\*\/\^\(\)\= ]', '', result)
    
    # 5. Join digits separated by spaces: "1 0 0" -> "100"
    # Only if they are purely digits
    for _ in range(3):
        result = re.sub(r'(\d)\s+(\d)', r'\1\2', result)
        
    # 6. Final balance
    return balance_parentheses(result.strip())

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
    
    # Load model at startup — NOT lazily in request handlers
    load_model()
    
    print(f"Model ready: {_model_ready}")
    # Set threaded=False because signal.alarm only works in the main thread
    app.run(host='127.0.0.1', port=args.port, debug=False, threaded=False)
