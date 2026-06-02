// ScientificCalculatorTests/PerformanceTests.swift
// Scientific Calculator - Performance Tests

import XCTest
@testable import ScientificCalculator

final class PerformanceTests: XCTestCase {
    
    let dispatcher = Dispatcher()
    
    // MARK: - Parsing Performance
    
    func testParsingPerformance() {
        let expression = "sin(pi/4) + cos(pi/4) * 2^10 / sqrt(16)"
        let metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]
        
        measure(metrics: metrics) {
            for _ in 0..<1000 {
                _ = Parser.parse(expression)
            }
        }
    }
    
    // MARK: - Evaluation Performance
    
    func testEvaluationPerformance() async {
        let expression = "2 + 3 * 4"
        let metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric()]
        
        measure(metrics: metrics) {
            let expectation = expectation(description: "Evaluate")
            Task {
                for _ in 0..<100 {
                    _ = await dispatcher.evaluateAsync(expression: expression)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testComplexExpressionPerformance() async {
        let expression = "sin(pi/4)^2 + cos(pi/4)^2 + ln(e^2) * sqrt(16)"
        let metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]
        
        measure(metrics: metrics) {
            let expectation = expectation(description: "Evaluate")
            Task {
                for _ in 0..<100 {
                    _ = await dispatcher.evaluateAsync(expression: expression)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Matrix Performance
    
    func testMatrixMultiplicationPerformance() async {
        // Create two 50x50 matrices
        let size = 50
        var matrixStringA = "["
        var matrixStringB = "["
        
        for i in 0..<size {
            var rowA = "["
            var rowB = "["
            for j in 0..<size {
                rowA += "\(Double(i+j))" + (j < size-1 ? "," : "")
                rowB += "\(Double(i*j))" + (j < size-1 ? "," : "")
            }
            rowA += "]"
            rowB += "]"
            
            matrixStringA += rowA + (i < size-1 ? "," : "")
            matrixStringB += rowB + (i < size-1 ? "," : "")
        }
        matrixStringA += "]"
        matrixStringB += "]"
        
        let expression = "\(matrixStringA) * \(matrixStringB)"
        let metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]
        
        measure(metrics: metrics) {
            let expectation = expectation(description: "Evaluate")
            Task {
                _ = await dispatcher.evaluateAsync(expression: expression)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Performance Stability
    
    func testPerformanceStability() async throws {
        let expression = "2 + 3 * 4 - 5 / 2"
        var times: [Double] = []
        
        // Warm up
        for _ in 0..<10 {
            _ = await dispatcher.evaluateAsync(expression: expression)
        }
        
        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            for _ in 0..<10 {
                _ = await dispatcher.evaluateAsync(expression: expression)
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
    
    func testMetricsReported() async throws {
        let report = await dispatcher.evaluateAsync(expression: "2 + 3")
        
        XCTAssertGreaterThan(report.metrics.parseTimeMs, 0)
        XCTAssertGreaterThanOrEqual(report.metrics.evalTimeMs, 0)
        XCTAssertGreaterThan(report.metrics.totalTimeMs, 0)
        XCTAssertEqual(report.metrics.astNodeCount, 3)
        XCTAssertEqual(report.metrics.expressionLength, 5)
    }
    
    func testMetricsNodeCount() async throws {
        let simpleReport = await dispatcher.evaluateAsync(expression: "42")
        XCTAssertEqual(simpleReport.metrics.astNodeCount, 1)
        
        let complexReport = await dispatcher.evaluateAsync(expression: "sin(cos(tan(0)))")
        XCTAssertEqual(complexReport.metrics.astNodeCount, 4)  // sin, cos, tan, 0
    }
}
