// ScientificCalculatorTests/NumericEngineTests.swift
// Scientific Calculator - Numeric Engine Unit Tests

import XCTest
@testable import ScientificCalculator

final class NumericEngineTests: XCTestCase {
    
    let engine = NumericEngine()
    let dispatcher = Dispatcher()
    
    // MARK: - Helper
    
    func evaluate(_ expression: String) async -> Double? {
        let report = await dispatcher.evaluateAsync(expression: expression)
        return report.result.doubleValue
    }
    
    // MARK: - Basic Arithmetic
    
    func testAddition() async throws {
        XCTAssertEqual(await evaluate("2 + 3")!, 5.0)
        XCTAssertEqual(await evaluate("0 + 0")!, 0.0)
        XCTAssertEqual(await evaluate("-1 + 1")!, 0.0)
    }
    
    func testSubtraction() async throws {
        XCTAssertEqual(await evaluate("5 - 3")!, 2.0)
        XCTAssertEqual(await evaluate("3 - 5")!, -2.0)
    }
    
    func testMultiplication() async throws {
        XCTAssertEqual(await evaluate("4 * 5")!, 20.0)
        XCTAssertEqual(await evaluate("0 * 100")!, 0.0)
        XCTAssertEqual(await evaluate("-3 * 4")!, -12.0)
    }
    
    func testDivision() async throws {
        XCTAssertEqual(await evaluate("10 / 2")!, 5.0)
        XCTAssertEqual(await evaluate("1 / 4")!, 0.25)
    }
    
    func testPower() async throws {
        XCTAssertEqual(await evaluate("2 ^ 10")!, 1024.0)
        XCTAssertEqual(await evaluate("3 ^ 0")!, 1.0)
        XCTAssertEqual(await evaluate("4 ^ 0.5")!, 2.0)
    }
    
    // MARK: - Operator Precedence
    
    func testPrecedence() async throws {
        XCTAssertEqual(await evaluate("2 + 3 * 4")!, 14.0)
        XCTAssertEqual(await evaluate("(2 + 3) * 4")!, 20.0)
        XCTAssertEqual(await evaluate("2 * 3 ^ 2")!, 18.0)
        XCTAssertEqual(await evaluate("2 ^ 3 ^ 2")!, 512.0)  // Right assoc: 2^9
    }
    
    // MARK: - Constants
    
    func testPi() async throws {
        let result = try XCTUnwrap(await evaluate("pi"))
        XCTAssertEqual(result, Double.pi, accuracy: 0.0001)
    }
    
    func testE() async throws {
        let result = try XCTUnwrap(await evaluate("e"))
        XCTAssertEqual(result, M_E, accuracy: 0.0001)
    }
    
    // MARK: - Trigonometric Functions
    
    func testSin() async throws {
        XCTAssertEqual(await evaluate("sin(0)")!, 0.0, accuracy: 0.0001)
        let sinPiOver2 = try XCTUnwrap(await evaluate("sin(pi/2)"))
        XCTAssertEqual(sinPiOver2, 1.0, accuracy: 0.0001)
    }
    
    func testCos() async throws {
        XCTAssertEqual(await evaluate("cos(0)")!, 1.0, accuracy: 0.0001)
        let cosPi = try XCTUnwrap(await evaluate("cos(pi)"))
        XCTAssertEqual(cosPi, -1.0, accuracy: 0.0001)
    }
    
    func testTan() async throws {
        XCTAssertEqual(await evaluate("tan(0)")!, 0.0, accuracy: 0.0001)
        let tanPiOver4 = try XCTUnwrap(await evaluate("tan(pi/4)"))
        XCTAssertEqual(tanPiOver4, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Logarithmic Functions
    
    func testLog10() async throws {
        XCTAssertEqual(await evaluate("log(10)")!, 1.0, accuracy: 0.0001)
        XCTAssertEqual(await evaluate("log(100)")!, 2.0, accuracy: 0.0001)
        XCTAssertEqual(await evaluate("log(1)")!, 0.0, accuracy: 0.0001)
    }
    
    func testLn() async throws {
        XCTAssertEqual(await evaluate("ln(1)")!, 0.0, accuracy: 0.0001)
        XCTAssertEqual(await evaluate("ln(e)")!, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Square Root
    
    func testSqrt() async throws {
        XCTAssertEqual(await evaluate("sqrt(4)")!, 2.0)
        XCTAssertEqual(await evaluate("sqrt(2)")!, sqrt(2), accuracy: 0.0001)
        XCTAssertEqual(await evaluate("sqrt(0)")!, 0.0)
    }
    
    // MARK: - Complex Expressions
    
    func testComplexExpression() async throws {
        // sin(pi/4) + cos(pi/4) ≈ sqrt(2)
        let result = try XCTUnwrap(await evaluate("sin(pi/4) + cos(pi/4)"))
        XCTAssertEqual(result, sqrt(2), accuracy: 0.0001)
    }
    
    func testNestedFunctions() async throws {
        // sqrt(sin(pi/6)^2 + cos(pi/6)^2) = 1 (Pythagorean identity)
        let result = try XCTUnwrap(await evaluate("sqrt(sin(pi/6)^2 + cos(pi/6)^2)"))
        XCTAssertEqual(result, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Edge Cases
    
    func testDivisionByZero() async {
        let report = await dispatcher.evaluateAsync(expression: "1/0")
        if case .error(let msg, _) = report.result {
            XCTAssertTrue(msg.contains("Division by zero"))
        } else {
            XCTFail("Expected division by zero error")
        }
    }
    
    func testLogNegative() async {
        let report = await dispatcher.evaluateAsync(expression: "log(-1)")
        if case .error(let msg, _) = report.result {
            XCTAssertTrue(msg.contains("positive"))
        } else {
            XCTFail("Expected domain error")
        }
    }
    
    func testSqrtNegative() async {
        let report = await dispatcher.evaluateAsync(expression: "sqrt(-1)")
        if case .error(let msg, _) = report.result {
            XCTAssertTrue(msg.contains("non-negative"))
        } else {
            XCTFail("Expected domain error")
        }
    }
    
    func testLargeNumber() async throws {
        let result = try XCTUnwrap(await evaluate("2^50"))
        XCTAssertEqual(result, pow(2, 50), accuracy: 1)
    }
    
    func testSmallNumber() async throws {
        let result = try XCTUnwrap(await evaluate("1/1000000"))
        XCTAssertEqual(result, 0.000001, accuracy: 0.0000001)
    }
    
    // MARK: - Determinism
    
    func testDeterminism() async throws {
        let expression = "sin(pi/4) * 2 + cos(pi/3) / 2"
        var results: [Double] = []
        for _ in 0..<100 {
            if let result = await evaluate(expression) {
                results.append(result)
            }
        }
        
        XCTAssertEqual(results.count, 100)
        let first = results[0]
        for result in results {
            XCTAssertEqual(result, first)
        }
    }
}
