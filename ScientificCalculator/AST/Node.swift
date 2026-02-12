// AST/Node.swift
// Scientific Calculator - AST Node Types

import Foundation

/// Position in source expression for error reporting
struct SourcePosition: Equatable {
    let offset: Int
    let length: Int
}

/// AST Node representing parsed expression
indirect enum Node: Equatable {
    /// Numeric literal value
    case number(Double, position: SourcePosition)
    
    /// Binary operation (left op right)
    case binary(left: Node, op: BinaryOperator, right: Node, position: SourcePosition)
    
    /// Unary operation (op operand)
    case unary(op: UnaryOperator, operand: Node, position: SourcePosition)
    
    /// Function call (e.g., sin(x))
    case function(name: MathFunction, argument: Node, position: SourcePosition)
    
    /// Mathematical constant (pi, e)
    case constant(MathConstant, position: SourcePosition)
    
    /// Variable reference (e.g., x)
    case variable(String, position: SourcePosition)
    
    /// Get position of this node
    var position: SourcePosition {
        switch self {
        case .number(_, let pos),
             .binary(_, _, _, let pos),
             .unary(_, _, let pos),
             .function(_, _, let pos),
             .constant(_, let pos),
             .variable(_, let pos):
            return pos
        }
    }
    
    /// Count total nodes in tree
    var nodeCount: Int {
        switch self {
        case .number, .constant, .variable:
            return 1
        case .unary(_, let operand, _):
            return 1 + operand.nodeCount
        case .binary(let left, _, let right, _):
            return 1 + left.nodeCount + right.nodeCount
        case .function(_, let argument, _):
            return 1 + argument.nodeCount
        }
    }
}

// MARK: - Debug Description
extension Node: CustomStringConvertible {
    var description: String {
        switch self {
        case .number(let value, _):
            return "\(value)"
        case .binary(let left, let op, let right, _):
            return "(\(left) \(op.rawValue) \(right))"
        case .unary(let op, let operand, _):
            return "(\(op.rawValue)\(operand))"
        case .function(let name, let arg, _):
            return "\(name.rawValue)(\(arg))"
        case .constant(let c, _):
            return c.rawValue
        case .variable(let name, _):
            return name
        }
    }
}
