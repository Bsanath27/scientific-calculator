// Assistant/NLTranslator.swift
// Scientific Calculator - Phase 5: Natural Language → Expression Translator
// Rule-based pattern matching — no LLM used for math.

import Foundation

/// Result of NL translation
struct NLTranslation {
    /// The mathematical expression
    let expression: String
    /// What operation to perform
    let operation: MathOperation
    /// The variable (for calculus operations)
    let variable: String?
    /// Whether translation was successful
    let didTranslate: Bool
    
    static func passthrough(_ expr: String) -> NLTranslation {
        NLTranslation(expression: expr, operation: .evaluate, variable: nil, didTranslate: false)
    }
}

/// Supported math operations
enum MathOperation: String {
    case evaluate       // Default: parse and compute
    case solve          // Solve equation for variable
    case differentiate  // d/dx
    case integrate      // ∫ dx
    case simplify       // Simplify expression
}

/// Translates natural language math phrases to calculator expressions.
/// Pure pattern matching — deterministic, no ML, no external APIs.
struct NLTranslator {
    
    /// Translate natural language to a math expression + operation
    static func translate(_ input: String) -> NLTranslation {
        // 1. Spell Check / Syntax Correction
        let spellChecked = NLSyntaxAnalyzer.correct(input)
        
        // 2. Standardization (New Layer)
        let text = NLSyntaxAnalyzer.standardize(spellChecked)
        
        // 3. Normalization (lowercasing done in standardize, trimming here just in case)
        // inputToProcess removed as it was unused
        
        // Empty input
        guard !text.isEmpty else {
            return .passthrough("")
        }
        
        // If it already looks like a math expression, pass through
        if looksLikeMathExpression(text) {
            return .passthrough(input.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // Try each translator in priority order
        if let result = tryCalculus(text) { return result }
        if let result = tryLimits(text) { return result } // New
        if let result = trySolve(text) { return result }
        if let result = tryAlgebra(text) { return result } // New (Factor/Expand)
        if let result = tryStatistics(text) { return result } // New
        if let result = tryLinearAlgebra(text) { return result } // New
        if let result = tryPercentage(text) { return result }
        if let result = tryRoots(text) { return result }
        if let result = tryPowers(text) { return result }
        if let result = tryLogarithms(text) { return result }
        if let result = tryTrigonometry(text) { return result }
        if let result = tryArithmetic(text) { return result }
        if let result = tryConstants(text) { return result }
        if let result = tryFactorial(text) { return result }
        if let result = tryAbsoluteValue(text) { return result }
        
        // Fallback: try cleaning up as expression
        let cleaned = cleanToExpression(text)
        return NLTranslation(expression: cleaned, operation: .evaluate, variable: nil, didTranslate: !cleaned.isEmpty)
    }
    
    // MARK: - Detection
    
    /// Check if input already looks like a math expression (not natural language)
    private static func looksLikeMathExpression(_ text: String) -> Bool {
        let mathChars = CharacterSet(charactersIn: "0123456789+-*/^().,= ")
            .union(CharacterSet.letters)
        let stripped = text.unicodeScalars.filter { !mathChars.contains($0) }
        
        // If it starts with a number or known function, it's probably math
        let startsWithNumber = text.first?.isNumber == true
        let startsWithFunction = ["sin(", "cos(", "tan(", "log(", "ln(", "sqrt(", "exp("]
            .contains(where: { text.hasPrefix($0) })
        let hasOperators = text.contains("+") || text.contains("-") || text.contains("*")
            || text.contains("/") || text.contains("^") || text.contains("=")
        
        // Likely a math expression if: starts with number/function AND has operators AND no English words
        if (startsWithNumber || startsWithFunction) && hasOperators && stripped.isEmpty {
            return true
        }
        
        // Pure number
        if Double(text) != nil { return true }
        
        return false
    }

    // MARK: - Calculus
    
    private static func tryCalculus(_ text: String) -> NLTranslation? {
        // "derivative of X with respect to Y" / "differentiate X"
        // Synonyms: derive, diff
        let derivPatterns: [(String, String)] = [
            ("derivative of (.+?) with respect to (\\w+)", ""),
            ("differentiate (.+?) with respect to (\\w+)", ""),
            ("derive (.+?) with respect to (\\w+)", ""),
            ("d/d(\\w+) of (.+)", ""),
            ("derivative of (.+)", ""),
            ("differentiate (.+)", ""),
            ("derive (.+)", ""),
            ("diff (.+)", ""),
        ]
        
        for (pattern, _) in derivPatterns {
            if let match = text.match(pattern) {
                if match.count >= 3 {
                    let expr = cleanToExpression(match[1])
                    let variable = match[2].trimmingCharacters(in: .whitespaces)
                    return NLTranslation(expression: expr, operation: .differentiate, variable: variable, didTranslate: true)
                } else if match.count >= 2 {
                    let expr = cleanToExpression(match[1])
                    return NLTranslation(expression: expr, operation: .differentiate, variable: "x", didTranslate: true)
                }
            }
        }
        
        // "integrate X dx" / "integral of X"
        // Synonyms: antiderivative
        let integralPatterns = [
            "integrate (.+?) d(\\w+)",
            "integral of (.+?) d(\\w+)",
            "integrate (.+?) with respect to (\\w+)",
            "antiderivative of (.+?)",
            "integral of (.+)",
            "integrate (.+)",
        ]
        
        for pattern in integralPatterns {
            if let match = text.match(pattern) {
                if match.count >= 3 {
                    let expr = cleanToExpression(match[1])
                    let variable = match[2].trimmingCharacters(in: .whitespaces)
                    return NLTranslation(expression: expr, operation: .integrate, variable: variable, didTranslate: true)
                } else if match.count >= 2 {
                    let expr = cleanToExpression(match[1])
                    return NLTranslation(expression: expr, operation: .integrate, variable: "x", didTranslate: true)
                }
            }
        }
        
        return nil
    }

    // MARK: - Limits (New)
    
    private static func tryLimits(_ text: String) -> NLTranslation? {
        // "limit of f(x) as x approaches N"
        if let match = text.match("limit of (.+?) as (\\w+) (?:approaches|goes to|->) (.+)") {
            let expr = cleanToExpression(match[1])
            let variable = match[2]
            let target = match[3]
            return NLTranslation(expression: "limit(\(expr), \(variable), \(target))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        return nil
    }
    
    // MARK: - Algebra (New)
    
    private static func tryAlgebra(_ text: String) -> NLTranslation? {
        // "factor X" / "factorize X"
        if let match = text.match("(?:factor|factorize) (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "factor(\(expr))", operation: .simplify, variable: nil, didTranslate: true)
        }
        
        // "expand X"
        if let match = text.match("expand (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "expand(\(expr))", operation: .simplify, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Statistics (New)
    
    private static func tryStatistics(_ text: String) -> NLTranslation? {
        let statsOps = ["mean", "median", "mode", "variance", "std dev", "standard deviation"]
        
        for op in statsOps {
            if let match = text.match("\(op) of (.+)") {
                let nums = match[1] // "1, 2, 3"
                // Map "std dev" -> "stdev" for SymPy if needed, or handle in Python.
                // Assuming Python service has mapping or we map here.
                let funcName = op.replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "stddev", with: "stdev")
                    .replacingOccurrences(of: "standarddeviation", with: "stdev")
                
                return NLTranslation(expression: "\(funcName)([\(nums)])", operation: .evaluate, variable: nil, didTranslate: true)
            }
        }
        return nil
    }
    
    // MARK: - Linear Algebra (New)
    
    private static func tryLinearAlgebra(_ text: String) -> NLTranslation? {
        // "determinant of [[1, 2], [3, 4]]"
        if let match = text.match("determinant of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "det(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "inverse of X"
        if let match = text.match("inverse of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "inverse(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "transpose of X"
        if let match = text.match("transpose of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "transpose(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Solve
    
    private static func trySolve(_ text: String) -> NLTranslation? {
        // "solve X for Y" / "solve X"
        // Synonym: roots of X
        let patterns = [
            "solve (.+?) for (\\w+)",
            "find (\\w+) (?:in|from|where) (.+)",
            "solve (.+)",
            "roots of (.+)"
        ]
        
        for pattern in patterns {
            if let match = text.match(pattern) {
                if match.count >= 3 {
                    let expr = cleanToExpression(match[1])
                    let variable = match[2].trimmingCharacters(in: .whitespaces)
                    return NLTranslation(expression: expr, operation: .solve, variable: variable, didTranslate: true)
                } else if match.count >= 2 {
                    let expr = cleanToExpression(match[1])
                    return NLTranslation(expression: expr, operation: .solve, variable: "x", didTranslate: true)
                }
            }
        }
        
        return nil
    }
    
    // ... (Rest of existing methods percentage, roots, etc.) ...
    
    // MARK: - Percentage
    
    private static func tryPercentage(_ text: String) -> NLTranslation? {
        // "what is X percent of Y" → Y * X / 100
        if let match = text.match("(?:what is |)([\\d.]+) ?(?:percent|%) of ([\\d.]+)") {
            return NLTranslation(expression: "\(match[2]) * \(match[1]) / 100", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "X% of Y"
        if let match = text.match("([\\d.]+)% of ([\\d.]+)") {
            return NLTranslation(expression: "\(match[2]) * \(match[1]) / 100", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Roots
    
    private static func tryRoots(_ text: String) -> NLTranslation? {
        // "square root of X"
        if let match = text.match("square root of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "sqrt(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "cube root of X" → X^(1/3)
        if let match = text.match("cube root of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "(\(expr))^(1/3)", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "Nth root of X" → X^(1/N)
        if let match = text.match("(\\d+)(?:th|st|nd|rd) root of (.+)") {
            let n = match[1]
            let expr = cleanToExpression(match[2])
            return NLTranslation(expression: "(\(expr))^(1/\(n))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "sqrt X"
        if let match = text.match("sqrt (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "sqrt(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Powers
    
    private static func tryPowers(_ text: String) -> NLTranslation? {
        // "X to the power of Y"
        if let match = text.match("(.+?) to the power of (.+)") {
            let base = cleanToExpression(match[1])
            let exp = cleanToExpression(match[2])
            return NLTranslation(expression: "(\(base))^(\(exp))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "X squared"
        if let match = text.match("(.+?) squared") {
            let base = cleanToExpression(match[1])
            return NLTranslation(expression: "(\(base))^2", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "X cubed"
        if let match = text.match("(.+?) cubed") {
            let base = cleanToExpression(match[1])
            return NLTranslation(expression: "(\(base))^3", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Logarithms
    
    private static func tryLogarithms(_ text: String) -> NLTranslation? {
        // "log base N of X" → log(X)/log(N)
        if let match = text.match("log ?(?:base|b) ?(\\d+) of (.+)") {
            let base = match[1]
            let expr = cleanToExpression(match[2])
            return NLTranslation(expression: "log(\(expr))/log(\(base))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "natural log of X" / "ln of X"
        if let match = text.match("(?:natural log|ln) of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "ln(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        // "log of X" → log(X) (base 10)
        if let match = text.match("log of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "log(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        
        return nil
    }
    
    // MARK: - Trigonometry
    
    private static func tryTrigonometry(_ text: String) -> NLTranslation? {
        let trigFunctions = ["sin", "cos", "tan"]
        
        for fn in trigFunctions {
            // "sine of X" / "cosine of X" / "tangent of X"
            let fullName: String
            switch fn {
            case "sin": fullName = "sine"
            case "cos": fullName = "cosine"
            case "tan": fullName = "tangent"
            default: continue
            }
            
            if let match = text.match("\(fullName) of (.+)") {
                let expr = cleanToExpression(match[1])
                return NLTranslation(expression: "\(fn)(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
            }
            
            // "sin of X"
            if let match = text.match("\(fn) of (.+)") {
                let expr = cleanToExpression(match[1])
                return NLTranslation(expression: "\(fn)(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
            }
        }
        
        return nil
    }
    
    // MARK: - Arithmetic
    
    private static func tryArithmetic(_ text: String) -> NLTranslation? {
        // "what is X plus/minus/times/divided by Y"
        let ops: [(String, String)] = [
            ("plus", "+"), ("added to", "+"), ("and", "+"),
            ("minus", "-"), ("subtracted by", "-"),
            ("times", "*"), ("multiplied by", "*"),
            ("divided by", "/"), ("over", "/"),
        ]
        
        // Strip "what is" prefix
        var cleaned = text
        for prefix in ["what is ", "what's ", "calculate ", "compute ", "evaluate "] {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        
        for (word, symbol) in ops {
            if let match = cleaned.match("(.+?) \(word) (.+)") {
                let left = cleanToExpression(match[1])
                let right = cleanToExpression(match[2])
                if !left.isEmpty && !right.isEmpty {
                    return NLTranslation(expression: "\(left) \(symbol) \(right)", operation: .evaluate, variable: nil, didTranslate: true)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Constants
    
    private static func tryConstants(_ text: String) -> NLTranslation? {
        if text == "pi" || text == "value of pi" {
            return NLTranslation(expression: "pi", operation: .evaluate, variable: nil, didTranslate: true)
        }
        if text == "e" || text == "euler's number" || text == "eulers number" {
            return NLTranslation(expression: "E", operation: .evaluate, variable: nil, didTranslate: true)
        }
        return nil
    }
    
    // MARK: - Factorial
    
    private static func tryFactorial(_ text: String) -> NLTranslation? {
        // "factorial of X" / "X factorial"
        if let match = text.match("factorial of (\\d+)") {
            return NLTranslation(expression: "\(match[1])!", operation: .evaluate, variable: nil, didTranslate: true)
        }
        if let match = text.match("(\\d+) factorial") {
            return NLTranslation(expression: "\(match[1])!", operation: .evaluate, variable: nil, didTranslate: true)
        }
        return nil
    }
    
    // MARK: - Absolute Value
    
    private static func tryAbsoluteValue(_ text: String) -> NLTranslation? {
        if let match = text.match("(?:absolute value|abs|magnitude) of (.+)") {
            let expr = cleanToExpression(match[1])
            return NLTranslation(expression: "abs(\(expr))", operation: .evaluate, variable: nil, didTranslate: true)
        }
        return nil
    }
    
    // MARK: - Helpers
    
    /// Clean natural language fragments into expression-like strings
    private static func cleanToExpression(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Word → symbol replacements
        let replacements: [(String, String)] = [
            ("x squared", "x^2"),
            ("x cubed", "x^3"),
            ("squared", "^2"),
            ("cubed", "^3"),
            ("pi over", "pi/"),
            ("pi", "pi"),
            ("divided by", "/"),
            ("multiplied by", "*"),
            ("times", "*"),
            ("plus", "+"),
            ("minus", "-"),
            ("over", "/"),
        ]
        
        for (word, symbol) in replacements {
            result = result.replacingOccurrences(of: " \(word) ", with: " \(symbol) ")
            result = result.replacingOccurrences(of: " \(word)", with: "\(symbol)")
            if result.hasPrefix("\(word) ") {
                result = "\(symbol) " + String(result.dropFirst(word.count + 1))
            }
        }
        
        // Clean up spaces around operators
        result = result.replacingOccurrences(of: " + ", with: "+")
            .replacingOccurrences(of: " - ", with: "-")
            .replacingOccurrences(of: " * ", with: "*")
            .replacingOccurrences(of: " / ", with: "/")
        
        // Remove "equals" → "="
        result = result.replacingOccurrences(of: " equals ", with: " = ")
        result = result.replacingOccurrences(of: " equal to ", with: " = ")
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Regex Helper

private extension String {
    /// Match regex and return capture groups (index 0 = full match, 1+ = groups)
    func match(_ pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range) else {
            return nil
        }
        
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            if let groupRange = Range(match.range(at: i), in: self) {
                groups.append(String(self[groupRange]))
            } else {
                groups.append("")
            }
        }
        
        return groups.count > 1 ? groups : nil
    }
}
