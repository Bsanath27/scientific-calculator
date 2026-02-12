#!/usr/bin/env python3
"""
Generate test equation images for OCR testing.
Renders LaTeX equations to PNG using matplotlib.

Usage: python3 generate_test_images.py
Output: test_images/ directory with numbered equation PNGs + ground truth
"""

import os
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'test_images')

# Test equations: (filename, LaTeX for rendering, expected calculator expression)
EQUATIONS = [
    ("01_addition",         r"$\frac{1}{2} + \frac{3}{4}$",         "1/2 + 3/4"),
    ("02_sqrt",             r"$\sqrt{16}$",                          "sqrt(16)"),
    ("03_power",            r"$2^{10}$",                             "2^10"),
    ("04_pythagorean",      r"$3^{2} + 4^{2}$",                     "3^2 + 4^2"),
    ("05_multiplication",   r"$3 \times 4 + 5$",                     "3*4 + 5"),
    ("06_fraction",         r"$\frac{22}{7}$",                       "22/7"),
    ("07_trig",             r"$\sin\left(\frac{\pi}{2}\right)$",     "sin(pi/2)"),
    ("08_polynomial",       r"$x^{2} + 2x + 1$",                    "x^2 + 2*x + 1"),
    ("09_quadratic",        r"$x = \frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}$",
                                                                      "(-b + sqrt(b^2 - 4*a*c))/(2*a)"),
    ("10_euler",            r"$e^{i\pi} + 1$",                       "exp(i*pi) + 1"),
]


def render_equation(latex_str: str, output_path: str, dpi: int = 150):
    """Render a LaTeX equation string to a PNG image."""
    fig, ax = plt.subplots(figsize=(6, 1.5))
    ax.set_axis_off()
    
    # Render the equation centered on a white background
    ax.text(
        0.5, 0.5, latex_str,
        fontsize=28,
        ha='center', va='center',
        transform=ax.transAxes,
        color='black'
    )
    
    fig.patch.set_facecolor('white')
    fig.savefig(output_path, dpi=dpi, bbox_inches='tight',
                facecolor='white', edgecolor='none', pad_inches=0.3)
    plt.close(fig)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Generate each equation image + ground truth file
    for filename, latex_str, expected_expr in EQUATIONS:
        img_path = os.path.join(OUTPUT_DIR, f"{filename}.png")
        txt_path = os.path.join(OUTPUT_DIR, f"{filename}.txt")
        
        render_equation(latex_str, img_path)
        
        # Write ground truth
        with open(txt_path, 'w') as f:
            f.write(f"latex: {latex_str}\n")
            f.write(f"expected: {expected_expr}\n")
        
        print(f"  Generated: {filename}.png")
    
    # Write index file
    index_path = os.path.join(OUTPUT_DIR, "README.md")
    with open(index_path, 'w') as f:
        f.write("# OCR Test Images\n\n")
        f.write("Generated test equations for OCR pipeline testing.\n\n")
        f.write("| # | File | LaTeX | Expected Expression |\n")
        f.write("|---|------|-------|---------------------|\n")
        for filename, latex_str, expected_expr in EQUATIONS:
            clean_latex = latex_str.replace('$', '').replace('|', '\\|')
            f.write(f"| {filename[:2]} | {filename}.png | `{clean_latex}` | `{expected_expr}` |\n")
    
    print(f"\nGenerated {len(EQUATIONS)} test images in {OUTPUT_DIR}/")
    print(f"Ground truth files (.txt) alongside each image.")


if __name__ == '__main__':
    main()
