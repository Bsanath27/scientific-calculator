// ScientificCalculatorTests/EquationDispatcherTests.swift
// Scientific Calculator - Equation Dispatching Tests

import XCTest
@testable import ScientificCalculator

final class EquationDispatcherTests: XCTestCase {
    
    let dispatcher = Dispatcher()
    
    // Helper to evaluate without parsing boilerplate
    func evaluate(_ expression: String) -> EvaluationResult {
        let report = dispatcher.evaluate(expression: expression)
        return report.result
    }
    
    func testEquationDispatch() {
        // This relies on the live running Python service
        // We assume the service is running for these tests
        
        // 3x - 5 = 16  =>  3x = 21  =>  x = 7
        let result = evaluate("3*x - 5 = 16")
        
        switch result {
        case .symbolic(let res, _, _):
            // Expected: Eq(x, 7)
            XCTAssertTrue(res.contains("Eq") || res.contains("Equality") || res.contains("x") && res.contains("7"))
        case .error(let msg):
            XCTFail("Equation dispatch failed with error: \(msg)")
        default:
            XCTFail("Expected symbolic result for equation, got \(result)")
        }
    }
    
    func testUndefinedVariableDispatch() {
        // "3x - 21" has undefined variable x (assuming no bindings)
        // Should fallback to symbolic engine
        let result = evaluate("3*x - 21")
        
        switch result {
        case .symbolic(let res, _, _):
            // Expected: 3*x - 21
            XCTAssertTrue(res.contains("x"))
            XCTAssertTrue(res.contains("3") || res.contains("21"))
        case .error(let msg):
             XCTFail("Variable dispatch failed with error: \(msg)")
        default:
             XCTFail("Expected symbolic result for variable expression, got \(result)")
        }
    }
    
    func testNumericErrorDispatch() {
        // 1/0 is a numeric error but NOT an equation/variable error
        // Should stay as numeric error and NOT fallback to Symbolic (which would also fail or return infinity)
        // But our logic specifically checks for "Equality" or "Undefined variable" strings
        let result = evaluate("1/0")
        
        if case .error(let msg) = result {
            XCTAssertTrue(msg.contains("Division by zero"))
        } else {
            XCTFail("Expected numeric error for 1/0, got \(result)")
        }
    }
}
