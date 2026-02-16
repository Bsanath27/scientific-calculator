// Symbolic/LatexFormatter.swift
// Scientific Calculator - LaTeX Formatting Utilities

import Foundation

/// Formats LaTeX strings for display
struct LatexFormatter {
    
    /// Convert LaTeX string to more readable Unicode representation
    /// - Parameter latex: LaTeX string from SymPy
    /// - Returns: Formatted string for display
    static func format(_ latex: String) -> String {
        var result = latex
        
        // Replacement mapping
        let replacements: [String: String] = [
            "\\pi": "π",
            "\\infty": "∞",
            "\\sqrt": "√",
            "\\pm": "±",
            "\\times": "×",
            "\\div": "÷",
            "\\cdot": "·",
            "\\alpha": "α",
            "\\beta": "β",
            "\\gamma": "γ",
            "\\delta": "δ",
            "\\theta": "θ",
            "\\lambda": "λ",
            "\\mu": "μ",
            "\\sigma": "σ",
            "\\phi": "φ",
            "\\omega": "ω",
            "\\Delta": "Δ",
            "\\Sigma": "Σ",
            "\\Omega": "Ω",
            "\\approx": "≈",
            "\\neq": "≠",
            "\\leq": "≤",
            "\\geq": "≥",
            "\\rightarrow": "→",
            "\\forall": "∀",
            "\\exists": "∃",
            "\\in": "∈"
        ]
        
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }
        
        // Handle superscripts (simple case: ^2, ^3)
        result = result.replacingOccurrences(of: "^2", with: "²")
        result = result.replacingOccurrences(of: "^3", with: "³")
        result = result.replacingOccurrences(of: "^{2}", with: "²")
        result = result.replacingOccurrences(of: "^{3}", with: "³")
        
        // Simple fraction handling
        result = simplifyFractions(result)
        
        // Remove remaining braces but keep structure
        result = result.replacingOccurrences(of: "{", with: "(")
        result = result.replacingOccurrences(of: "}", with: ")")
        
        // Clean up unnecessary parentheses
        result = result.replacingOccurrences(of: "( ", with: "(")
        result = result.replacingOccurrences(of: " )", with: ")")
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    /// Convert to plain text (removes LaTeX commands entirely)
    /// - Parameter latex: LaTeX string
    /// - Returns: Plain text representation
    static func toPlainText(_ latex: String) -> String {
        var result = latex
        
        // Remove LaTeX commands
        result = result.replacingOccurrences(of: #"\\[a-zA-Z]+"#, with: "", options: .regularExpression)
        
        // Remove braces
        result = result.replacingOccurrences(of: "{", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        
        // Clean up
        result = result.trimmingCharacters(in: .whitespaces)
        
        return result
    }
    
    // MARK: - Private Helpers
    
    /// Simplify simple fraction representations
    private static func simplifyFractions(_ latex: String) -> String {
        // Handle \\frac{a}{b} → a/b (simple cases only)
        var result = latex
        
        // Very basic implementation - just handle simple numerics
        let fracPattern = #"\\frac\{([^}]+)\}\{([^}]+)\}"#
        if let regex = try? NSRegularExpression(pattern: fracPattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "($1)/($2)"
            )
        }
        
        return result
    }
}

// MARK: - String Extensions

extension String {
    /// Check if string contains LaTeX markup
    var isLatex: Bool {
        return self.contains("\\")
    }
}
