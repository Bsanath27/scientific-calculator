// OCREngine/LatexNormalizer.swift
// Scientific Calculator - Phase 4: LaTeX to Calculator Syntax Normalizer
// Converts LaTeX output from OCR into expression text the Parser understands.
// Uses simple deterministic string replacements — no regex for complex parsing.

import Foundation

/// Converts LaTeX math notation to calculator-compatible expression syntax.
/// This is a pure text transform — no math evaluation.
struct LatexNormalizer {
    
    /// Normalize LaTeX string to calculator expression syntax
    /// - Parameter latex: Raw LaTeX from OCR
    /// - Returns: Calculator-compatible expression string
    static func normalize(_ latex: String) -> String {
        var result = latex
        
        // Step 1: Remove LaTeX display-mode wrappers
        result = removeDisplayWrappers(result)
        
        // Step 2: Convert LaTeX fractions → (a)/(b)
        result = convertFractions(result)
        
        // Step 3: Convert LaTeX sqrt → sqrt()
        result = convertSqrt(result)
        
        // Step 4: Convert LaTeX operators and symbols
        result = convertOperators(result)
        
        // Step 5: Convert LaTeX functions (trig, log)
        result = convertFunctions(result)
        
        // Step 6: Convert LaTeX constants
        result = convertConstants(result)
        
        // Step 7: Clean up remaining LaTeX artifacts
        result = cleanUp(result)
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Step 1: Remove Display Wrappers
    
    private static func removeDisplayWrappers(_ s: String) -> String {
        var result = s
        // Remove $...$, $$...$$, \[...\], \(...\)
        for wrapper in ["$$", "$", "\\[", "\\]", "\\(", "\\)"] {
            result = result.replacingOccurrences(of: wrapper, with: "")
        }
        // Remove \displaystyle, \textstyle, etc.
        for cmd in ["\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle"] {
            result = result.replacingOccurrences(of: cmd, with: "")
        }
        return result
    }
    
    // MARK: - Step 2: Convert Fractions
    
    /// Convert \frac{a}{b} → (a)/(b)
    /// Handles nested fractions by processing innermost first
    private static func convertFractions(_ s: String) -> String {
        var result = s
        // Process up to 10 nested levels (practical limit)
        for _ in 0..<10 {
            guard let fracRange = result.range(of: "\\frac") else { break }
            
            let afterFrac = result[fracRange.upperBound...]
            
            // Extract first brace group {numerator}
            guard let num = extractBraceGroup(String(afterFrac)) else { break }
            
            let afterNum = String(afterFrac.dropFirst(num.consumed))
            
            // Extract second brace group {denominator}
            guard let den = extractBraceGroup(afterNum) else { break }
            
            let totalConsumed = result.distance(from: result.startIndex, to: fracRange.lowerBound)
            let prefix = String(result.prefix(totalConsumed))
            let remaining = String(afterFrac.dropFirst(num.consumed + den.consumed))
            
            result = prefix + "(\(num.content))/(\(den.content))" + remaining
        }
        return result
    }
    
    // MARK: - Step 3: Convert Sqrt
    
    /// Convert \sqrt{x} → sqrt(x) and \sqrt[n]{x} → (x)^(1/(n))
    private static func convertSqrt(_ s: String) -> String {
        var result = s
        for _ in 0..<10 {
            guard let sqrtRange = result.range(of: "\\sqrt") else { break }
            
            let afterSqrt = String(result[sqrtRange.upperBound...])
            let prefix = String(result[..<sqrtRange.lowerBound])
            
            // Check for optional [n] (nth root)
            if afterSqrt.hasPrefix("[") {
                // \sqrt[n]{x} → (x)^(1/(n))
                guard let nthContent = extractBracketGroup(afterSqrt) else { break }
                let afterNth = String(afterSqrt.dropFirst(nthContent.consumed))
                guard let body = extractBraceGroup(afterNth) else { break }
                let remaining = String(afterSqrt.dropFirst(nthContent.consumed + body.consumed))
                result = prefix + "(\(body.content))^(1/(\(nthContent.content)))" + remaining
            } else {
                // \sqrt{x} → sqrt(x)
                guard let body = extractBraceGroup(afterSqrt) else { break }
                let remaining = String(afterSqrt.dropFirst(body.consumed))
                result = prefix + "sqrt(\(body.content))" + remaining
            }
        }
        return result
    }
    
    // MARK: - Step 4: Convert Operators
    
    private static func convertOperators(_ s: String) -> String {
        var result = s
        let replacements: [(String, String)] = [
            ("\\cdot", "*"),
            ("\\times", "*"),
            ("\\div", "/"),
            ("\\pm", "+"),       // Simplify ± to +
            ("\\mp", "-"),       // Simplify ∓ to -
            ("\\left(", "("),
            ("\\right)", ")"),
            ("\\left[", "("),
            ("\\right]", ")"),
            ("\\left|", "abs("),
            ("\\right|", ")"),
            ("\\{", "("),
            ("\\}", ")"),
            ("\\sum", "sum"),    // Handle standard LaTeX sum
            ("Sigma", "sum"),    // Handle legacy/ocr text Sigma
            ("\\simeq", "="),
            ("\\approx", "="),
            ("\\cong", "="),
        ]
        for (from, to) in replacements {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }
    
    // MARK: - Step 5: Convert Functions
    
    private static func convertFunctions(_ s: String) -> String {
        var result = s
        let functions = ["sin", "cos", "tan", "log", "ln", "exp"]
        for fn in functions {
            // \sin → sin, \cos → cos, etc.
            result = result.replacingOccurrences(of: "\\\(fn)", with: fn)
        }
        return result
    }
    
    // MARK: - Step 6: Convert Constants
    
    private static func convertConstants(_ s: String) -> String {
        var result = s
        result = result.replacingOccurrences(of: "\\pi", with: "pi")
        result = result.replacingOccurrences(of: "\\infty", with: "inf")
        return result
    }
    
    // MARK: - Step 7: Clean Up
    
    private static func cleanUp(_ s: String) -> String {
        var result = s
        
        // Step 0: Remove question numbering (e.g. "1)", "1.", "Q1:")
        result = removeQuestionNumbering(result)
        
        // Remove remaining backslash commands (e.g., \, \; \quad \text{})
        // Simple: remove \command where command is alphabetic
        var cleaned = ""
        var i = result.startIndex
        while i < result.endIndex {
            if result[i] == "\\" {
                let next = result.index(after: i)
                if next < result.endIndex && result[next].isLetter {
                    // Skip \command
                    var end = next
                    while end < result.endIndex && result[end].isLetter {
                        end = result.index(after: end)
                    }
                    // Also skip a following brace group if it was \text{...}
                    if end < result.endIndex && result[end] == "{" {
                        if let group = extractBraceGroup(String(result[end...])) {
                            let groupEndOffset = result.distance(from: end, to: result.endIndex)
                            if group.consumed <= groupEndOffset {
                                end = result.index(end, offsetBy: group.consumed)
                            }
                        }
                    }
                    i = end
                } else if next < result.endIndex {
                    // \, \; etc — just skip the backslash
                    i = next
                } else {
                    i = next
                }
            } else {
                cleaned.append(result[i])
                i = result.index(after: i)
            }
        }
        result = cleaned
        
        // Remove remaining braces that aren't part of expressions
        result = result.replacingOccurrences(of: "{", with: "(")
        result = result.replacingOccurrences(of: "}", with: ")")
        
        // Collapse multiple spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Remove leading/trailing whitespace from within parens
        result = result.replacingOccurrences(of: "( ", with: "(")
        result = result.replacingOccurrences(of: " )", with: ")")
        
        // Remove underscore before parens (e.g. sum_(s) -> sum(s))
        result = result.replacingOccurrences(of: "_(", with: "(")
        // Remove underscore before brace-converted-to-paren
        result = result.replacingOccurrences(of: "_", with: "")
        
        return result
    }
    
    // MARK: - Helper: Numbering Removal
    
    private static func removeQuestionNumbering(_ s: String) -> String {

        var result = s
        
        // Remove "1. " (dot requires space to avoid 1.2)
        result = result.replacingOccurrences(of: #"^\s*\d+\.\s+"#, with: "", options: .regularExpression)
        
        // Remove "1) ", "a) ", "(a) ", "(1) "
        // \d+|[a-zA-Z] matches "1", "12", "a", "B"
        // Followed by ) and MANDATORY space
        result = result.replacingOccurrences(of: #"^\s*(\d+|[a-zA-Z])\)\s+"#, with: "", options: .regularExpression)
        
        // Remove "(a) " or "(1) "
        // \([a-zA-Z0-9]+\) matches "(a)", "(12)"
        // Followed by MANDATORY space
        result = result.replacingOccurrences(of: #"^\s*\([a-zA-Z0-9]+\)\s+"#, with: "", options: .regularExpression)

        // Remove "Q1: ", "Problem 1: "
        result = result.replacingOccurrences(of: #"^\s*(?:Question|Problem|Q)\s*\d+:?\s+"#, with: "", options: .regularExpression)
        
        return result
    }
    
    // MARK: - Brace/Bracket Group Extraction
    
    /// Extract content from {content} — returns content and total characters consumed (including braces)
    private static func extractBraceGroup(_ s: String) -> (content: String, consumed: Int)? {
        let trimmed = s.drop(while: { $0.isWhitespace })
        guard trimmed.first == "{" else { return nil }
        
        var depth = 0
        var content = ""
        var consumed = s.count - trimmed.count  // whitespace before {
        
        for char in trimmed {
            consumed += 1
            if char == "{" {
                depth += 1
                if depth > 1 { content.append(char) }
            } else if char == "}" {
                depth -= 1
                if depth == 0 { return (content, consumed) }
                content.append(char)
            } else {
                content.append(char)
            }
        }
        return nil  // Unbalanced
    }
    
    /// Extract content from [content]
    private static func extractBracketGroup(_ s: String) -> (content: String, consumed: Int)? {
        guard s.first == "[" else { return nil }
        
        var depth = 0
        var content = ""
        var consumed = 0
        
        for char in s {
            consumed += 1
            if char == "[" {
                depth += 1
                if depth > 1 { content.append(char) }
            } else if char == "]" {
                depth -= 1
                if depth == 0 { return (content, consumed) }
                content.append(char)
            } else {
                content.append(char)
            }
        }
        return nil
    }
}

// Test Logic
let tests = [
    ("\\sum_{i=0}^{n} i", "sum(i=0)^(n) i"),
    ("Sigma_{s} N(s)", "sum(s) N(s)"),
    ("S(h) \\simeq \\frac{1}{N} \\sum_{s} N(s)", "S(h) = (1)/(N) sum(s) N(s)")
]

var failed = false
for (input, expected) in tests {
    let result = LatexNormalizer.normalize(input)
    if result != expected {
        print("FAILED: input='\(input)'")
        print("  Expected: '\(expected)'")
        print("  Got:      '\(result)'")
        failed = true
    } else {
        print("PASS: \(input) -> \(result)")
    }
}

if failed {
    exit(1)
} else {
    print("All tests passed!")
}
