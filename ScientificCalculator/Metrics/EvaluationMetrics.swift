// Metrics/EvaluationMetrics.swift
// Scientific Calculator - Performance Metrics

import Foundation

/// Performance metrics for a single evaluation
struct EvaluationMetrics: Equatable, Codable {
    /// Time spent parsing (milliseconds)
    let parseTimeMs: Double
    
    /// Time spent evaluating (milliseconds)
    let evalTimeMs: Double
    
    /// Total time from start to finish (milliseconds)
    let totalTimeMs: Double
    
    /// Peak memory usage during evaluation (kilobytes)
    let peakMemoryKB: Double
    
    /// Number of nodes in AST
    let astNodeCount: Int
    
    /// Length of input expression
    let expressionLength: Int
    
    // MARK: - Symbolic-specific metrics (Phase 2)
    
    /// Time spent calling Python service (milliseconds) - nil for numeric
    let pythonCallTimeMs: Double?
    
    /// Time spent converting AST to SymPy (milliseconds) - nil for numeric
    let conversionTimeMs: Double?
}

extension EvaluationMetrics {
    /// Empty metrics for error cases
    static let zero = EvaluationMetrics(
        parseTimeMs: 0,
        evalTimeMs: 0,
        totalTimeMs: 0,
        peakMemoryKB: 0,
        astNodeCount: 0,
        expressionLength: 0,
        pythonCallTimeMs: nil,
        conversionTimeMs: nil
    )
}
