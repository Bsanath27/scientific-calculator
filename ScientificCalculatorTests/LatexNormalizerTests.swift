// ScientificCalculatorTests/LatexNormalizerTests.swift
// Scientific Calculator - Phase 4: LaTeX Normalizer Unit Tests

import XCTest
@testable import ScientificCalculator

final class LatexNormalizerTests: XCTestCase {
    
    // MARK: - Display Wrappers
    
    func testRemoveDollarSigns() {
        XCTAssertEqual(LatexNormalizer.normalize("$x + 1$"), "x + 1")
    }
    
    func testRemoveDoubleDollarSigns() {
        XCTAssertEqual(LatexNormalizer.normalize("$$x^2$$"), "x^2")
    }
    
    func testRemoveDisplaystyle() {
        XCTAssertEqual(LatexNormalizer.normalize("\\displaystyle x"), "x")
    }
    
    // MARK: - Fractions
    
    func testSimpleFraction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\frac{a}{b}"), "(a)/(b)")
    }
    
    func testNumericFraction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\frac{1}{2}"), "(1)/(2)")
    }
    
    func testNestedFraction() {
        let result = LatexNormalizer.normalize("\\frac{\\frac{1}{2}}{3}")
        XCTAssertEqual(result, "((1)/(2))/(3)")
    }
    
    func testFractionWithExpression() {
        XCTAssertEqual(LatexNormalizer.normalize("\\frac{x+1}{x-1}"), "(x+1)/(x-1)")
    }
    
    // MARK: - Square Root
    
    func testSimpleSqrt() {
        XCTAssertEqual(LatexNormalizer.normalize("\\sqrt{x}"), "sqrt(x)")
    }
    
    func testSqrtWithNumber() {
        XCTAssertEqual(LatexNormalizer.normalize("\\sqrt{16}"), "sqrt(16)")
    }
    
    func testNthRoot() {
        let result = LatexNormalizer.normalize("\\sqrt[3]{8}")
        XCTAssertEqual(result, "(8)^(1/(3))")
    }
    
    // MARK: - Operators
    
    func testCdot() {
        XCTAssertEqual(LatexNormalizer.normalize("a \\cdot b"), "a * b")
    }
    
    func testTimes() {
        XCTAssertEqual(LatexNormalizer.normalize("3 \\times 4"), "3 * 4")
    }
    
    func testDiv() {
        XCTAssertEqual(LatexNormalizer.normalize("10 \\div 2"), "10 / 2")
    }
    
    func testLeftRightParens() {
        XCTAssertEqual(LatexNormalizer.normalize("\\left(x+1\\right)"), "(x+1)")
    }
    
    // MARK: - Functions
    
    func testSinFunction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\sin(x)"), "sin(x)")
    }
    
    func testCosFunction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\cos(x)"), "cos(x)")
    }
    
    func testLogFunction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\log(10)"), "log(10)")
    }
    
    func testLnFunction() {
        XCTAssertEqual(LatexNormalizer.normalize("\\ln(e)"), "ln(e)")
    }
    
    // MARK: - Constants
    
    func testPi() {
        XCTAssertEqual(LatexNormalizer.normalize("\\pi"), "pi")
    }
    
    // MARK: - Complex Expressions
    
    func testQuadraticFormula() {
        let latex = "\\frac{-b + \\sqrt{b^2 - 4 \\cdot a \\cdot c}}{2 \\cdot a}"
        let result = LatexNormalizer.normalize(latex)
        XCTAssertTrue(result.contains("sqrt("), "Should contain sqrt")
        XCTAssertTrue(result.contains("/"), "Should contain division")
        XCTAssertFalse(result.contains("\\"), "Should not contain backslash")
    }
    
    func testPassthrough() {
        // Already clean expression should pass through unchanged
        XCTAssertEqual(LatexNormalizer.normalize("sin(pi/4) + 2^3"), "sin(pi/4) + 2^3")
    }
    
    func testEmptyInput() {
        XCTAssertEqual(LatexNormalizer.normalize(""), "")
    }
    
    // MARK: - Cleanup
    
    func testRemoveRemainingBraces() {
        XCTAssertEqual(LatexNormalizer.normalize("x^{2}"), "x^(2)")
    }
    
    func testCollapseSpaces() {
        XCTAssertEqual(LatexNormalizer.normalize("x  +  1"), "x + 1")
    }
    
    // MARK: - Robustness
    
    func testRemoveQuestionNumbering() {
        // "1) x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("1) x+1"), "x+1", "Should remove '1)' prefix")
        
        // "1. x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("1. x+1"), "x+1", "Should remove '1.' prefix")
        
        // "a) x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("a) x+1"), "x+1", "Should remove 'a)' prefix")
        
        // "(a) x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("(a) x+1"), "x+1", "Should remove '(a)' prefix")
        
        // "Q1: x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("Q1: x+1"), "x+1", "Should remove 'Q1:' prefix")
        
        // "Problem 1: x+1" -> "x+1"
        XCTAssertEqual(LatexNormalizer.normalize("Problem 1: x+1"), "x+1", "Should remove 'Problem 1:' prefix")
        
        // "1) \frac{1}{2}" -> "(1)/(2)"
        XCTAssertEqual(LatexNormalizer.normalize("1) \\frac{1}{2}"), "(1)/(2)", "Should remove numbering before fraction")
        
        // Whitespace handling
        XCTAssertEqual(LatexNormalizer.normalize("  2.  x^2"), "x^2", "Should handle leading whitespace before numbering")
    }
}
