// Parser/Token.swift
// Scientific Calculator - Lexer Token Types

import Foundation

/// Token produced by the tokenizer
enum Token: Equatable {
    case number(Double)
    case binaryOperator(BinaryOperator)
    case leftParen
    case rightParen
    case function(MathFunction)
    case constant(MathConstant)
    case variable(String)
    case eof
    
    /// Check if token can start a prefix expression
    var canStartPrefix: Bool {
        switch self {
        case .number, .leftParen, .function, .constant, .variable:
            return true
        case .binaryOperator(let op) where op == .subtract || op == .add:
            return true  // Unary plus/minus
        default:
            return false
        }
    }
}

/// Token with position information
struct PositionedToken: Equatable {
    let token: Token
    let position: SourcePosition
}
