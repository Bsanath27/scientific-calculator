// StatsEngineTests.swift
// Scientific Calculator - Phase 3: Statistics Engine Tests

import XCTest
@testable import ScientificCalculator

final class StatsEngineTests: XCTestCase {
    private let engine = StatsEngine()
    
    // MARK: - Mean
    
    func testMean() {
        let result = engine.mean([1, 2, 3, 4, 5]).value
        XCTAssertEqual(result, 3.0, accuracy: 1e-10)
    }
    
    func testMeanSingleValue() {
        let result = engine.mean([42.0]).value
        XCTAssertEqual(result, 42.0, accuracy: 1e-10)
    }
    
    // MARK: - Median
    
    func testMedianOdd() {
        let result = engine.median([3, 1, 4, 1, 5]).value
        XCTAssertEqual(result, 3.0, accuracy: 1e-10)
    }
    
    func testMedianEven() {
        let result = engine.median([1, 2, 3, 4]).value
        XCTAssertEqual(result, 2.5, accuracy: 1e-10)
    }
    
    // MARK: - Variance
    
    func testVariance() {
        let result = engine.variance([2, 4, 4, 4, 5, 5, 7, 9]).value
        XCTAssertEqual(result, 4.0, accuracy: 1e-10)
    }
    
    // MARK: - Standard Deviation
    
    func testStandardDeviation() {
        let result = engine.standardDeviation([2, 4, 4, 4, 5, 5, 7, 9]).value
        XCTAssertEqual(result, 2.0, accuracy: 1e-10)
    }
    
    // MARK: - Correlation
    
    func testCorrelationPerfectPositive() {
        let result = engine.correlation([1, 2, 3, 4, 5], [2, 4, 6, 8, 10]).value
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }
    
    func testCorrelationPerfectNegative() {
        let result = engine.correlation([1, 2, 3, 4, 5], [10, 8, 6, 4, 2]).value
        XCTAssertEqual(result, -1.0, accuracy: 1e-10)
    }
    
    func testCorrelationZero() {
        // x and x^2 centered around 0 have zero correlation
        let x = [-2.0, -1.0, 0.0, 1.0, 2.0]
        let y = [4.0, 1.0, 0.0, 1.0, 4.0]
        let result = engine.correlation(x, y).value
        XCTAssertEqual(result, 0.0, accuracy: 1e-10)
    }
    
    // MARK: - Linear Regression
    
    func testLinearRegressionPerfect() {
        // y = 2x + 1
        let x = [1.0, 2.0, 3.0, 4.0, 5.0]
        let y = [3.0, 5.0, 7.0, 9.0, 11.0]
        let result = engine.linearRegression(x: x, y: y).value
        
        XCTAssertEqual(result.slope, 2.0, accuracy: 1e-10)
        XCTAssertEqual(result.intercept, 1.0, accuracy: 1e-10)
        XCTAssertEqual(result.rSquared, 1.0, accuracy: 1e-10)
    }
    
    // MARK: - Moving Average
    
    func testMovingAverage() {
        let data = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = engine.movingAverage(data, windowSize: 3).value
        
        // [mean(1,2,3), mean(2,3,4), mean(3,4,5)] = [2, 3, 4]
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], 2.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 3.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 4.0, accuracy: 1e-10)
    }
    
    // MARK: - Min / Max
    
    func testMin() {
        let result = engine.min([5, 2, 8, 1, 9]).value
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }
    
    func testMax() {
        let result = engine.max([5, 2, 8, 1, 9]).value
        XCTAssertEqual(result, 9.0, accuracy: 1e-10)
    }
    
    // MARK: - Performance
    
    func testStats10kPerformance() {
        let data = (0..<10000).map { _ in Double.random(in: -100...100) }
        
        let meanResult = engine.mean(data)
        XCTAssertLessThan(meanResult.metrics.executionTimeMs, 50.0, "Mean on 10k should be < 50ms")
        
        let stdResult = engine.standardDeviation(data)
        XCTAssertLessThan(stdResult.metrics.executionTimeMs, 50.0, "StdDev on 10k should be < 50ms")
        
        let medianResult = engine.median(data)
        XCTAssertLessThan(medianResult.metrics.executionTimeMs, 50.0, "Median on 10k should be < 50ms")
    }
}
