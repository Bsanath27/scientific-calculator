// Parser/SyntaxValidator.swift
// Scientific Calculator - Real-time Syntax Validation

import Foundation

/// Represents a syntax error with a position in the source string
struct SyntaxError: Equatable {
    let message: String
    let position: Int
    let length: Int
}

/// Utility for validating mathematical expressions in real-time
struct SyntaxValidator {
    
    /// Validate an expression and return found errors
    static func validate(_ expression: String) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        
        // 1. Check for invalid characters using Tokenizer (Lexical validation)
        var tokenizer = Tokenizer(input: expression)
        let tokenizeResult = tokenizer.tokenize()
        
        switch tokenizeResult {
        case .success(let tokens):
            // 2. Check for unmatched parentheses
            errors.append(contentsOf: findUnmatchedParentheses(tokens))
            
            // 3. Check for sequential operators (e.g., 5++4)
            errors.append(contentsOf: findSequentialOperators(tokens))
            
            // 4. Structural validation using the Parser (Full validation)
            var parser = Parser(tokens: tokens)
            let parseResult = parser.parse()
            
            if case .failure(let error) = parseResult {
                // If it's an error we haven't already caught by position
                if case .unexpectedToken(_, let got, let pos) = error {
                    // Only add if we don't already have an error at this exact position
                    if !errors.contains(where: { $0.position == pos }) {
                        errors.append(SyntaxError(message: "Unexpected '\(got)'", position: pos, length: 1))
                    }
                } else if case .unexpectedEndOfInput(let expected) = error {
                    // This often means something is missing (e.g., "2+")
                    // We can highlight the end of the string
                    let pos = max(0, expression.count - 1)
                    if !errors.contains(where: { $0.position == pos }) {
                        errors.append(SyntaxError(message: "Expected \(expected)", position: pos, length: 1))
                    }
                }
            }
            
        case .failure(let error):
            // Tokenizer error (invalid character/number)
            if case .invalidNumber(let text, let pos) = error {
                errors.append(SyntaxError(message: "Invalid character '\(text)'", position: pos, length: text.count))
            } else if case .unknownIdentifier(let name, let pos) = error {
                errors.append(SyntaxError(message: "Unknown: '\(name)'", position: pos, length: name.count))
            }
        }
        
        return errors
    }
    
    /// Find indices of unmatched parentheses
    private static func findUnmatchedParentheses(_ tokens: [PositionedToken]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        var openStack: [PositionedToken] = []
        
        for pToken in tokens {
            if case .leftParen = pToken.token {
                openStack.append(pToken)
            } else if case .rightParen = pToken.token {
                if openStack.isEmpty {
                    errors.append(SyntaxError(message: "Extra closing parenthesis", position: pToken.position.offset, length: 1))
                } else {
                    openStack.removeLast()
                }
            }
        }
        
        // Remaining in stack are unmatched open parens
        for pToken in openStack {
            errors.append(SyntaxError(message: "Missing closing parenthesis", position: pToken.position.offset, length: 1))
        }
        
        return errors
    }
    
    /// Check for illegal sequences like "++", "**", "+*", etc.
    private static func findSequentialOperators(_ tokens: [PositionedToken]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        
        for i in 0..<tokens.count - 1 {
            let current = tokens[i]
            let next = tokens[i+1]
            
            if case .binaryOperator(let op1) = current.token,
               case .binaryOperator(let op2) = next.token {
                
                // Allow unary '-' or '+' after another operator (e.g., "5*-2")
                if op2 == .subtract || op2 == .add {
                    continue
                }
                
                // Otherwise, sequential binary operators are usually an error
                errors.append(SyntaxError(
                    message: "Two operators in a row",
                    position: next.position.offset,
                    length: 1
                ))
            }
        }
        
        return errors
    }
}
