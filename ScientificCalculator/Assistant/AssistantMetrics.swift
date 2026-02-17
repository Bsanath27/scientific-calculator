// Assistant/AssistantMetrics.swift
// Scientific Calculator - Phase 5: Assistant Performance Metrics

import Foundation

/// Performance metrics for the assistant translation + evaluation pipeline
struct AssistantMetrics {
    /// Time spent translating NL → expression (ms)
    let translationTimeMs: Double
    
    /// Translation confidence (0.0–1.0)
    /// Based on: didTranslate (0.3), pattern specificity (0.4), expression validity (0.3)
    let translationConfidence: Double
    
    /// Time spent parsing expression → AST (ms)
    let parseTimeMs: Double
    
    /// Time spent evaluating AST (ms)
    let evalTimeMs: Double
    
    /// Total end-to-end time (ms)
    var totalTimeMs: Double {
        translationTimeMs + parseTimeMs + evalTimeMs
    }
    
    /// Human-readable summary
    var summary: String {
        let conf = Int(translationConfidence * 100)
        return "Translation: \(String(format: "%.1f", translationTimeMs))ms (\(conf)% conf) | Eval: \(String(format: "%.1f", evalTimeMs))ms | Total: \(String(format: "%.1f", totalTimeMs))ms"
    }
    
    /// Compute translation confidence from NLTranslation result
    static func confidence(for translation: NLTranslation) -> Double {
        guard translation.didTranslate else { return 0.3 }  // passthrough: low confidence
        
        var score = 0.6  // base: successful translation
        
        // Bonus for having a specific operation
        if translation.operation != .evaluate {
            score += 0.2
        }
        
        // Bonus for having a variable detected
        if translation.variable != nil {
            score += 0.1
        }
        
        // Penalty for empty expression
        if translation.expression.isEmpty {
            score = 0.0
        }
        
        return min(score, 1.0)
    }
}
