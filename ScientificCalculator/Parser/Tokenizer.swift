// Parser/Tokenizer.swift
// Scientific Calculator - Lexical Analyzer

import Foundation

/// Tokenizer converts input string to stream of tokens
struct Tokenizer {
    private let input: String
    private var index: String.Index
    private var offset: Int = 0
    
    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }
    
    /// Tokenize entire input
    mutating func tokenize() -> TokenizeResult {
        var tokens: [PositionedToken] = []
        
        while !isAtEnd {
            skipWhitespace()
            if isAtEnd { break }
            
            let startOffset = offset
            
            do {
                let token = try scanToken()
                let length = offset - startOffset
                tokens.append(PositionedToken(
                    token: token,
                    position: SourcePosition(offset: startOffset, length: max(1, length))
                ))
            } catch let error as ParserError {
                return .failure(error)
            } catch {
                return .failure(.invalidNumber(text: String(currentChar), position: offset))
            }
        }
        
        tokens.append(PositionedToken(
            token: .eof,
            position: SourcePosition(offset: offset, length: 0)
        ))
        
        return .success(tokens)
    }
    
    // MARK: - Private Scanning
    
    private var isAtEnd: Bool { index >= input.endIndex }
    
    private var currentChar: Character {
        guard !isAtEnd else { return "\0" }
        return input[index]
    }
    
    private mutating func advance() -> Character {
        let char = currentChar
        if !isAtEnd {
            index = input.index(after: index)
            offset += 1
        }
        return char
    }
    
    private func peek() -> Character {
        guard !isAtEnd else { return "\0" }
        return input[index]
    }
    
    private mutating func skipWhitespace() {
        while !isAtEnd && currentChar.isWhitespace {
            _ = advance()
        }
    }
    
    private mutating func scanToken() throws -> Token {
        let char = currentChar
        
        // Numbers
        if char.isNumber || char == "." {
            return try scanNumber()
        }
        
        // Identifiers (functions/constants)
        if char.isLetter {
            return try scanIdentifier()
        }
        
        // Operators and punctuation
        _ = advance()
        switch char {
        case "+": return .binaryOperator(.add)
        case "-": return .binaryOperator(.subtract)
        case "*": return .binaryOperator(.multiply)
        case "/": return .binaryOperator(.divide)
        case "^": return .binaryOperator(.power)
        case "=": return .binaryOperator(.equals)
        case "(": return .leftParen
        case ")": return .rightParen
        default:
            throw ParserError.invalidNumber(text: String(char), position: offset - 1)
        }
    }
    
    private mutating func scanNumber() throws -> Token {
        var numStr = ""
        var hasDecimal = false
        var hasExponent = false
        
        while !isAtEnd {
            let char = currentChar
            
            if char.isNumber {
                numStr.append(advance())
            } else if char == "." && !hasDecimal && !hasExponent {
                hasDecimal = true
                numStr.append(advance())
            } else if (char == "e" || char == "E") && !hasExponent && !numStr.isEmpty {
                hasExponent = true
                numStr.append(advance())
                // Handle optional sign after exponent
                if !isAtEnd && (currentChar == "+" || currentChar == "-") {
                    numStr.append(advance())
                }
            } else {
                break
            }
        }
        
        guard let value = Double(numStr) else {
            throw ParserError.invalidNumber(text: numStr, position: offset - numStr.count)
        }
        
        return .number(value)
    }
    
    private mutating func scanIdentifier() throws -> Token {

        var identifier = ""
        
        while !isAtEnd && (currentChar.isLetter || currentChar.isNumber) {
            identifier.append(advance())
        }
        
        let lowercased = identifier.lowercased()
        
        // Check for function
        if let function = MathFunction(rawValue: lowercased) {
            return .function(function)
        }
        
        // Check for constant
        if let constant = MathConstant(rawValue: lowercased) {
            return .constant(constant)
        }
        
        // Unknown identifier → treat as variable
        return .variable(lowercased)
    }
}
