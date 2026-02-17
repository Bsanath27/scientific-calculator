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
    
    /// Type of operation: "numeric", "symbolic", or "fallback"
    let operationType: String
    
    // MARK: - Symbolic-specific metrics (Phase 2)
    
    /// Time spent calling Python service (milliseconds) - nil for numeric
    let pythonCallTimeMs: Double?
    
    /// Time spent converting AST to SymPy (milliseconds) - nil for numeric
    let conversionTimeMs: Double?
    
    // MARK: - OCR-specific metrics (Phase 4)
    
    /// Time spent on OCR recognition (milliseconds) - nil for non-OCR
    let ocrTimeMs: Double?
    
    /// OCR recognition confidence score (0.0-1.0) - nil for non-OCR
    let ocrConfidence: Double?
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
        operationType: "numeric",
        pythonCallTimeMs: nil,
        conversionTimeMs: nil,
        ocrTimeMs: nil,
        ocrConfidence: nil
    )
}
