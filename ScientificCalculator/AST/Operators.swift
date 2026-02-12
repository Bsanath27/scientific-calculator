// AST/Operators.swift
// Scientific Calculator - AST Operators

import Foundation

/// Binary operators for arithmetic
enum BinaryOperator: String, CaseIterable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
    case equals = "="
    
    /// Precedence level for Pratt parser (higher = binds tighter)
    var precedence: Int {
        switch self {
        case .add, .subtract: return 10
        case .multiply, .divide: return 20
        case .power: return 30
        case .equals: return 0
        }
    }
    
    /// Right-associative operators bind to the right
    var isRightAssociative: Bool {
        switch self {
        case .power: return true
        default: return false
        }
    }
}

/// Unary operators (prefix only for now)
enum UnaryOperator: String {
    case negate = "-"
    case positive = "+"
}

/// Mathematical functions supported
enum MathFunction: String, CaseIterable {
    case sin
    case cos
    case tan
    case log    // log base 10
    case ln     // natural log
    case sqrt
    
    /// Number of arguments expected
    var arity: Int { 1 }
}

/// Mathematical constants
enum MathConstant: String, CaseIterable {
    case pi
    case e
    
    var value: Double {
        switch self {
        case .pi: return Double.pi
        case .e: return M_E
        }
    }
}
