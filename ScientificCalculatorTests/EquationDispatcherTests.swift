// ScientificCalculatorTests/EquationDispatcherTests.swift
import XCTest
@testable import ScientificCalculator

final class EquationDispatcherTests: XCTestCase {
    
    // Mock Engines
    class MockNumericEngine: MathEngine {
        let engineName = "MockNumeric"
        let mode = ComputationMode.numeric
        
        func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult {
            // Mimic NumericEngine behavior partially or pass through
            // For this test, we want to simulate the real NumericEngine's failure
            let realEngine = NumericEngine()
            return realEngine.evaluate(ast: ast, context: context)
        }
    }
    
    class MockSymbolicEngine: MathEngine {
        let engineName = "MockSymbolic"
        let mode = ComputationMode.symbolic
        
        var wasCalled = false
        
        func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult {
            wasCalled = true
            return .symbolic("x = 7", latex: "x = 7", metadata: nil)
        }
    }
    
    func testDispatcherSwitchesToSymbolicForEquation() {
        let numeric = MockNumericEngine()
        let symbolic = MockSymbolicEngine()
        let dispatcher = Dispatcher(numeric: numeric, symbolic: symbolic)
        dispatcher.mode = .numeric
        
        let expression = "3*x - 5 = 16"
        let report = dispatcher.evaluate(expression: expression)
        
        XCTAssertTrue(symbolic.wasCalled, "Dispatcher should switch to SymbolicEngine for equations")
        
        if case .symbolic(let res, _, _) = report.result {
            XCTAssertEqual(res, "x = 7")
        } else {
            XCTFail("Result should be symbolic, got: \(report.result)")
        }
    }
    
    func testDispatcherSwitchesToSymbolicForUndefinedVariable() {
        let numeric = MockNumericEngine()
        let symbolic = MockSymbolicEngine()
        let dispatcher = Dispatcher(numeric: numeric, symbolic: symbolic)
        dispatcher.mode = .numeric
        
        let expression = "3*x + 10" // x is undefined
        let report = dispatcher.evaluate(expression: expression)
        
        XCTAssertTrue(symbolic.wasCalled, "Dispatcher should switch to SymbolicEngine for undefined variables")
    }
    
    func testParserHandlesEquals() {
        let expression = "3*x - 5 = 16"
        let result = Parser.parse(expression)
        
        switch result {
        case .success(let ast):
            print("Parser success: \(ast)")
        case .failure(let error):
            XCTFail("Parser failed to parse equation: \(error)")
        }
    }
}
