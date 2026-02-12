// Benchmarks/NumericToolsBenchmark.swift
// Scientific Calculator - Phase 3: Performance Benchmarks

import Foundation

/// Benchmark suite for Phase 3 numeric tools
final class NumericToolsBenchmark {
    
    /// Run all benchmarks and report results
    static func runAll() {
        print("\n")
        print("╔═══════════════════════════════════════════════════╗")
        print("║      PHASE 3: NUMERIC TOOLS BENCHMARK SUITE      ║")
        print("╚═══════════════════════════════════════════════════╝\n")
        
        benchmarkMatrix()
        benchmarkVector()
        benchmarkStats()
        benchmarkGraph()
        
        print("═══════════════════════════════════════════════════")
        print("  BENCHMARK SUITE COMPLETE")
        print("═══════════════════════════════════════════════════\n")
    }
    
    // MARK: - Matrix Benchmarks
    
    static func benchmarkMatrix() {
        print("─── Matrix Engine ───────────────────────────────\n")
        let engine = MatrixEngine()
        
        // 100x100 multiply
        let n = 100
        let data = (0..<n*n).map { _ in Double.random(in: -10...10) }
        let a = Matrix(rows: n, cols: n, data: data)
        let b = Matrix(rows: n, cols: n, data: data.reversed())
        
        // Warmup
        _ = engine.multiply(a, b)
        
        // Benchmark: 100 iterations
        var times: [Double] = []
        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            _ = engine.multiply(a, b)
            let end = CFAbsoluteTimeGetCurrent()
            times.append((end - start) * 1000)
        }
        
        let avg = times.reduce(0, +) / Double(times.count)
        let maxT = times.max() ?? 0
        print("  100x100 Multiply (100 iters)")
        print("    Avg: \(String(format: "%.4f", avg)) ms")
        print("    Max: \(String(format: "%.4f", maxT)) ms")
        print("    Target: < 5.0 ms  [\(avg < 5.0 ? "PASS ✓" : "FAIL ✗")]")
        
        // Determinant
        let detResult = engine.determinant(a)
        print("  100x100 Determinant: \(String(format: "%.4f", detResult.metrics.executionTimeMs)) ms")
        
        // Inverse
        let invResult = engine.inverse(a)
        print("  100x100 Inverse: \(String(format: "%.4f", invResult.metrics.executionTimeMs)) ms")
        
        // Eigenvalues
        let eigResult = engine.eigenvalues(a)
        print("  100x100 Eigenvalues: \(String(format: "%.4f", eigResult.metrics.executionTimeMs)) ms")
        print()
    }
    
    // MARK: - Vector Benchmarks
    
    static func benchmarkVector() {
        print("─── Vector Engine ──────────────────────────────\n")
        let engine = VectorEngine()
        
        let large = (0..<10000).map { _ in Double.random(in: -100...100) }
        let large2 = (0..<10000).map { _ in Double.random(in: -100...100) }
        
        let dotResult = engine.dot(large, large2)
        print("  10k Dot Product: \(String(format: "%.4f", dotResult.metrics.executionTimeMs)) ms")
        
        let normResult = engine.norm(large)
        print("  10k Norm: \(String(format: "%.4f", normResult.metrics.executionTimeMs)) ms")
        
        let addResult = engine.add(large, large2)
        print("  10k Add: \(String(format: "%.4f", addResult.metrics.executionTimeMs)) ms")
        print()
    }
    
    // MARK: - Stats Benchmarks
    
    static func benchmarkStats() {
        print("─── Stats Engine ───────────────────────────────\n")
        let engine = StatsEngine()
        
        let data10k = (0..<10000).map { _ in Double.random(in: -100...100) }
        let data10k2 = (0..<10000).map { _ in Double.random(in: -100...100) }
        
        let meanResult = engine.mean(data10k)
        print("  10k Mean: \(String(format: "%.4f", meanResult.metrics.executionTimeMs)) ms")
        print("    Target: < 5.0 ms  [\(meanResult.metrics.executionTimeMs < 5.0 ? "PASS ✓" : "FAIL ✗")]")
        
        let medianResult = engine.median(data10k)
        print("  10k Median: \(String(format: "%.4f", medianResult.metrics.executionTimeMs)) ms")
        
        let stdResult = engine.standardDeviation(data10k)
        print("  10k StdDev: \(String(format: "%.4f", stdResult.metrics.executionTimeMs)) ms")
        
        let corrResult = engine.correlation(data10k, data10k2)
        print("  10k Correlation: \(String(format: "%.4f", corrResult.metrics.executionTimeMs)) ms")
        
        let regResult = engine.linearRegression(x: data10k, y: data10k2)
        print("  10k Linear Regression: \(String(format: "%.4f", regResult.metrics.executionTimeMs)) ms")
        
        let maResult = engine.movingAverage(data10k, windowSize: 50)
        print("  10k Moving Avg (w=50): \(String(format: "%.4f", maResult.metrics.executionTimeMs)) ms")
        print()
    }
    
    // MARK: - Graph Benchmarks
    
    static func benchmarkGraph() {
        print("─── Graph Engine ───────────────────────────────\n")
        let engine = GraphEngine()
        
        let result500 = engine.sample(expression: "sin(x)", xMin: -10, xMax: 10, pointCount: 500)
        print("  sin(x) 500 points: \(String(format: "%.2f", result500.metrics.executionTimeMs)) ms")
        print("    Target: < 50.0 ms  [\(result500.metrics.executionTimeMs < 50.0 ? "PASS ✓" : "FAIL ✗")]")
        
        let resultComplex = engine.sample(expression: "sin(x)*cos(x)+x^2", xMin: -5, xMax: 5, pointCount: 300)
        print("  sin(x)*cos(x)+x^2 300 pts: \(String(format: "%.2f", resultComplex.metrics.executionTimeMs)) ms")
        
        let multiResult = engine.sampleMultiple(
            expressions: ["sin(x)", "cos(x)", "x^2"],
            xMin: -5, xMax: 5, pointCount: 200
        )
        print("  3-function multi-plot 200 pts: \(String(format: "%.2f", multiResult.metrics.executionTimeMs)) ms")
        print()
    }
}
