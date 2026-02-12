// Metrics/EvaluationReport.swift
// Scientific Calculator - Evaluation Report

import Foundation

/// Complete report of an evaluation including result and metrics
struct EvaluationReport {
    let result: EvaluationResult
    let metrics: EvaluationMetrics
    
    /// Formatted result string for display
    var resultString: String {
        switch result {
        case .number(let value):
            return ResultFormatter.format(value)
        case .symbolic(let result, let latex, _):
            return "\(result)\n\(latex)"
        case .error(let message):
            return "Error: \(message)"
        case .notImplemented(let message):
            return message
        }
    }
    
    /// Whether evaluation succeeded
    var isSuccess: Bool {
        result.isSuccess
    }
}
