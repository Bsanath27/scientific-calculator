// Metrics/MetricsCollector.swift
// Scientific Calculator - Metrics Collection Utilities

import Foundation

/// Utility for collecting performance metrics
enum MetricsCollector {
    /// Get current memory usage in kilobytes
    static func currentMemoryKB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0
        }
        return 0
    }
    
    /// Measure execution time of a block
    static func measureTime<T>(_ block: () throws -> T) rethrows -> (result: T, timeMs: Double) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let end = CFAbsoluteTimeGetCurrent()
        return (result, (end - start) * 1000)
    }
    
    /// Measure execution time (async version placeholder)
    static func measureTimeMs(_ block: () -> Void) -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        return (end - start) * 1000
    }
}
