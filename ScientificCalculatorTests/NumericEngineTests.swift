// ScientificCalculatorTests/NumericEngineTests.swift
// Scientific Calculator - Numeric Engine Unit Tests

import XCTest
@testable import ScientificCalculator

final class NumericEngineTests: XCTestCase {
    
    let engine = NumericEngine()
    let dispatcher = Dispatcher()
    
    // MARK: - Helper
    
    func evaluate(_ expression: String) -> Double? {
        let report = dispatcher.evaluate(expression: expression)
        return report.result.doubleValue
    }
    
    // MARK: - Basic Arithmetic
    
    func testAddition() throws {
        XCTAssertEqual(evaluate("2 + 3")!, 5.0)
        XCTAssertEqual(evaluate("0 + 0")!, 0.0)
        XCTAssertEqual(evaluate("-1 + 1")!, 0.0)
    }
    
    func testSubtraction() throws {
        XCTAssertEqual(evaluate("5 - 3")!, 2.0)
        XCTAssertEqual(evaluate("3 - 5")!, -2.0)
    }
    
    func testMultiplication() throws {
        XCTAssertEqual(evaluate("4 * 5")!, 20.0)
        XCTAssertEqual(evaluate("0 * 100")!, 0.0)
        XCTAssertEqual(evaluate("-3 * 4")!, -12.0)
    }
    
    func testDivision() throws {
        XCTAssertEqual(evaluate("10 / 2")!, 5.0)
        XCTAssertEqual(evaluate("1 / 4")!, 0.25)
    }
    
    func testPower() throws {
        XCTAssertEqual(evaluate("2 ^ 10")!, 1024.0)
        XCTAssertEqual(evaluate("3 ^ 0")!, 1.0)
        XCTAssertEqual(evaluate("4 ^ 0.5")!, 2.0)
    }
    
    // MARK: - Operator Precedence
    
    func testPrecedence() throws {
        XCTAssertEqual(evaluate("2 + 3 * 4")!, 14.0)
        XCTAssertEqual(evaluate("(2 + 3) * 4")!, 20.0)
        XCTAssertEqual(evaluate("2 * 3 ^ 2")!, 18.0)
        XCTAssertEqual(evaluate("2 ^ 3 ^ 2")!, 512.0)  // Right assoc: 2^9
    }
    
    // MARK: - Constants
    
    func testPi() throws {
        let result = try XCTUnwrap(evaluate("pi"))
        XCTAssertEqual(result, Double.pi, accuracy: 0.0001)
    }
    
    func testE() throws {
        let result = try XCTUnwrap(evaluate("e"))
        XCTAssertEqual(result, M_E, accuracy: 0.0001)
    }
    
    // MARK: - Trigonometric Functions
    
    func testSin() throws {
        XCTAssertEqual(evaluate("sin(0)")!, 0.0, accuracy: 0.0001)
        let sinPiOver2 = try XCTUnwrap(evaluate("sin(pi/2)"))
        XCTAssertEqual(sinPiOver2, 1.0, accuracy: 0.0001)
    }
    
    func testCos() throws {
        XCTAssertEqual(evaluate("cos(0)")!, 1.0, accuracy: 0.0001)
        let cosPi = try XCTUnwrap(evaluate("cos(pi)"))
        XCTAssertEqual(cosPi, -1.0, accuracy: 0.0001)
    }
    
    func testTan() throws {
        XCTAssertEqual(evaluate("tan(0)")!, 0.0, accuracy: 0.0001)
        let tanPiOver4 = try XCTUnwrap(evaluate("tan(pi/4)"))
        XCTAssertEqual(tanPiOver4, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Logarithmic Functions
    
    func testLog10() throws {
        XCTAssertEqual(evaluate("log(10)")!, 1.0, accuracy: 0.0001)
        XCTAssertEqual(evaluate("log(100)")!, 2.0, accuracy: 0.0001)
        XCTAssertEqual(evaluate("log(1)")!, 0.0, accuracy: 0.0001)
    }
    
    func testLn() throws {
        XCTAssertEqual(evaluate("ln(1)")!, 0.0, accuracy: 0.0001)
        XCTAssertEqual(evaluate("ln(e)")!, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Square Root
    
    func testSqrt() throws {
        XCTAssertEqual(evaluate("sqrt(4)")!, 2.0)
        XCTAssertEqual(evaluate("sqrt(2)")!, sqrt(2), accuracy: 0.0001)
        XCTAssertEqual(evaluate("sqrt(0)")!, 0.0)
    }
    
    // MARK: - Complex Expressions
    
    func testComplexExpression() throws {
        // sin(pi/4) + cos(pi/4) ≈ sqrt(2)
        let result = try XCTUnwrap(evaluate("sin(pi/4) + cos(pi/4)"))
        XCTAssertEqual(result, sqrt(2), accuracy: 0.0001)
    }
    
    func testNestedFunctions() throws {
        // sqrt(sin(pi/6)^2 + cos(pi/6)^2) = 1 (Pythagorean identity)
        let result = try XCTUnwrap(evaluate("sqrt(sin(pi/6)^2 + cos(pi/6)^2)"))
        XCTAssertEqual(result, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Edge Cases
    
    func testDivisionByZero() {
        let report = dispatcher.evaluate(expression: "1/0")
        if case .error(let msg) = report.result {
            XCTAssertTrue(msg.contains("Division by zero"))
        } else {
            XCTFail("Expected division by zero error")
        }
    }
    
    func testLogNegative() {
        let report = dispatcher.evaluate(expression: "log(-1)")
        if case .error(let msg) = report.result {
            XCTAssertTrue(msg.contains("positive"))
        } else {
            XCTFail("Expected domain error")
        }
    }
    
    func testSqrtNegative() {
        let report = dispatcher.evaluate(expression: "sqrt(-1)")
        if case .error(let msg) = report.result {
            XCTAssertTrue(msg.contains("non-negative"))
        } else {
            XCTFail("Expected domain error")
        }
    }
    
    func testLargeNumber() throws {
        let result = try XCTUnwrap(evaluate("2^50"))
        XCTAssertEqual(result, pow(2, 50), accuracy: 1)
    }
    
    func testSmallNumber() throws {
        let result = try XCTUnwrap(evaluate("1/1000000"))
        XCTAssertEqual(result, 0.000001, accuracy: 0.0000001)
    }
    
    // MARK: - Determinism
    
    func testDeterminism() throws {
        let expression = "sin(pi/4) * 2 + cos(pi/3) / 2"
        let results = (0..<100).compactMap { _ in evaluate(expression) }
        
        XCTAssertEqual(results.count, 100)
        let first = results[0]
        for result in results {
            XCTAssertEqual(result, first)
        }
    }
}
