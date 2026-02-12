// OCREngine/OCRMetrics.swift
// Scientific Calculator - Phase 4: OCR Pipeline Metrics
// Tracks timing and quality metrics for the OCR recognition pipeline.

import Foundation

/// Metrics for the OCR recognition pipeline
struct OCRMetrics {
    /// Time spent on OCR recognition (milliseconds)
    let ocrTimeMs: Double
    
    /// Image size in bytes
    let imageSize: Int
    
    /// OCR confidence score (0.0 to 1.0)
    let confidenceScore: Double
    
    /// Time spent normalizing LaTeX (milliseconds)
    let normalizeTimeMs: Double
    
    /// Time spent parsing the expression (milliseconds)
    let parseTimeMs: Double
    
    /// Time spent evaluating (milliseconds)
    let evalTimeMs: Double
    
    /// Total pipeline time from image to result (milliseconds)
    let totalTimeMs: Double
    
    /// Console-friendly description
    var consoleDescription: String {
        """
        OCR Pipeline Metrics
        ────────────────────
        OCR time:       \(String(format: "%.1f", ocrTimeMs)) ms
        Normalize time: \(String(format: "%.3f", normalizeTimeMs)) ms
        Parse time:     \(String(format: "%.3f", parseTimeMs)) ms
        Eval time:      \(String(format: "%.3f", evalTimeMs)) ms
        Total time:     \(String(format: "%.1f", totalTimeMs)) ms
        ────────────────────
        Image size:     \(imageSize) bytes
        Confidence:     \(String(format: "%.0f", confidenceScore * 100))%
        """
    }
    
    /// Display-friendly string for UI
    var displayString: String {
        var lines: [String] = []
        lines.append(String(format: "OCR: %.1fms | Confidence: %.0f%%", ocrTimeMs, confidenceScore * 100))
        lines.append(String(format: "Parse: %.3fms | Eval: %.3fms", parseTimeMs, evalTimeMs))
        lines.append(String(format: "Total: %.1fms | Image: %d bytes", totalTimeMs, imageSize))
        return lines.joined(separator: "\n")
    }
}
