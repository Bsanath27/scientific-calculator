// Engines/NumericEngine.swift
// Scientific Calculator - Numeric Evaluation Engine

import Foundation
import Accelerate

/// High-performance numeric evaluation engine
final class NumericEngine: MathEngine {
    let engineName = "NumericEngine"
    let mode = ComputationMode.numeric
    
    /// Evaluate AST to numeric result
    func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult {
        do {
            let result = try evaluateNode(ast, bindings: context.variableBindings)
            return .number(result)
        } catch let error as EvaluationError {
            return .error(error.message)
        } catch {
            return .error("Unknown evaluation error: \(error)")
        }
    }
    
    // MARK: - Private Evaluation
    
    private func evaluateNode(_ node: Node, bindings: [String: Double] = [:]) throws -> Double {
        switch node {
        case .number(let value, _):
            return value
            
        case .constant(let constant, _):
            return constant.value
            
        case .variable(let name, _):
            guard let value = bindings[name] else {
                throw EvaluationError.domainError("Undefined variable: \(name)")
            }
            return value
            
        case .unary(let op, let operand, _):
            let value = try evaluateNode(operand, bindings: bindings)
            return try evaluateUnary(op: op, value: value)
            
        case .binary(let left, let op, let right, _):
            let leftValue = try evaluateNode(left, bindings: bindings)
            let rightValue = try evaluateNode(right, bindings: bindings)
            return try evaluateBinary(left: leftValue, op: op, right: rightValue)
            
        case .function(let function, let argument, _):
            let argValue = try evaluateNode(argument, bindings: bindings)
            return try evaluateFunction(function, argument: argValue)
        }
    }
    
    private func evaluateUnary(op: UnaryOperator, value: Double) throws -> Double {
        switch op {
        case .negate: return -value
        case .positive: return value
        }
    }
    
    private func evaluateBinary(left: Double, op: BinaryOperator, right: Double) throws -> Double {
        switch op {
        case .add:
            return left + right
            
        case .subtract:
            return left - right
            
        case .multiply:
            return left * right
            
        case .divide:
            guard right != 0 else {
                throw EvaluationError.divisionByZero
            }
            return left / right
            
        case .power:
            let result = pow(left, right)
            guard result.isFinite else {
                throw EvaluationError.overflow
            }
            return result
            
        case .equals:
            throw EvaluationError.domainError("Cannot evaluate equality numerically")
        }
    }
    
    private func evaluateFunction(_ function: MathFunction, argument: Double) throws -> Double {
        let result: Double
        
        switch function {
        case .sin:
            result = sin(argument)
        case .cos:
            result = cos(argument)
        case .tan:
            result = tan(argument)
        case .log:
            guard argument > 0 else {
                throw EvaluationError.domainError("log requires positive argument")
            }
            result = log10(argument)
        case .ln:
            guard argument > 0 else {
                throw EvaluationError.domainError("ln requires positive argument")
            }
            result = log(argument)
        case .sqrt:
            guard argument >= 0 else {
                throw EvaluationError.domainError("sqrt requires non-negative argument")
            }
            result = sqrt(argument)
        }
        
        guard result.isFinite else {
            throw EvaluationError.overflow
        }
        
        return result
    }
}

// MARK: - Evaluation Errors

enum EvaluationError: Error {
    case divisionByZero
    case overflow
    case domainError(String)
    
    var message: String {
        switch self {
        case .divisionByZero:
            return "Division by zero"
        case .overflow:
            return "Numeric overflow"
        case .domainError(let msg):
            return msg
        }
    }
}


