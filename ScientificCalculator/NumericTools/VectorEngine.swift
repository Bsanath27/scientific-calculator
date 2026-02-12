// NumericTools/VectorEngine.swift
// Scientific Calculator - Phase 3: Vector Operations Engine
// Uses Accelerate vDSP for high-performance vector math

import Foundation
import Accelerate

/// High-performance vector operations using vDSP
final class VectorEngine {
    
    // MARK: - Dot Product
    
    /// Compute dot product of two vectors
    func dot(_ a: [Double], _ b: [Double]) -> NumericToolResult<Double> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Dot Product", dataSize: a.count) {
            var result: Double = 0.0
            vDSP_dotprD(a, 1, b, 1, &result, vDSP_Length(a.count))
            return result
        }
    }
    
    // MARK: - Cross Product
    
    /// Compute cross product of two 3D vectors
    func cross(_ a: [Double], _ b: [Double]) -> NumericToolResult<[Double]> {
        precondition(a.count == 3 && b.count == 3, "Cross product requires 3D vectors")
        
        return NumericToolRunner.run(operationType: "Vector Cross Product", dataSize: 3) {
            return [
                a[1] * b[2] - a[2] * b[1],
                a[2] * b[0] - a[0] * b[2],
                a[0] * b[1] - a[1] * b[0]
            ]
        }
    }
    
    // MARK: - Norm
    
    /// Compute L2 (Euclidean) norm
    func norm(_ v: [Double]) -> NumericToolResult<Double> {
        return NumericToolRunner.run(operationType: "Vector Norm", dataSize: v.count) {
            var sumOfSquares: Double = 0.0
            vDSP_svesqD(v, 1, &sumOfSquares, vDSP_Length(v.count))
            return sqrt(sumOfSquares)
        }
    }
    
    // MARK: - Normalize
    
    /// Normalize vector to unit length
    func normalize(_ v: [Double]) -> NumericToolResult<[Double]> {
        return NumericToolRunner.run(operationType: "Vector Normalize", dataSize: v.count) {
            var sumOfSquares: Double = 0.0
            vDSP_svesqD(v, 1, &sumOfSquares, vDSP_Length(v.count))
            let length = sqrt(sumOfSquares)
            
            guard length > 0 else { return [Double](repeating: 0.0, count: v.count) }
            
            var result = [Double](repeating: 0.0, count: v.count)
            var divisor = length
            vDSP_vsdivD(v, 1, &divisor, &result, 1, vDSP_Length(v.count))
            return result
        }
    }
    
    // MARK: - Mean
    
    /// Compute mean of vector elements
    func mean(_ v: [Double]) -> NumericToolResult<Double> {
        return NumericToolRunner.run(operationType: "Vector Mean", dataSize: v.count) {
            var result: Double = 0.0
            vDSP_meanvD(v, 1, &result, vDSP_Length(v.count))
            return result
        }
    }
    
    // MARK: - Sum
    
    /// Compute sum of vector elements
    func sum(_ v: [Double]) -> NumericToolResult<Double> {
        return NumericToolRunner.run(operationType: "Vector Sum", dataSize: v.count) {
            var result: Double = 0.0
            vDSP_sveD(v, 1, &result, vDSP_Length(v.count))
            return result
        }
    }
    
    // MARK: - Element-wise Operations
    
    /// Element-wise addition
    func add(_ a: [Double], _ b: [Double]) -> NumericToolResult<[Double]> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Add", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_vaddD(a, 1, b, 1, &result, 1, vDSP_Length(a.count))
            return result
        }
    }
    
    /// Element-wise subtraction
    func subtract(_ a: [Double], _ b: [Double]) -> NumericToolResult<[Double]> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Subtract", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_vsubD(b, 1, a, 1, &result, 1, vDSP_Length(a.count))
            return result
        }
    }
    
    /// Element-wise multiplication
    func multiply(_ a: [Double], _ b: [Double]) -> NumericToolResult<[Double]> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Multiply", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_vmulD(a, 1, b, 1, &result, 1, vDSP_Length(a.count))
            return result
        }
    }
    
    /// Element-wise division
    func divide(_ a: [Double], _ b: [Double]) -> NumericToolResult<[Double]> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Divide", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_vdivD(b, 1, a, 1, &result, 1, vDSP_Length(a.count))
            return result
        }
    }
    
    // MARK: - Scalar Operations
    
    /// Scalar multiplication
    func scalarMultiply(_ v: [Double], scalar: Double) -> NumericToolResult<[Double]> {
        return NumericToolRunner.run(operationType: "Vector Scalar Multiply", dataSize: v.count) {
            var result = [Double](repeating: 0.0, count: v.count)
            var s = scalar
            vDSP_vsmulD(v, 1, &s, &result, 1, vDSP_Length(v.count))
            return result
        }
    }
    
    // MARK: - Magnitude / Distance
    
    /// Compute distance between two vectors
    func distance(_ a: [Double], _ b: [Double]) -> NumericToolResult<Double> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Vector Distance", dataSize: a.count) {
            var diff = [Double](repeating: 0.0, count: a.count)
            vDSP_vsubD(b, 1, a, 1, &diff, 1, vDSP_Length(a.count))
            
            var sumOfSquares: Double = 0.0
            vDSP_svesqD(diff, 1, &sumOfSquares, vDSP_Length(a.count))
            return sqrt(sumOfSquares)
        }
    }
}
