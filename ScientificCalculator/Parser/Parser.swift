// Parser/Parser.swift
// Scientific Calculator - Pratt Parser

import Foundation

/// Pratt parser for mathematical expressions
struct Parser {
    private var tokens: [PositionedToken]
    private var current: Int = 0
    
    init(tokens: [PositionedToken]) {
        self.tokens = tokens
    }
    
    /// Parse tokens into AST
    mutating func parse() -> ParseResult {
        guard !tokens.isEmpty else {
            return .failure(.emptyExpression)
        }
        
        // Filter out EOF for empty check
        let nonEofTokens = tokens.filter { 
            if case .eof = $0.token { return false }
            return true
        }
        
        if nonEofTokens.isEmpty {
            return .failure(.emptyExpression)
        }
        
        do {
            let node = try parseExpression(precedence: 0)
            
            // Ensure we consumed all tokens
            if !isAtEnd {
                let pos = currentToken.position
                return .failure(.unexpectedToken(
                    expected: "end of expression",
                    got: describeToken(currentToken.token),
                    position: pos.offset
                ))
            }
            
            return .success(node)
        } catch let error as ParserError {
            return .failure(error)
        } catch {
            return .failure(.unexpectedEndOfInput(expected: "expression"))
        }
    }
    
    // MARK: - Pratt Parser Core
    
    /// Parse expression with given minimum precedence
    private mutating func parseExpression(precedence: Int) throws -> Node {
        var left = try parsePrefix()
        
        while !isAtEnd {
            var op: BinaryOperator
            var opPrecedence: Int
            var isImplicit = false
            
            if let (explicitOp, explicitPrecedence) = infixOperator {
                op = explicitOp
                opPrecedence = explicitPrecedence
            } else if currentToken.token.canStartPrefix {
                // Implicit multiplication: 2x, 2(x), (a)(b)
                // We treat this as multiplication with same precedence as explicit multiplication
                op = .multiply
                opPrecedence = op.precedence
                isImplicit = true
            } else {
                break
            }
            
            // Stop if operator binds less tightly than current precedence
            if opPrecedence < precedence { break }
            
            // Consume operator ONLY if explicit
            if !isImplicit {
                _ = advance()
            }
            
            // Right-associativity: use same precedence; left-associativity: use higher
            let nextPrecedence = op.isRightAssociative ? opPrecedence : opPrecedence + 1
            let right = try parseExpression(precedence: nextPrecedence)
            
            let startPos = left.position
            let endPos = right.position
            let combinedPos = SourcePosition(
                offset: startPos.offset,
                length: (endPos.offset + endPos.length) - startPos.offset
            )
            
            left = .binary(left: left, op: op, right: right, position: combinedPos)
        }
        
        return left
    }
    
    /// Parse prefix expression (number, unary op, function, paren group)
    private mutating func parsePrefix() throws -> Node {
        let token = currentToken
        
        switch token.token {
        case .number(let value):
            _ = advance()
            return .number(value, position: token.position)
            
        case .constant(let constant):
            _ = advance()
            return .constant(constant, position: token.position)
            
        case .variable(let name):
            _ = advance()
            return .variable(name, position: token.position)
            
        case .binaryOperator(let op) where op == .subtract || op == .add:
            // Unary plus/minus
            _ = advance()
            let operand = try parsePrefix()
            let unaryOp: UnaryOperator = (op == .subtract) ? .negate : .positive
            let combinedPos = SourcePosition(
                offset: token.position.offset,
                length: (operand.position.offset + operand.position.length) - token.position.offset
            )
            return .unary(op: unaryOp, operand: operand, position: combinedPos)
            
        case .function(let function):
            return try parseFunction(function, startPosition: token.position)
            
        case .leftParen:
            return try parseGroupedExpression(startPosition: token.position)
            
        case .eof:
            throw ParserError.unexpectedEndOfInput(expected: "expression")
            
        default:
            throw ParserError.unexpectedToken(
                expected: "number, function, or '('",
                got: describeToken(token.token),
                position: token.position.offset
            )
        }
    }
    
    /// Parse function call: name(argument)
    private mutating func parseFunction(_ function: MathFunction, startPosition: SourcePosition) throws -> Node {
        _ = advance()  // consume function name
        
        guard case .leftParen = currentToken.token else {
            throw ParserError.unexpectedToken(
                expected: "'(' after function name",
                got: describeToken(currentToken.token),
                position: currentToken.position.offset
            )
        }
        _ = advance()  // consume '('
        
        let argument = try parseExpression(precedence: 0)
        
        guard case .rightParen = currentToken.token else {
            throw ParserError.unmatchedParenthesis(position: startPosition.offset)
        }
        let endToken = advance()  // consume ')'
        
        let combinedPos = SourcePosition(
            offset: startPosition.offset,
            length: (endToken.position.offset + 1) - startPosition.offset
        )
        
        return .function(name: function, argument: argument, position: combinedPos)
    }
    
    /// Parse parenthesized expression
    private mutating func parseGroupedExpression(startPosition: SourcePosition) throws -> Node {
        _ = advance()  // consume '('
        
        let inner = try parseExpression(precedence: 0)
        
        guard case .rightParen = currentToken.token else {
            throw ParserError.unmatchedParenthesis(position: startPosition.offset)
        }
        _ = advance()  // consume ')'
        
        return inner
    }
    
    // MARK: - Token Utilities
    
    private var isAtEnd: Bool {
        if case .eof = currentToken.token { return true }
        return current >= tokens.count
    }
    
    private var currentToken: PositionedToken {
        guard current < tokens.count else {
            return PositionedToken(token: .eof, position: SourcePosition(offset: 0, length: 0))
        }
        return tokens[current]
    }
    
    @discardableResult
    private mutating func advance() -> PositionedToken {
        let token = currentToken
        if current < tokens.count { current += 1 }
        return token
    }
    
    /// Get current infix operator and its precedence, if any
    private var infixOperator: (BinaryOperator, Int)? {
        guard case .binaryOperator(let op) = currentToken.token else { return nil }
        return (op, op.precedence)
    }
    
    private func describeToken(_ token: Token) -> String {
        switch token {
        case .number(let v): return "number \(v)"
        case .binaryOperator(let op): return "'\(op.rawValue)'"
        case .leftParen: return "'('"
        case .rightParen: return "')'"
        case .function(let f): return "function '\(f.rawValue)'"
        case .constant(let c): return "constant '\(c.rawValue)'"
        case .variable(let v): return "variable '\(v)'"
        case .eof: return "end of input"
        }
    }
}

// MARK: - Convenience
extension Parser {
    /// Parse expression string directly
    static func parse(_ expression: String) -> ParseResult {
        var tokenizer = Tokenizer(input: expression)
        
        switch tokenizer.tokenize() {
        case .success(let tokens):
            var parser = Parser(tokens: tokens)
            return parser.parse()
        case .failure(let error):
            return .failure(error)
        }
    }
}
