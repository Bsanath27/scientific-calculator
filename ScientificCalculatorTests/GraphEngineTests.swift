// ScientificCalculatorTests/GraphEngineTests.swift
// Scientific Calculator - GraphEngine Unit Tests

import XCTest
@testable import ScientificCalculator

final class GraphEngineTests: XCTestCase {
    
    let engine = GraphEngine()
    
    // MARK: - Basic Sampling
    
    func testSampleSinX() {
        let result = engine.sample(expression: "sin(x)", xMin: -3.14, xMax: 3.14, pointCount: 100)
        XCTAssertEqual(result.value.count, 100, "All points should be valid for sin(x)")
    }
    
    func testSampleXSquared() {
        let result = engine.sample(expression: "x^2", xMin: -5, xMax: 5, pointCount: 50)
        XCTAssertEqual(result.value.count, 50, "All points should be valid for x^2")
        
        // x=0 should produce y=0
        let midpoint = result.value[result.value.count / 2]
        XCTAssertEqual(midpoint.y, 0.0, accuracy: 0.5, "Midpoint of x^2 should be near 0")
    }
    
    func testSampleConstantExpression() {
        let result = engine.sample(expression: "5", xMin: -10, xMax: 10, pointCount: 20)
        XCTAssertEqual(result.value.count, 20)
        
        // All y values should be 5.0
        for point in result.value {
            XCTAssertEqual(point.y, 5.0, accuracy: 0.0001)
        }
    }
    
    // MARK: - Edge Cases
    
    func testSampleWithDomainErrors() {
        // sqrt(x) has domain errors for x < 0
        let result = engine.sample(expression: "sqrt(x)", xMin: -5, xMax: 5, pointCount: 100)
        // Should have fewer than 100 points (negative x values skipped)
        XCTAssertLessThan(result.value.count, 100)
        XCTAssertGreaterThan(result.value.count, 40)
    }
    
    func testSampleInvalidExpression() {
        let result = engine.sample(expression: "+++", xMin: -1, xMax: 1, pointCount: 10)
        XCTAssertEqual(result.value.count, 0, "Invalid expression should produce no points")
    }
    
    func testSampleWithAsymptotes() {
        // 1/x has asymptote at x=0
        let result = engine.sample(expression: "1/x", xMin: -10, xMax: 10, pointCount: 200)
        // Should have fewer than 200 points (x=0 produces division error)
        XCTAssertLessThan(result.value.count, 200)
        XCTAssertGreaterThan(result.value.count, 100)
    }
    
    // MARK: - Point IDs
    
    func testPointIDsAreSequential() {
        let result = engine.sample(expression: "x", xMin: 0, xMax: 10, pointCount: 10)
        for (index, point) in result.value.enumerated() {
            XCTAssertEqual(point.id, index, "Point IDs should be sequential integers")
        }
    }
    
    // MARK: - Multi-plot
    
    func testSampleMultiple() {
        let result = engine.sampleMultiple(
            expressions: ["sin(x)", "cos(x)", "x"],
            xMin: -3.14, xMax: 3.14, pointCount: 50
        )
        XCTAssertEqual(result.value.count, 3, "Should have 3 plot functions")
        
        // Each function should have points
        for fn in result.value {
            XCTAssertGreaterThan(fn.points.count, 0)
        }
    }
    
    // MARK: - Metrics
    
    func testMetricsReported() {
        let result = engine.sample(expression: "sin(x)", xMin: -10, xMax: 10, pointCount: 100)
        XCTAssertGreaterThan(result.metrics.executionTimeMs, 0)
        XCTAssertEqual(result.metrics.dataSize, 100)
        XCTAssertEqual(result.metrics.operationType, "Graph Sample")
    }
    
    // MARK: - Variable Support
    
    func testVariableInExpression() {
        // sin(x) should parse x as a variable
        let result = engine.sample(expression: "sin(x)", xMin: 0, xMax: 3.14159, pointCount: 10)
        XCTAssertEqual(result.value.count, 10)
        
        // First point should be sin(0) ≈ 0
        XCTAssertEqual(result.value.first?.y ?? 99, 0.0, accuracy: 0.01)
    }
    
    func testComplexExpression() {
        let result = engine.sample(expression: "sin(x)*cos(x)+x^2", xMin: -2, xMax: 2, pointCount: 20)
        XCTAssertEqual(result.value.count, 20, "Complex expression should produce all points")
    }
}
