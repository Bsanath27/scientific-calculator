// ScientificCalculatorTests/PerformanceTests.swift
// Scientific Calculator - Performance Tests

import XCTest
@testable import ScientificCalculator

final class PerformanceTests: XCTestCase {
    
    let dispatcher = Dispatcher()
    
    // MARK: - Parsing Performance
    
    func testParsingPerformance() throws {
        let expression = "sin(pi/4) + cos(pi/4) * 2^10 / sqrt(16)"
        
        measure {
            for _ in 0..<1000 {
                _ = Parser.parse(expression)
            }
        }
    }
    
    // MARK: - Evaluation Performance
    
    func testEvaluationPerformance() throws {
        let expression = "2 + 3 * 4"
        
        measure {
            for _ in 0..<1000 {
                _ = dispatcher.evaluate(expression: expression)
            }
        }
    }
    
    func testComplexExpressionPerformance() throws {
        let expression = "sin(pi/4)^2 + cos(pi/4)^2 + ln(e^2) * sqrt(16)"
        
        measure {
            for _ in 0..<1000 {
                _ = dispatcher.evaluate(expression: expression)
            }
        }
    }
    
    // MARK: - Performance Stability
    
    func testPerformanceStability() throws {
        let expression = "2 + 3 * 4 - 5 / 2"
        var times: [Double] = []
        
        // Warm up
        for _ in 0..<10 {
            _ = dispatcher.evaluate(expression: expression)
        }
        
        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            for _ in 0..<10 {
                _ = dispatcher.evaluate(expression: expression)
            }
            let end = CFAbsoluteTimeGetCurrent()
            times.append((end - start) * 1000)
        }
        
        let avg = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - avg, 2) }.reduce(0, +) / Double(times.count)
        let stdDev = sqrt(variance)
        
        // Coefficient of variation should be reasonable
        // (Relaxed threshold for variable test environments)
        XCTAssertLessThan(stdDev / avg, 2.0, "Performance variance too high")
    }
    
    // MARK: - Metrics Accuracy
    
    func testMetricsReported() throws {
        let report = dispatcher.evaluate(expression: "2 + 3")
        
        XCTAssertGreaterThan(report.metrics.parseTimeMs, 0)
        XCTAssertGreaterThanOrEqual(report.metrics.evalTimeMs, 0)
        XCTAssertGreaterThan(report.metrics.totalTimeMs, 0)
        XCTAssertEqual(report.metrics.astNodeCount, 3)
        XCTAssertEqual(report.metrics.expressionLength, 5)
    }
    
    func testMetricsNodeCount() throws {
        let simpleReport = dispatcher.evaluate(expression: "42")
        XCTAssertEqual(simpleReport.metrics.astNodeCount, 1)
        
        let complexReport = dispatcher.evaluate(expression: "sin(cos(tan(0)))")
        XCTAssertEqual(complexReport.metrics.astNodeCount, 4)  // sin, cos, tan, 0
    }
}
