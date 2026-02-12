# verify_ocr_fix.py
import sys
import os

# Add local directory to path to import ocr_service
sys.path.append(os.getcwd())

from PythonOCR.ocr_service import validate_and_canonicalize, clean_latex_output

# The problematic LaTeX
latex_str_raw = r"\chi(p_{h}(r)-0,0)\cong\frac{27}{128}(r-r^{*})^{-2}"
print(f"Input Raw: {latex_str_raw}")

# Run cleanup first (this is what the service does)
latex_clean = clean_latex_output(latex_str_raw)
print(f"Cleaned: {latex_clean}")

canonical, valid = validate_and_canonicalize(latex_clean)
print(f"Canonical: {canonical}")
print(f"Valid: {valid}")

# Check if the critical term is preserved
if "27/128" in canonical and "star" in canonical:
    print("SUCCESS: Term preserved and standardized.")
else:
    print("FAILURE: Term truncated or not standardized.")
