# reproduce_ocr_issue_2.py
from sympy.parsing.latex import parse_latex
from sympy import pprint

# Problematic LaTeX from screenshot
latex_str_raw = r"\chi(p_{h}(r)-0,0)\cong\frac{27}{128}(r-r^{*})^{-2}"

# Proposed Fixes:
# 1. Replace \cong with =
# 2. Replace ^{...} with _{star} if it contains *
# Note: r"^{*}" matches exactly "^{*}" in the string
latex_str = latex_str_raw.replace(r"\cong", "=").replace(r"^{*}", "_{star}")

print(f"Input LaTeX (Raw): {latex_str_raw}")
print(f"Input LaTeX (Fixed): {latex_str}")

try:
    expr = parse_latex(latex_str)
    print(f"Parsed Expression Type: {type(expr)}")
    print(f"Parsed Expression: {expr}")
    # Check if LHS matches
    if hasattr(expr, 'lhs') and hasattr(expr, 'rhs'):
        print(f"LHS: {expr.lhs}")
        print(f"RHS: {expr.rhs}")
        # Try converting back to string
        print(f"str(expr): {str(expr)}")
    else:
        print("Not an equation?")
except Exception as e:
    print(f"Parsing Failed: {e}")
