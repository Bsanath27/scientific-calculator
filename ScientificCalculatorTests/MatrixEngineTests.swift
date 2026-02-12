// MatrixEngineTests.swift
// Scientific Calculator - Phase 3: Matrix Engine Tests

import XCTest
@testable import ScientificCalculator

final class MatrixEngineTests: XCTestCase {
    private let engine = MatrixEngine()
    
    // MARK: - Addition
    
    func testAddition() {
        let a = Matrix([[1, 2], [3, 4]])
        let b = Matrix([[5, 6], [7, 8]])
        let result = engine.add(a, b).value
        
        XCTAssertEqual(result[0, 0], 6.0, accuracy: 1e-10)
        XCTAssertEqual(result[0, 1], 8.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 0], 10.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 1], 12.0, accuracy: 1e-10)
    }
    
    // MARK: - Subtraction
    
    func testSubtraction() {
        let a = Matrix([[5, 6], [7, 8]])
        let b = Matrix([[1, 2], [3, 4]])
        let result = engine.subtract(a, b).value
        
        XCTAssertEqual(result[0, 0], 4.0, accuracy: 1e-10)
        XCTAssertEqual(result[0, 1], 4.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 0], 4.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 1], 4.0, accuracy: 1e-10)
    }
    
    // MARK: - Multiplication
    
    func testMultiplication() {
        let a = Matrix([[1, 2], [3, 4]])
        let b = Matrix([[5, 6], [7, 8]])
        let result = engine.multiply(a, b).value
        
        // [1*5+2*7, 1*6+2*8] = [19, 22]
        // [3*5+4*7, 3*6+4*8] = [43, 50]
        XCTAssertEqual(result[0, 0], 19.0, accuracy: 1e-10)
        XCTAssertEqual(result[0, 1], 22.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 0], 43.0, accuracy: 1e-10)
        XCTAssertEqual(result[1, 1], 50.0, accuracy: 1e-10)
    }
    
    func testMultiplicationNonSquare() {
        let a = Matrix([[1, 2, 3], [4, 5, 6]])  // 2x3
        let b = Matrix([[7, 8], [9, 10], [11, 12]])  // 3x2
        let result = engine.multiply(a, b).value
        
        XCTAssertEqual(result.rows, 2)
        XCTAssertEqual(result.cols, 2)
        XCTAssertEqual(result[0, 0], 58.0, accuracy: 1e-10)  // 1*7+2*9+3*11
        XCTAssertEqual(result[0, 1], 64.0, accuracy: 1e-10)  // 1*8+2*10+3*12
    }
    
    // MARK: - Transpose
    
    func testTranspose() {
        let a = Matrix([[1, 2, 3], [4, 5, 6]])  // 2x3
        let result = engine.transpose(a).value
        
        XCTAssertEqual(result.rows, 3)
        XCTAssertEqual(result.cols, 2)
        XCTAssertEqual(result[0, 0], 1.0)
        XCTAssertEqual(result[0, 1], 4.0)
        XCTAssertEqual(result[1, 0], 2.0)
        XCTAssertEqual(result[2, 1], 6.0)
    }
    
    // MARK: - Determinant
    
    func testDeterminant2x2() {
        let a = Matrix([[1, 2], [3, 4]])
        let det = engine.determinant(a).value
        // det = 1*4 - 2*3 = -2
        XCTAssertEqual(det, -2.0, accuracy: 1e-10)
    }
    
    func testDeterminant3x3() {
        let a = Matrix([[6, 1, 1], [4, -2, 5], [2, 8, 7]])
        let det = engine.determinant(a).value
        // det = -306
        XCTAssertEqual(det, -306.0, accuracy: 1e-8)
    }
    
    func testDeterminantIdentity() {
        let a = Matrix.identity(4)
        let det = engine.determinant(a).value
        XCTAssertEqual(det, 1.0, accuracy: 1e-10)
    }
    
    // MARK: - Inverse
    
    func testInverse2x2() {
        let a = Matrix([[4, 7], [2, 6]])
        guard let inv = engine.inverse(a).value else {
            XCTFail("Inverse should exist")
            return
        }
        
        // A * A^-1 should be identity
        let product = engine.multiply(a, inv).value
        XCTAssertEqual(product[0, 0], 1.0, accuracy: 1e-10)
        XCTAssertEqual(product[0, 1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(product[1, 0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(product[1, 1], 1.0, accuracy: 1e-10)
    }
    
    func testInverseSingular() {
        let a = Matrix([[1, 2], [2, 4]])  // Singular
        let inv = engine.inverse(a).value
        XCTAssertNil(inv)
    }
    
    // MARK: - Eigenvalues
    
    func testEigenvalues2x2() {
        let a = Matrix([[2, 1], [1, 2]])
        let eigen = engine.eigenvalues(a).value
        
        XCTAssertEqual(eigen.real.count, 2)
        let sorted = eigen.real.sorted()
        XCTAssertEqual(sorted[0], 1.0, accuracy: 1e-10)
        XCTAssertEqual(sorted[1], 3.0, accuracy: 1e-10)
    }
    
    // MARK: - Identity
    
    func testIdentity() {
        let id = Matrix.identity(3)
        XCTAssertEqual(id[0, 0], 1.0)
        XCTAssertEqual(id[1, 1], 1.0)
        XCTAssertEqual(id[2, 2], 1.0)
        XCTAssertEqual(id[0, 1], 0.0)
    }
    
    // MARK: - Performance
    
    func testMultiply100x100Performance() {
        let n = 100
        let data = (0..<n*n).map { _ in Double.random(in: -10...10) }
        let a = Matrix(rows: n, cols: n, data: data)
        let b = Matrix(rows: n, cols: n, data: data)
        
        let result = engine.multiply(a, b)
        XCTAssertLessThan(result.metrics.executionTimeMs, 5.0, "100x100 multiply should be < 5ms")
    }
}
