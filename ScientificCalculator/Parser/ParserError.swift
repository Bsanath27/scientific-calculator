// Parser/ParserError.swift
// Scientific Calculator - Parser Error Types

import Foundation

/// Errors that can occur during parsing
enum ParserError: Error, Equatable, LocalizedError {
    case unexpectedToken(expected: String, got: String, position: Int)
    case unexpectedEndOfInput(expected: String)
    case unmatchedParenthesis(position: Int)
    case unknownIdentifier(name: String, position: Int)
    case invalidNumber(text: String, position: Int)
    case emptyExpression
    
    var errorDescription: String? {
        switch self {
        case .unexpectedToken(let expected, let got, let pos):
            return "Unexpected '\(got)' at position \(pos), expected \(expected)"
        case .unexpectedEndOfInput(let expected):
            return "Unexpected end of input, expected \(expected)"
        case .unmatchedParenthesis(let pos):
            return "Unmatched parenthesis at position \(pos)"
        case .unknownIdentifier(let name, let pos):
            return "Unknown identifier '\(name)' at position \(pos)"
        case .invalidNumber(let text, let pos):
            return "Invalid number '\(text)' at position \(pos)"
        case .emptyExpression:
            return "Empty expression"
        }
    }
}

/// Result of tokenization
typealias TokenizeResult = Result<[PositionedToken], ParserError>

/// Result of parsing
typealias ParseResult = Result<Node, ParserError>
