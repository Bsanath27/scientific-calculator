// Symbolic/ASTToSympyConverter.swift
// Scientific Calculator - AST to SymPy Expression Converter

import Foundation

/// Converts AST nodes to SymPy-compatible expression strings
struct ASTToSympyConverter {
    
    /// Convert AST node to SymPy expression string
    /// - Parameter node: AST root node
    /// - Returns: SymPy-compatible expression string
    static func convert(_ node: Node) -> String {
        return convertNode(node)
    }
    
    // MARK: - Private Conversion
    
    private static func convertNode(_ node: Node) -> String {
        switch node {
        case .number(let value, _):
            return formatNumber(value)
            
        case .constant(let constant, _):
            return convertConstant(constant)
            
        case .variable(let name, _):
            return name
            
        case .unary(let op, let operand, _):
            return convertUnary(op: op, operand: operand)
            
        case .binary(let left, let op, let right, _):
            return convertBinary(left: left, op: op, right: right)
            
        case .function(let function, let argument, _):
            return convertFunction(function: function, argument: argument)
        }
    }
    
    /// Format number value
    private static func formatNumber(_ value: Double) -> String {
        // Check if it's an integer
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(value)
    }
    
    /// Convert constant to SymPy equivalent
    private static func convertConstant(_ constant: MathConstant) -> String {
        switch constant {
        case .pi:
            return "pi"
        case .e:
            return "E"
        }
    }
    
    /// Convert unary operation
    private static func convertUnary(op: UnaryOperator, operand: Node) -> String {
        let operandStr = convertNode(operand)
        
        switch op {
        case .negate:
            // Wrap in parens if operand is complex
            if needsParens(operand) {
                return "-(\(operandStr))"
            }
            return "-\(operandStr)"
        case .positive:
            // Positive is a no-op in SymPy
            return operandStr
        }
    }
    
    /// Convert binary operation
    private static func convertBinary(left: Node, op: BinaryOperator, right: Node) -> String {
        let leftStr = convertNode(left)
        let rightStr = convertNode(right)
        
        switch op {
        case .add:
            return "\(leftStr) + \(rightStr)"
        case .subtract:
            return "\(leftStr) - \(wrapIfNeeded(right, rightStr))"
        case .multiply:
            return "\(wrapIfNeeded(left, leftStr)) * \(wrapIfNeeded(right, rightStr))"
        case .divide:
            return "\(wrapIfNeeded(left, leftStr)) / \(wrapIfNeeded(right, rightStr))"
        case .power:
            // SymPy uses ** for exponentiation
            return "\(wrapIfNeeded(left, leftStr))**\(wrapIfNeeded(right, rightStr))"
        case .equals:
            return "Eq(\(leftStr), \(rightStr))"
        }
    }
    
    /// Convert function call
    private static func convertFunction(function: MathFunction, argument: Node) -> String {
        let argStr = convertNode(argument)
        
        switch function {
        case .sin:
            return "sin(\(argStr))"
        case .cos:
            return "cos(\(argStr))"
        case .tan:
            return "tan(\(argStr))"
        case .log:
            return "log(\(argStr), 10)"  // SymPy log needs base
        case .ln:
            return "log(\(argStr))"  // Natural log
        case .sqrt:
            return "sqrt(\(argStr))"
        }
    }
    
    /// Check if node needs parentheses
    private static func needsParens(_ node: Node) -> Bool {
        switch node {
        case .binary:
            return true
        default:
            return false
        }
    }
    
    /// Wrap expression in parentheses if needed
    private static func wrapIfNeeded(_ node: Node, _ str: String) -> String {
        if needsParens(node) {
            return "(\(str))"
        }
        return str
    }
}
