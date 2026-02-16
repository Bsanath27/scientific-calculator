#!/usr/bin/env python3
"""
SymPy Service - Flask HTTP server for symbolic math operations
Exposes SymPy functionality via REST API for Swift calculator
"""

from flask import Flask, request, jsonify
from sympy import (
    sympify, simplify, solve, diff, integrate, sqrt, 
    sin, cos, tan, log, ln, exp, pi, E, Symbol, latex, Function
)
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
import time
import traceback
import ast

app = Flask(__name__)

# Configure parsing transformations
TRANSFORMATIONS = standard_transformations + (implicit_multiplication_application,)

def safe_sympify(expression_str):
    """Safely parse expression string to SymPy object"""
    try:
        # Convert ^ to ** for exponentiation
        expression_str = expression_str.replace('^', '**')
        local_dict = {'Function': Function, 'Symbol': Symbol, 'sin': sin, 'cos': cos, 'tan': tan, 'log': log, 'ln': ln, 'sqrt': sqrt, 'exp': exp, 'pi': pi, 'E': E}
        
        # Detect undefined functions using AST to prevent them being parsed as Symbols * Tuple
        try:
            tree = ast.parse(expression_str)
            for node in ast.walk(tree):
                if isinstance(node, ast.Call):
                    if isinstance(node.func, ast.Name):
                        func_name = node.func.id
                        if func_name not in local_dict:
                            local_dict[func_name] = Function(func_name)
        except Exception:
            pass
            
        return parse_expr(expression_str, local_dict=local_dict, transformations=TRANSFORMATIONS)
    except Exception as e:
        raise ValueError(f"Invalid expression: {str(e)}")

def create_response(result_expr, start_time):
    """Create standardized JSON response"""
    execution_time = (time.time() - start_time) * 1000  # Convert to ms
    
    return jsonify({
        'result': str(result_expr),
        'latex': latex(result_expr),
        'execution_time_ms': round(execution_time, 3)
    })

def error_response(message, status_code=400):
    """Create error response"""
    return jsonify({'error': message}), status_code

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'online', 'service': 'sympy'})

@app.route('/simplify', methods=['POST'])
def simplify_endpoint():
    """Simplify algebraic expressions"""
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        expr = safe_sympify(data['expression'])
        result = simplify(expr)
        
        return create_response(result, start_time)
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Simplify error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

@app.route('/solve', methods=['POST'])
def solve_endpoint():
    """Solve equations"""
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        expr = safe_sympify(data['expression'])
        variable = data.get('variable', 'x')
        
        # Create symbol for the variable
        var_symbol = Symbol(variable)
        solutions = solve(expr, var_symbol)
        
        return create_response(solutions, start_time)
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Solve error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

@app.route('/differentiate', methods=['POST'])
def differentiate_endpoint():
    """Compute derivatives"""
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        expr = safe_sympify(data['expression'])
        variable = data.get('variable', 'x')
        
        # Create symbol for the variable
        var_symbol = Symbol(variable)
        result = diff(expr, var_symbol)
        
        return create_response(result, start_time)
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Differentiate error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

@app.route('/integrate', methods=['POST'])
def integrate_endpoint():
    """Compute integrals"""
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        expr = safe_sympify(data['expression'])
        variable = data.get('variable', 'x')
        
        # Create symbol for the variable
        var_symbol = Symbol(variable)
        result = integrate(expr, var_symbol)
        
        return create_response(result, start_time)
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Integrate error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

@app.route('/evaluate', methods=['POST'])
def evaluate_endpoint():
    """Evaluate symbolic expressions (simplify by default)"""
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        expr = safe_sympify(data['expression'])
        result = simplify(expr)
        
        return create_response(result, start_time)
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Evaluate error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

@app.route('/verify', methods=['POST'])
def verify_endpoint():
    """
    Verify if a mathematical identity holds (simplify to zero).
    Expects an expression that represents (LHS - RHS).
    If the result is 0, the identity is verified.
    """
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'expression' not in data:
            return error_response('Missing expression field')
        
        # Parse expression
        expr = safe_sympify(data['expression'])
        
        # Simplify
        result = simplify(expr)
        
        # Check if zero
        # strict=True helps with some edge cases, but default is usually fine
        is_verified = result == 0
        
        execution_time = (time.time() - start_time) * 1000
        
        return jsonify({
            'verified': is_verified,
            'result': str(result),
            'latex': latex(result),
            'execution_time_ms': round(execution_time, 3)
        })
    
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        app.logger.error(f"Verify error: {traceback.format_exc()}")
        return error_response(f"Internal error: {str(e)}", 500)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='SymPy Service')
    parser.add_argument('--port', type=int, default=8001, help='Port to run the service on')
    args = parser.parse_args()

    print("=" * 50)
    print(f"SymPy Service Starting on port {args.port}")
    print("=" * 50)
    print("Endpoints:")
    print("  GET  /health")
    print("  POST /simplify")
    print("  POST /solve")
    print("  POST /differentiate")
    print("  POST /integrate")
    print("  POST /evaluate")
    print("  POST /verify")
    print("=" * 50)
    
    app.run(host='127.0.0.1', port=args.port, debug=False)
