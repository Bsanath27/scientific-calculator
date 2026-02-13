// Assistant/NLSyntaxAnalyzer.swift
// Scientific Calculator - Phase 5: NLU Spell Checker

import Foundation

/// Analyzes natural language input and corrects spelling mistakes for math terms.
struct NLSyntaxAnalyzer {
    
    /// Known mathematical vocabulary
    private static let vocabulary: Set<String> = [
        // Operations
        "calculate", "compute", "evaluate", "simplify", "solve",
        "derivative", "derive", "differentiate", "integral", "integrate",
        "factor", "expand", "limit", "roots",
        
        // Functions
        "sin", "sine", "cos", "cosine", "tan", "tangent",
        "log", "ln", "natural", "sqrt", "square", "root", "cube",
        "abs", "absolute", "magnitude", "factorial",
        "mean", "median", "mode", "determinant", "inverse", "transpose",
        
        // Connectors/Prepositions
        "of", "with", "respect", "to", "for", "in", "from", "and", "plus", "minus", "times", "divided", "by", "over", "power",
        "as", "approaches", "goes", "factorize"
    ]
    
    /// Corrects spelling in the input string
    /// - Parameter input: Raw user input (e.g., "inetgrate x")
    /// - Returns: Corrected string (e.g., "integrate x")
    static func correct(_ input: String) -> String {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var words = text.components(separatedBy: .whitespaces)
        
        for (index, word) in words.enumerated() {
            let lower = word.lowercased()
            
            // Skip numbers, empty strings, and likely variables (length 1)
            if lower.isEmpty || Double(lower) != nil || lower.count <= 1 {
                continue
            }
            
            // Skip if already correct
            if vocabulary.contains(lower) {
                continue
            }
            
            // Fuzzy match
            if let bestMatch = findBestMatch(for: lower) {
                // Preserve original casing if it looked like a proper noun (heuristic), 
                // but for math commands usually lowercase is fine.
                // We'll just use the vocabulary word (which is lowercase).
                words[index] = bestMatch
            }
        }
        
        return words.joined(separator: " ")
    }
    
    /// Standardizes input phrases to canonical math expressions
    /// - Parameter input: Raw or spell-checked input
    /// - Returns: Standardized string (e.g. "root of 4" -> "sqrt(4)")
    static func standardize(_ input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Phrase Replacements
        let replacements: [(String, String)] = [
            ("root of", "sqrt"),
            ("square root of", "sqrt"),
            ("cubic root of", "cbrt"),
            ("derivative of", "diff"),
            ("derivative", "diff"),
            ("antiderivative of", "integrate"),
            ("integral of", "integrate"),
            ("multiplied by", "*"),
            ("divided by", "/"),
            ("into", "*"),
            ("times", "*"),
            ("plus", "+"),
            ("minus", "-"),
            ("equals", "="),
            ("equal to", "=")
        ]
        
        for (phrase, replacement) in replacements {
             text = text.replacingOccurrences(of: phrase, with: replacement)
        }
        
        // 2. Equation Handling
        // If it looks like an equation (has =) but no command, treat as solve
        if text.contains("=") && !text.contains("solve") {
            return "solve \(text)"
        }
        
        return text
    }
    
    /// Find best matching word from vocabulary
    /// - Returns: The best match if distance <= 2, otherwise nil
    private static func findBestMatch(for token: String) -> String? {
        var bestWord: String?
        var minDistance = Int.max
        
        for word in vocabulary {
            let dist = levenshtein(token, word)
            if dist < minDistance {
                minDistance = dist
                bestWord = word
            }
        }
        
        // Threshold: 2 edits
        // Also ensure we don't correct "sin" to "tan" just because they are close.
        // Length check: don't correct very short words aggressively.
        if minDistance <= 2 {
            // Safety: if the word is very short (e.g. "si"), distance 2 matches "sin" (1 edit).
            // But "si" might be a variable. 
            // We established `lower.count <= 1` skip above, but let's be careful.
            if token.count < 3 && minDistance > 1 { return nil }
            return bestWord
        }
        
        return nil
    }
    
    /// Compute Levenshtein edit distance
    private static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1.utf16)
        let b = Array(s2.utf16)
        
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count { dist[i][0] = i }
        for j in 0...b.count { dist[0][j] = j }
        
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = (a[i - 1] == b[j - 1]) ? 0 : 1
                dist[i][j] = min(
                    dist[i - 1][j] + 1,      // deletion
                    dist[i][j - 1] + 1,      // insertion
                    dist[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return dist[a.count][b.count]
    }
}
