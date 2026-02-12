// Formatting/ResultFormatter.swift
// Scientific Calculator - Result Formatting

import Foundation

/// Formatter for numeric and symbolic results with metrics
enum ResultFormatter {
    /// Format evaluation result for display
    static func formatResult(_ result: EvaluationResult) -> String {
        switch result {
        case .number(let value):
            return format(value)
        case .symbolic(let result, let latex, _):
            return "\(result)\n\(latex)"
        case .error(let msg):
            return "Error: \(msg)"
        case .notImplemented(let msg):
            return "Not Implemented: \(msg)"
        }
    }
    
    /// Format a Double result for display
    static func format(_ value: Double) -> String {
        // Handle special values
        if value.isNaN { return "NaN" }
        if value.isInfinite { return value > 0 ? "∞" : "-∞" }
        
        // Use scientific notation for very large or very small values
        let absValue = abs(value)
        if absValue != 0 && (absValue >= 1e10 || absValue < 1e-6) {
            return formatScientific(value)
        }
        
        // Standard formatting with limited decimal places
        return formatStandard(value)
    }
    
    /// Format with scientific notation
    private static func formatScientific(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.maximumSignificantDigits = 10
        formatter.minimumSignificantDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    /// Format with standard decimal notation
    private static func formatStandard(_ value: Double) -> String {
        // Check if it's effectively an integer
        if value.truncatingRemainder(dividingBy: 1) == 0 && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    /// Format metrics for display
    static func formatMetrics(_ metrics: EvaluationMetrics) -> String {
        var text = """
        Parse: \(String(format: "%.3f", metrics.parseTimeMs)) ms
        Eval:  \(String(format: "%.3f", metrics.evalTimeMs)) ms
        Total: \(String(format: "%.3f", metrics.totalTimeMs)) ms
        Memory: \(String(format: "%.2f", metrics.peakMemoryKB)) KB
        AST Nodes: \(metrics.astNodeCount)
        Expr Length: \(metrics.expressionLength)
        """
        
        // Add symbolic-specific metrics if available
        if let pythonTime = metrics.pythonCallTimeMs {
            text += "\nPython: \(String(format: "%.3f", pythonTime)) ms"
        }
        if let conversionTime = metrics.conversionTimeMs {
            text += "\nConversion: \(String(format: "%.3f", conversionTime)) ms"
        }
        
        return text
    }
}
