// Benchmarks/BenchmarkRunner.swift
// Scientific Calculator - Performance Benchmark Tool

import Foundation

/// Benchmark results for an expression
struct BenchmarkResults {
    let expression: String
    let iterations: Int
    let avgTimeMs: Double
    let p95TimeMs: Double
    let maxTimeMs: Double
    let minTimeMs: Double
    let memoryUsageKB: Double
    let successRate: Double
}

/// Benchmark runner for performance testing
final class BenchmarkRunner {
    private let dispatcher = Dispatcher()
    
    /// Default number of iterations
    static let defaultIterations = 1000
    
    /// Run benchmark on expression
    func run(expression: String, iterations: Int = defaultIterations) -> BenchmarkResults {
        print("\n🔄 Running benchmark: \(iterations) iterations")
        print("Expression: \(expression)")
        print("─────────────────────────────────────────")
        
        var times: [Double] = []
        var successes = 0
        let startMemory = MetricsCollector.currentMemoryKB()
        
        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            let report = dispatcher.evaluate(expression: expression)
            let end = CFAbsoluteTimeGetCurrent()
            
            let timeMs = (end - start) * 1000
            times.append(timeMs)
            
            if report.isSuccess { successes += 1 }
            
            // Progress indicator for long runs
            if (i + 1) % 250 == 0 {
                print("  Progress: \(i + 1)/\(iterations)")
            }
        }
        
        let endMemory = MetricsCollector.currentMemoryKB()
        
        // Calculate statistics
        let sorted = times.sorted()
        let avg = times.reduce(0, +) / Double(times.count)
        let p95Index = Int(Double(times.count) * 0.95)
        let p95 = sorted[min(p95Index, sorted.count - 1)]
        let maxTime = sorted.last ?? 0
        let minTime = sorted.first ?? 0
        let memoryDelta = max(0, endMemory - startMemory)
        let successRate = Double(successes) / Double(iterations)
        
        let results = BenchmarkResults(
            expression: expression,
            iterations: iterations,
            avgTimeMs: avg,
            p95TimeMs: p95,
            maxTimeMs: maxTime,
            minTimeMs: minTime,
            memoryUsageKB: memoryDelta,
            successRate: successRate
        )
        
        printResults(results)
        
        return results
    }
    
    /// Run benchmark on multiple expressions
    func runSuite(expressions: [String], iterations: Int = 100) -> [BenchmarkResults] {
        print("\n═══════════════════════════════════════")
        print("    BENCHMARK SUITE (\(expressions.count) expressions)")
        print("═══════════════════════════════════════\n")
        
        return expressions.map { run(expression: $0, iterations: iterations) }
    }
    
    private func printResults(_ results: BenchmarkResults) {
        print("\n╔═══════════════════════════════════════╗")
        print("║         BENCHMARK RESULTS             ║")
        print("╠═══════════════════════════════════════╣")
        print("║ Iterations: \(String(format: "%6d", results.iterations))                   ║")
        print("╠═══════════════════════════════════════╣")
        print("║ Avg Time:   \(String(format: "%10.4f", results.avgTimeMs)) ms           ║")
        print("║ P95 Time:   \(String(format: "%10.4f", results.p95TimeMs)) ms           ║")
        print("║ Max Time:   \(String(format: "%10.4f", results.maxTimeMs)) ms           ║")
        print("║ Min Time:   \(String(format: "%10.4f", results.minTimeMs)) ms           ║")
        print("╠═══════════════════════════════════════╣")
        print("║ Memory:     \(String(format: "%10.2f", results.memoryUsageKB)) KB           ║")
        print("║ Success:    \(String(format: "%10.1f", results.successRate * 100))%            ║")
        print("╚═══════════════════════════════════════╝\n")
    }
}

// MARK: - Quick Benchmark API
extension BenchmarkRunner {
    /// Quick benchmark with default settings
    static func quick(_ expression: String) -> BenchmarkResults {
        BenchmarkRunner().run(expression: expression, iterations: 100)
    }
    
    /// Full benchmark
    static func full(_ expression: String) -> BenchmarkResults {
        BenchmarkRunner().run(expression: expression, iterations: 1000)
    }
}
