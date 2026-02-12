#!/usr/bin/env python3
"""
Test script for SymPy Service
Tests all endpoints with sample expressions
"""

import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_endpoint(name, endpoint, data):
    """Test a single endpoint"""
    print(f"\n{'='*50}")
    print(f"Testing: {name}")
    print(f"{'='*50}")
    print(f"Request: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(f"{BASE_URL}{endpoint}", json=data, timeout=5)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("SymPy Service Test Suite")
    print("Make sure the service is running on port 5000")
    
    # Test health
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=2)
        print(f"\n✓ Health check: {response.json()}")
    except:
        print("\n✗ Service not running!")
        return
    
    results = []
    
    # Test simplify
    results.append(test_endpoint(
        "Simplify - Trig Identity",
        "/simplify",
        {"expression": "sin(x)**2 + cos(x)**2"}
    ))
    
    # Test solve
    results.append(test_endpoint(
        "Solve - Quadratic",
        "/solve",
        {"expression": "x**2 - 4", "variable": "x"}
    ))
    
    # Test differentiate
    results.append(test_endpoint(
        "Differentiate - Polynomial",
        "/differentiate",
        {"expression": "x**2", "variable": "x"}
    ))
    
    # Test integrate
    results.append(test_endpoint(
        "Integrate - Linear",
        "/integrate",
        {"expression": "2*x", "variable": "x"}
    ))
    
    # Test evaluate
    results.append(test_endpoint(
        "Evaluate - Expression",
        "/evaluate",
        {"expression": "sqrt(16) + pi"}
    ))
    
    print(f"\n{'='*50}")
    print(f"Results: {sum(results)}/{len(results)} passed")
    print(f"{'='*50}")

if __name__ == "__main__":
    main()
