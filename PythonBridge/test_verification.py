
import requests
import json

URL = "http://127.0.0.1:5001/verify"

tests = [
    {
        "name": "Trig Identity (sin^2 + cos^2 - 1 = 0)",
        "expression": "sin(x)**2 + cos(x)**2 - 1",
        "expected": True
    },
    {
        "name": "Algebraic Identity (x + x - 2x = 0)",
        "expression": "x + x - 2*x",
        "expected": True
    },
    {
        "name": "False Identity (x + y)",
        "expression": "x + y",
        "expected": False
    },
    {
        "name": "Complex Identity ((x+1)^2 - (x^2 + 2x + 1))",
        "expression": "(x+1)**2 - (x**2 + 2*x + 1)",
        "expected": True
    }
]

print(f"Testing Verify Endpoint at {URL}...\n")

for test in tests:
    try:
        payload = {"expression": test["expression"]}
        response = requests.post(URL, json=payload, timeout=2)
        
        if response.status_code == 200:
            result = response.json()
            verified = result.get("verified")
            print(f"[{'PASS' if verified == test['expected'] else 'FAIL'}] {test['name']}")
            print(f"   Expr: {test['expression']}")
            print(f"   Result: {result.get('result')}")
            print(f"   Verified: {verified}")
        else:
            print(f"[ERROR] {test['name']} - HTTP {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"[EXCEPTION] {test['name']}: {e}")
    
    print("-" * 30)
