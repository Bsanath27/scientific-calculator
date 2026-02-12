# Phase 2 Testing & Debugging Guide

## **Copy-Paste Ready Expressions**

Use these exact strings in the calculator (⌘C / ⌘V):

### **Arithmetic**
`1/2 + 1/3`
`1/10 + 2/10`
`5!`
`2^10`
`2^50`

### **Algebra & Simplification**
`sqrt(8)`
`sqrt(12)`
`sqrt(2) * sqrt(2)`
`(1+sqrt(5))/2`

### **Trigonometry (Exact)**
`sin(pi)`
`cos(pi)`
`tan(pi/4)`
`sin(pi/2)`
`cos(pi/3)`
`sin(pi/6)`

### **Identities**
`sin(pi/2)^2 + cos(pi/2)^2`
`sin(pi/4)^2 + cos(pi/4)^2`

### **Logarithms**
`ln(e)`
`ln(e^2)`
`log(100)`
`log(1000)`

---

## **Expected Results**

| Expression | Numeric Result | Symbolic Result |
| :--- | :--- | :--- |
| `1/2 + 1/3` | `0.833333...` | `5/6` |
| `sqrt(8)` | `2.8284...` | `2\sqrt{2}` |
| `sin(pi)` | `1.22e-16` | `0` |
| `ln(e^2)` | `2.0` | `2` |
| `2^50` | `1.1259e15` | `1125899906842624` |
| `sin(pi/2)^2 + cos(pi/2)^2` | `1.0` | `1` |

---

## **Debugging Checklist**

If results are wrong or `.notImplemented`, check:

1.  **Is Python Service Running?**
    *   Command: `curl http://127.0.0.1:5001/health`
    *   Expected: `{"status": "online", "service": "sympy"}`

2.  **Is Expression Valid?**
    *   Example: `ln(e)` (valid) vs `log10(100)` (invalid function name, use `log`)
    *   Check `Parser/Token.swift` for supported function names.

3.  **Check Xcode Console Logs:**
    *   Verify `Dispatcher` routes to `SymbolicEngine`.
    *   Check `EvaluationResult.symbolic` payload.

4.  **Verify Metrics:**
    *   Does `pythonCallTimeMs` show a value? (Means network call succeeded)
    *   Does `conversionTimeMs` show a value? (Means AST -> conversion succeeded)

---

## **Known Limitations (Phase 2)**

*   **No Variables:** `x`, `y`, `z` will cause a `ParserError` ("Unexpected token").
*   **Default Operation:** Currently only calls `/simplify`.
*   **UI:** LaTeX rendering is raw string output (`\sqrt{2}`), not formatted math view (yet).
