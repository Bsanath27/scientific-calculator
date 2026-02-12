// VectorEngineTests.swift
// Scientific Calculator - Phase 3: Vector Engine Tests

import XCTest
@testable import ScientificCalculator

final class VectorEngineTests: XCTestCase {
    private let engine = VectorEngine()
    
    // MARK: - Dot Product
    
    func testDotProduct() {
        let result = engine.dot([1, 2, 3], [4, 5, 6]).value
        // 1*4 + 2*5 + 3*6 = 32
        XCTAssertEqual(result, 32.0, accuracy: 1e-10)
    }
    
    func testDotProductOrthogonal() {
        let result = engine.dot([1, 0, 0], [0, 1, 0]).value
        XCTAssertEqual(result, 0.0, accuracy: 1e-10)
    }
    
    // MARK: - Cross Product
    
    func testCrossProduct() {
        let result = engine.cross([1, 0, 0], [0, 1, 0]).value
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 1.0, accuracy: 1e-10)
    }
    
    func testCrossProductAnticommutative() {
        let a = [1.0, 2.0, 3.0]
        let b = [4.0, 5.0, 6.0]
        let ab = engine.cross(a, b).value
        let ba = engine.cross(b, a).value
        
        for i in 0..<3 {
            XCTAssertEqual(ab[i], -ba[i], accuracy: 1e-10)
        }
    }
    
    // MARK: - Norm
    
    func testNorm() {
        let result = engine.norm([3, 4]).value
        XCTAssertEqual(result, 5.0, accuracy: 1e-10)
    }
    
    func testNorm3D() {
        let result = engine.norm([1, 2, 2]).value
        XCTAssertEqual(result, 3.0, accuracy: 1e-10)
    }
    
    // MARK: - Normalize
    
    func testNormalize() {
        let result = engine.normalize([3, 4]).value
        XCTAssertEqual(result[0], 0.6, accuracy: 1e-10)
        XCTAssertEqual(result[1], 0.8, accuracy: 1e-10)
    }
    
    func testNormalizeZeroVector() {
        let result = engine.normalize([0, 0, 0]).value
        XCTAssertEqual(result, [0.0, 0.0, 0.0])
    }
    
    // MARK: - Mean / Sum
    
    func testMean() {
        let result = engine.mean([2, 4, 6, 8, 10]).value
        XCTAssertEqual(result, 6.0, accuracy: 1e-10)
    }
    
    func testSum() {
        let result = engine.sum([1, 2, 3, 4, 5]).value
        XCTAssertEqual(result, 15.0, accuracy: 1e-10)
    }
    
    // MARK: - Element-wise Operations
    
    func testElementwiseAdd() {
        let result = engine.add([1, 2, 3], [4, 5, 6]).value
        XCTAssertEqual(result[0], 5.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 7.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 9.0, accuracy: 1e-10)
    }
    
    func testElementwiseMultiply() {
        let result = engine.multiply([2, 3, 4], [5, 6, 7]).value
        XCTAssertEqual(result[0], 10.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 18.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 28.0, accuracy: 1e-10)
    }
    
    // MARK: - Distance
    
    func testDistance() {
        let result = engine.distance([0, 0], [3, 4]).value
        XCTAssertEqual(result, 5.0, accuracy: 1e-10)
    }
    
    // MARK: - Scalar Multiply
    
    func testScalarMultiply() {
        let result = engine.scalarMultiply([1, 2, 3], scalar: 3.0).value
        XCTAssertEqual(result[0], 3.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 6.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 9.0, accuracy: 1e-10)
    }
}
