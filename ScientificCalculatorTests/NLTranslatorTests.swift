// NLTranslatorTests.swift
// Tests for the Natural Language → Expression Translator

import XCTest
@testable import ScientificCalculator

final class NLTranslatorTests: XCTestCase {
    
    // MARK: - Passthrough (already math expressions)
    
    func testPassthroughNumericExpression() {
        let result = NLTranslator.translate("2 + 3 * 4")
        XCTAssertFalse(result.didTranslate)
    }
    
    func testPassthroughFunctionExpression() {
        let result = NLTranslator.translate("sin(pi/4)")
        XCTAssertFalse(result.didTranslate)
    }
    
    func testPassthroughNumber() {
        let result = NLTranslator.translate("42")
        XCTAssertFalse(result.didTranslate)
    }
    
    // MARK: - Square Root
    
    func testSquareRoot() {
        let result = NLTranslator.translate("square root of 144")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "sqrt(144)")
        XCTAssertEqual(result.operation, .evaluate)
    }
    
    func testSquareRootExpression() {
        let result = NLTranslator.translate("square root of 16 + 9")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("sqrt"))
    }
    
    // MARK: - Cube Root
    
    func testCubeRoot() {
        let result = NLTranslator.translate("cube root of 27")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("^(1/3)"))
    }
    
    // MARK: - Nth Root
    
    func testNthRoot() {
        let result = NLTranslator.translate("4th root of 256")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("^(1/4)"))
    }
    
    // MARK: - Powers
    
    func testPowerOf() {
        let result = NLTranslator.translate("3 to the power of 4")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("^"))
    }
    
    func testSquared() {
        let result = NLTranslator.translate("5 squared")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("^2"))
    }
    
    func testCubed() {
        let result = NLTranslator.translate("7 cubed")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("^3"))
    }
    
    // MARK: - Trigonometry
    
    func testSineOf() {
        let result = NLTranslator.translate("sine of pi over 4")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.hasPrefix("sin("))
    }
    
    func testCosineOf() {
        let result = NLTranslator.translate("cosine of 0")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "cos(0)")
    }
    
    func testTangentOf() {
        let result = NLTranslator.translate("tangent of pi")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.hasPrefix("tan("))
    }
    
    // MARK: - Logarithms
    
    func testLogBase() {
        let result = NLTranslator.translate("log base 2 of 8")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "log(8)/log(2)")
    }
    
    func testNaturalLog() {
        let result = NLTranslator.translate("natural log of 10")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "ln(10)")
    }
    
    func testLogOf() {
        let result = NLTranslator.translate("log of 100")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "log(100)")
    }
    
    // MARK: - Percentage
    
    func testPercentOf() {
        let result = NLTranslator.translate("15 percent of 200")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "200 * 15 / 100")
    }
    
    func testWhatIsPercentOf() {
        let result = NLTranslator.translate("what is 25 percent of 80")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "80 * 25 / 100")
    }
    
    // MARK: - Arithmetic
    
    func testPlus() {
        let result = NLTranslator.translate("5 plus 3")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("+"))
    }
    
    func testMinus() {
        let result = NLTranslator.translate("10 minus 4")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("-"))
    }
    
    func testTimes() {
        let result = NLTranslator.translate("6 times 7")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("*"))
    }
    
    func testDividedBy() {
        let result = NLTranslator.translate("20 divided by 4")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("/"))
    }
    
    func testWhatIsArithmetic() {
        let result = NLTranslator.translate("what is 12 plus 8")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("+"))
    }
    
    // MARK: - Calculus
    
    func testDerivative() {
        let result = NLTranslator.translate("derivative of x^3")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .differentiate)
        XCTAssertEqual(result.variable, "x")
    }
    
    func testDerivativeWithRespectTo() {
        let result = NLTranslator.translate("derivative of sin(t) with respect to t")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .differentiate)
        XCTAssertEqual(result.variable, "t")
    }
    
    func testDifferentiate() {
        let result = NLTranslator.translate("differentiate x^2 + 3x")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .differentiate)
    }
    
    func testIntegrate() {
        let result = NLTranslator.translate("integrate sin(x) dx")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .integrate)
        XCTAssertEqual(result.variable, "x")
    }
    
    func testIntegralOf() {
        let result = NLTranslator.translate("integral of x^2")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .integrate)
    }
    
    // MARK: - Solve
    
    func testSolveFor() {
        let result = NLTranslator.translate("solve x^2 - 4 = 0 for x")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .solve)
        XCTAssertEqual(result.variable, "x")
    }
    
    func testSolve() {
        let result = NLTranslator.translate("solve 2x + 1 = 0")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.operation, .solve)
    }
    
    // MARK: - Constants
    
    func testPi() {
        let result = NLTranslator.translate("pi")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "pi")
    }
    
    func testEulersNumber() {
        let result = NLTranslator.translate("euler's number")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "E")
    }
    
    // MARK: - Factorial
    
    func testFactorialOf() {
        let result = NLTranslator.translate("factorial of 5")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "5!")
    }
    
    func testNFactorial() {
        let result = NLTranslator.translate("10 factorial")
        XCTAssertTrue(result.didTranslate)
        XCTAssertEqual(result.expression, "10!")
    }
    
    // MARK: - Absolute Value
    
    func testAbsoluteValue() {
        let result = NLTranslator.translate("absolute value of -5")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("abs("))
    }
    
    // MARK: - Edge Cases
    
    func testEmptyInput() {
        let result = NLTranslator.translate("")
        XCTAssertFalse(result.didTranslate)
    }
    
    func testWhitespaceOnly() {
        let result = NLTranslator.translate("   ")
        XCTAssertFalse(result.didTranslate)
    }
    
    func testMixedCase() {
        let result = NLTranslator.translate("Square Root Of 25")
        XCTAssertTrue(result.didTranslate)
        XCTAssertTrue(result.expression.contains("sqrt"))
    }
}
