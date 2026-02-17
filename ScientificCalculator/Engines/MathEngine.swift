// Engines/MathEngine.swift
// Scientific Calculator - Engine Protocol

import Foundation

/// Evaluation context with optional variable bindings
struct EvaluationContext {
    /// Variable name → value bindings for evaluation
    let variableBindings: [String: Double]
    
    static let empty = EvaluationContext(variableBindings: [:])
    
    /// Create context with variable bindings
    static func withBindings(_ bindings: [String: Double]) -> EvaluationContext {
        EvaluationContext(variableBindings: bindings)
    }
}

/// Structured issues that can be attached to an evaluation error.
/// This allows higher-level components (like the dispatcher) to make
/// decisions based on error type instead of fragile string matching.
enum EvaluationIssue: Equatable {
    case divisionByZero
    case overflow
    case domainError
    case cannotEvaluateEquality
    case undefinedVariable
    case symbolicComputationRequired
}

/// Result of an evaluation
enum EvaluationResult: Equatable {
    case number(Double)
    case symbolic(String, latex: String, metadata: [String: Double]?)
    case error(String, issue: EvaluationIssue? = nil)
    case notImplemented(String)
    
    var isSuccess: Bool {
        switch self {
        case .number, .symbolic:
            return true
        default:
            return false
        }
    }
    
    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
    
    var symbolicValue: (result: String, latex: String)? {
        if case .symbolic(let result, let latex, _) = self {
            return (result, latex)
        }
        return nil
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let msg, _): return msg
        case .notImplemented(let msg): return msg
        default: return nil
        }
    }
}

/// Computation mode
enum ComputationMode {
    case numeric
    case symbolic
}

/// Protocol for math evaluation engines
protocol MathEngine {
    /// Evaluate AST and return result with metrics (synchronous)
    func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult
    
    /// Evaluate AST asynchronously (override for engines with async operations)
    func evaluateAsync(ast: Node, context: EvaluationContext) async -> EvaluationResult
    
    /// Engine identifier
    var engineName: String { get }
    
    /// Supported mode
    var mode: ComputationMode { get }
}

/// Default async implementation wraps the sync call
extension MathEngine {
    func evaluateAsync(ast: Node, context: EvaluationContext) async -> EvaluationResult {
        return evaluate(ast: ast, context: context)
    }
}
