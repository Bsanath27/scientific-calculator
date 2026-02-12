// NumericTools/MatrixEngine.swift
// Scientific Calculator - Phase 3: Matrix Operations Engine
// Uses Accelerate framework (BLAS/LAPACK) for high-performance linear algebra

import Foundation
import Accelerate

// MARK: - Matrix Type

/// Row-major dense matrix backed by contiguous Double array
struct Matrix: Equatable, CustomStringConvertible {
    let rows: Int
    let cols: Int
    var data: [Double]
    
    /// Create zero matrix
    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        self.data = [Double](repeating: 0.0, count: rows * cols)
    }
    
    /// Create matrix from flat array (row-major)
    init(rows: Int, cols: Int, data: [Double]) {
        precondition(data.count == rows * cols, "Data size mismatch: expected \(rows * cols), got \(data.count)")
        self.rows = rows
        self.cols = cols
        self.data = data
    }
    
    /// Create identity matrix
    static func identity(_ n: Int) -> Matrix {
        var m = Matrix(rows: n, cols: n)
        for i in 0..<n {
            m[i, i] = 1.0
        }
        return m
    }
    
    /// Create matrix from 2D array
    init(_ array: [[Double]]) {
        precondition(!array.isEmpty && !array[0].isEmpty, "Array must not be empty")
        let r = array.count
        let c = array[0].count
        precondition(array.allSatisfy { $0.count == c }, "All rows must have same length")
        self.rows = r
        self.cols = c
        self.data = array.flatMap { $0 }
    }
    
    /// Element access (row, col)
    subscript(row: Int, col: Int) -> Double {
        get {
            precondition(row >= 0 && row < rows && col >= 0 && col < cols, "Index out of bounds")
            return data[row * cols + col]
        }
        set {
            precondition(row >= 0 && row < rows && col >= 0 && col < cols, "Index out of bounds")
            data[row * cols + col] = newValue
        }
    }
    
    /// Total element count
    var count: Int { rows * cols }
    
    /// Whether this is a square matrix
    var isSquare: Bool { rows == cols }
    
    var description: String {
        var lines: [String] = []
        for r in 0..<rows {
            let rowValues = (0..<cols).map { String(format: "%.4f", self[r, $0]) }
            lines.append("[ \(rowValues.joined(separator: "  ")) ]")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Matrix Engine

/// High-performance matrix operations using Accelerate
final class MatrixEngine {
    
    // MARK: - Addition
    
    /// Element-wise addition: C = A + B
    func add(_ a: Matrix, _ b: Matrix) -> NumericToolResult<Matrix> {
        precondition(a.rows == b.rows && a.cols == b.cols, "Matrix dimensions must match for addition")
        
        return NumericToolRunner.run(operationType: "Matrix Add", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_vaddD(a.data, 1, b.data, 1, &result, 1, vDSP_Length(a.count))
            return Matrix(rows: a.rows, cols: a.cols, data: result)
        }
    }
    
    // MARK: - Subtraction
    
    /// Element-wise subtraction: C = A - B
    func subtract(_ a: Matrix, _ b: Matrix) -> NumericToolResult<Matrix> {
        precondition(a.rows == b.rows && a.cols == b.cols, "Matrix dimensions must match for subtraction")
        
        return NumericToolRunner.run(operationType: "Matrix Subtract", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            // vDSP_vsubD computes B - A, so swap arguments
            vDSP_vsubD(b.data, 1, a.data, 1, &result, 1, vDSP_Length(a.count))
            return Matrix(rows: a.rows, cols: a.cols, data: result)
        }
    }
    
    // MARK: - Multiplication
    
    /// Matrix multiplication: C = A × B using BLAS dgemm
    func multiply(_ a: Matrix, _ b: Matrix) -> NumericToolResult<Matrix> {
        precondition(a.cols == b.rows, "Inner dimensions must match: A(\(a.rows)x\(a.cols)) × B(\(b.rows)x\(b.cols))")
        
        return NumericToolRunner.run(operationType: "Matrix Multiply", dataSize: a.rows * b.cols) {
            var result = [Double](repeating: 0.0, count: a.rows * b.cols)
            
            vDSP_mmulD(
                a.data, 1,
                b.data, 1,
                &result, 1,
                vDSP_Length(a.rows),
                vDSP_Length(b.cols),
                vDSP_Length(a.cols)
            )
            
            return Matrix(rows: a.rows, cols: b.cols, data: result)
        }
    }
    
    // MARK: - Transpose
    
    /// Matrix transpose: B = A^T
    func transpose(_ a: Matrix) -> NumericToolResult<Matrix> {
        return NumericToolRunner.run(operationType: "Matrix Transpose", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            vDSP_mtransD(a.data, 1, &result, 1, vDSP_Length(a.cols), vDSP_Length(a.rows))
            return Matrix(rows: a.cols, cols: a.rows, data: result)
        }
    }
    
    // MARK: - Determinant
    
    /// Compute determinant using LU factorization (LAPACK dgetrf)
    func determinant(_ a: Matrix) -> NumericToolResult<Double> {
        precondition(a.isSquare, "Determinant requires square matrix")
        let n = a.rows
        
        return NumericToolRunner.run(operationType: "Matrix Determinant", dataSize: n * n) {
            let matrix = a.data  // Copy for in-place factorization
            var pivots = [Int32](repeating: 0, count: n)
            let N = Int32(n)
            let LDA = Int32(n) // Leading dimension is N since it's dense
            var info: Int32 = 0
            
            // Column-major conversion for LAPACK (transpose = row↔col swap)
            var colMajor = [Double](repeating: 0.0, count: n * n)
            vDSP_mtransD(matrix, 1, &colMajor, 1, vDSP_Length(n), vDSP_Length(n))
            
            // LU factorization
            // Fix exclusivity: use separate variables if needed, but here simple &N matches signature
            // dgetrf_ expects: M, N, A, LDA, IPIV, INFO
            // We pass distinct variables.
            var M_arg = N
            var N_arg = N
            var LDA_arg = LDA
            
            dgetrf_(&M_arg, &N_arg, &colMajor, &LDA_arg, &pivots, &info)
            
            guard info == 0 else { return Double.nan }
            
            // Determinant = product of diagonal elements × sign from pivots
            var det = 1.0
            var sign = 1
            for i in 0..<n {
                det *= colMajor[i * n + i]
                if pivots[i] != Int32(i + 1) {
                    sign *= -1
                }
            }
            
            return det * Double(sign)
        }
    }
    
    // MARK: - Inverse
    
    /// Compute matrix inverse using LAPACK (dgetrf + dgetri)
    func inverse(_ a: Matrix) -> NumericToolResult<Matrix?> {
        precondition(a.isSquare, "Inverse requires square matrix")
        let n = a.rows
        
        return NumericToolRunner.run(operationType: "Matrix Inverse", dataSize: n * n) {
            let N = Int32(n)
            var pivots = [Int32](repeating: 0, count: n)
            var info: Int32 = 0
            
            // Convert to column-major for LAPACK (transpose)
            var colMajor = [Double](repeating: 0.0, count: n * n)
            vDSP_mtransD(a.data, 1, &colMajor, 1, vDSP_Length(n), vDSP_Length(n))
            
            // Local vars for exclusivity
            var M_arg = N
            var N_arg = N
            var LDA_arg = N
            
            // LU factorization
            dgetrf_(&M_arg, &N_arg, &colMajor, &LDA_arg, &pivots, &info)
            guard info == 0 else { return nil }  // Singular matrix
            
            // Compute inverse
            var workSize = Int32(n * n)
            var work = [Double](repeating: 0.0, count: Int(workSize))
            
            // Refresh args for dgetri
            var N_ri = N
            var LDA_ri = N
            
            dgetri_(&N_ri, &colMajor, &LDA_ri, &pivots, &work, &workSize, &info)
            guard info == 0 else { return nil }
            
            // Convert back to row-major (transpose)
            var rowMajor = [Double](repeating: 0.0, count: n * n)
            vDSP_mtransD(colMajor, 1, &rowMajor, 1, vDSP_Length(n), vDSP_Length(n))
            
            return Matrix(rows: n, cols: n, data: rowMajor)
        }
    }
    
    // MARK: - Eigenvalues
    
    /// Compute eigenvalues using LAPACK dgeev
    func eigenvalues(_ a: Matrix) -> NumericToolResult<(real: [Double], imaginary: [Double])> {
        precondition(a.isSquare, "Eigenvalues require square matrix")
        let n = a.rows
        
        return NumericToolRunner.run(operationType: "Matrix Eigenvalues", dataSize: n * n) {
            let N = Int32(n)
            var info: Int32 = 0
            
            // Convert to column-major (transpose)
            var colMajor = [Double](repeating: 0.0, count: n * n)
            vDSP_mtransD(a.data, 1, &colMajor, 1, vDSP_Length(n), vDSP_Length(n))
            
            var realEigenvalues = [Double](repeating: 0.0, count: n)
            var imagEigenvalues = [Double](repeating: 0.0, count: n)
            
            var jobvl: Int8 = Int8(UnicodeScalar("N").value)
            var jobvr: Int8 = Int8(UnicodeScalar("N").value)
            var ldvl = Int32(1)
            var ldvr = Int32(1)
            var vl = [Double](repeating: 0.0, count: 1)
            var vr = [Double](repeating: 0.0, count: 1)
            
            // Workspace query
            var workSize: Int32 = -1
            var workQuery = [Double](repeating: 0.0, count: 1)
            
            // Exclusivity copies
            var N_query = N
            var LDA_query = N
            
            dgeev_(&jobvl, &jobvr, &N_query, &colMajor, &LDA_query,
                   &realEigenvalues, &imagEigenvalues,
                   &vl, &ldvl, &vr, &ldvr,
                   &workQuery, &workSize, &info)
            
            workSize = Int32(workQuery[0])
            var work = [Double](repeating: 0.0, count: Int(workSize))
            
            // Compute eigenvalues
            var N_calc = N
            var LDA_calc = N
            
            dgeev_(&jobvl, &jobvr, &N_calc, &colMajor, &LDA_calc,
                   &realEigenvalues, &imagEigenvalues,
                   &vl, &ldvl, &vr, &ldvr,
                   &work, &workSize, &info)
            
            if info != 0 {
                return (real: [], imaginary: [])
            }
            
            return (real: realEigenvalues, imaginary: imagEigenvalues)
        }
    }
    
    // MARK: - Scalar Operations
    
    /// Scalar multiplication
    func scalarMultiply(_ a: Matrix, scalar: Double) -> NumericToolResult<Matrix> {
        return NumericToolRunner.run(operationType: "Matrix Scalar Multiply", dataSize: a.count) {
            var result = [Double](repeating: 0.0, count: a.count)
            var s = scalar
            vDSP_vsmulD(a.data, 1, &s, &result, 1, vDSP_Length(a.count))
            return Matrix(rows: a.rows, cols: a.cols, data: result)
        }
    }
    
    // MARK: - Dot Product (for vectors stored as matrices)
    
    /// Dot product of two vectors (1D matrices or flat arrays)
    func dotProduct(_ a: [Double], _ b: [Double]) -> NumericToolResult<Double> {
        precondition(a.count == b.count, "Vectors must have same length")
        
        return NumericToolRunner.run(operationType: "Dot Product", dataSize: a.count) {
            var result = 0.0
            vDSP_dotprD(a, 1, b, 1, &result, vDSP_Length(a.count))
            return result
        }
    }
}
