// NumericTools/NumericToolMetrics.swift
// Scientific Calculator - Phase 3: Shared Metrics for Numeric Tools

import Foundation

/// Performance metrics for numeric tool operations
struct NumericToolMetrics {
    /// Execution time in milliseconds
    let executionTimeMs: Double
    
    /// Memory usage in kilobytes
    let memoryUsageKB: Double
    
    /// Size of data processed (e.g., matrix dimensions, array length)
    let dataSize: Int
    
    /// Type of operation performed
    let operationType: String
    
    /// Formatted console output
    var consoleDescription: String {
        """
        ═══════════════════════════════════════
        Tool Operation: \(operationType)
        ───────────────────────────────────────
        Exec time:  \(String(format: "%.3f", executionTimeMs)) ms
        Memory:     \(String(format: "%.2f", memoryUsageKB)) KB
        Data size:  \(dataSize)
        ═══════════════════════════════════════
        """
    }
}

/// Generic result wrapper with metrics
struct NumericToolResult<T> {
    let value: T
    let metrics: NumericToolMetrics
}

/// Helper to measure a numeric tool operation
enum NumericToolRunner {
    /// Execute a tool operation with full metrics collection
    static func run<T>(
        operationType: String,
        dataSize: Int,
        operation: () throws -> T
    ) rethrows -> NumericToolResult<T> {
        let startMemory = MetricsCollector.currentMemoryKB()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try operation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = MetricsCollector.currentMemoryKB()
        
        let metrics = NumericToolMetrics(
            executionTimeMs: (endTime - startTime) * 1000,
            memoryUsageKB: max(0, endMemory - startMemory),
            dataSize: dataSize,
            operationType: operationType
        )
        
        #if DEBUG
        print(metrics.consoleDescription)
        #endif
        
        return NumericToolResult(value: result, metrics: metrics)
    }
}
