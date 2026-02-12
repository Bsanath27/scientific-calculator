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
        
        // Replace common LaTeX symbols with Unicode
        result = result.replacingOccurrences(of: "\\pi", with: "π")
        result = result.replacingOccurrences(of: "\\infty", with: "∞")
        result = result.replacingOccurrences(of: "\\sqrt", with: "√")
        result = result.replacingOccurrences(of: "\\pm", with: "±")
        result = result.replacingOccurrences(of: "\\times", with: "×")
        result = result.replacingOccurrences(of: "\\div", with: "÷")
        
        // Simple fraction handling (for basic cases)
        result = simplifyFractions(result)
        
        // Remove unnecessary braces
        result = result.replacingOccurrences(of: "{", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        
        // Clean up whitespace
        result = result.trimmingCharacters(in: .whitespaces)
        
        return result
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
