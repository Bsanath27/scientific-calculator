// ScientificCalculatorTests/DeadlockFixTests.swift
import XCTest
@testable import ScientificCalculator

final class DeadlockFixTests: XCTestCase {
    
    func testSymbolicEngineSyncEvaluateReturnsError() {
        let engine = SymbolicEngine()
        let ast = Node.variable("x", context: .empty)
        let context = EvaluationContext.empty
        
        // This used to use a semaphore and block. Now it should return immediately with an error.
        let result = engine.evaluate(ast: ast, context: context)
        
        if case .error(let msg, let issue) = result {
            XCTAssertTrue(msg.contains("requires async execution"))
            XCTAssertEqual(issue, .symbolicComputationRequired)
        } else {
            XCTFail("Expected symbolicComputationRequired error, got: \(result)")
        }
    }
    
    func testDispatcherSyncEvaluateDoesNotFallback() {
        let dispatcher = Dispatcher()
        dispatcher.mode = .numeric
        
        let expression = "x + 1" // Requires symbolic fallback
        
        // This used to fallback and block. Now it should return the error from the numeric engine
        // (which is undefinedVariable) and NOT attempt to call SymbolicEngine.evaluate if it blocks.
        let report = dispatcher.evaluate(expression: expression)
        
        if case .error(_, let issue) = report.result {
            XCTAssertEqual(issue, .undefinedVariable, "Should return undefinedVariable error without attempting symbolic fallback synchronously")
        } else {
            XCTFail("Expected error result for undefined variable in sync path, got: \(report.result)")
        }
    }
    
    func testDispatcherAsyncEvaluateStillWorks() async {
        let dispatcher = Dispatcher()
        dispatcher.mode = .numeric
        
        let expression = "2 + 2"
        let report = await dispatcher.evaluateAsync(expression: expression)
        
        XCTAssertEqual(report.result.doubleValue, 4.0)
    }
}
