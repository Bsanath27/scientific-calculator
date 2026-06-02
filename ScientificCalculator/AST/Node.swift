// AST/Node.swift
// Scientific Calculator - AST Node Types

import Foundation

/// Position in source expression for error reporting
struct SourcePosition: Equatable, Codable {
    let offset: Int
    let length: Int
}

/// AST Node representing parsed expression
indirect enum Node: Equatable, Codable {
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
    
    /// Symbolic function call (e.g., f(x, y))
    case symbolicFunction(name: String, arguments: [Node], position: SourcePosition)
    
    /// Get position of this node
    var position: SourcePosition {
        switch self {
        case .number(_, let pos),
             .binary(_, _, _, let pos),
             .unary(_, _, let pos),
             .function(_, _, let pos),
             .constant(_, let pos),
             .variable(_, let pos),
             .symbolicFunction(_, _, let pos):
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
        case .symbolicFunction(_, let args, _):
            return 1 + args.reduce(0) { $0 + $1.nodeCount }
        }
    }

    /// Attempt to simplify the node by one step.
    /// Returns a new node if a simplification was made, or nil if already fully simplified.
    func simplifyStep(bindings: [String: Double] = [:]) -> Node? {
        switch self {
        case .number, .constant:
            return nil
            
        case .variable(let name, let pos):
            if let val = bindings[name] {
                return .number(val, position: pos)
            }
            return nil
            
        case .unary(let op, let operand, let pos):
            if let simplifiedOperand = operand.simplifyStep(bindings: bindings) {
                return .unary(op: op, operand: simplifiedOperand, position: pos)
            }
            if case .number(let val, _) = operand {
                switch op {
                case .negate: return .number(-val, position: pos)
                case .positive: return .number(val, position: pos)
                }
            }
            return nil
            
        case .binary(let left, let op, let right, let pos):
            // Try simplifying children first (left-to-right)
            if let simplifiedLeft = left.simplifyStep(bindings: bindings) {
                return .binary(left: simplifiedLeft, op: op, right: right, position: pos)
            }
            if let simplifiedRight = right.simplifyStep(bindings: bindings) {
                return .binary(left: left, op: op, right: simplifiedRight, position: pos)
            }
            
            // Both children are simplified (likely numbers or constants)
            if case .number(let lVal, _) = left, case .number(let rVal, _) = right {
                switch op {
                case .add: return .number(lVal + rVal, position: pos)
                case .subtract: return .number(lVal - rVal, position: pos)
                case .multiply: return .number(lVal * rVal, position: pos)
                case .divide: 
                    if rVal != 0 { return .number(lVal / rVal, position: pos) }
                case .power:
                    let res = pow(lVal, rVal)
                    if res.isFinite { return .number(res, position: pos) }
                case .equals:
                    return nil // Cannot simplify equality to a single number yet
                }
            }
            return nil
            
        case .function(let name, let arg, let pos):
            if let simplifiedArg = arg.simplifyStep(bindings: bindings) {
                return .function(name: name, argument: simplifiedArg, position: pos)
            }
            if case .number(let val, _) = arg {
                let res: Double
                switch name {
                case .sin: res = sin(val)
                case .cos: res = cos(val)
                case .tan: res = tan(val)
                case .log: res = log10(val)
                case .ln: res = log(val)
                case .sqrt: res = sqrt(val)
                }
                if res.isFinite { return .number(res, position: pos) }
            }
            return nil
            
        case .symbolicFunction:
            return nil // Symbolic functions aren't simplified numerically here
        }
    }
}

// MARK: - Codable Implementation
extension Node {
    private enum CodingKeys: String, CodingKey {
        case type, value, left, op, right, position, name, operand, argument, arguments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "number":
            let value = try container.decode(Double.self, forKey: .value)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .number(value, position: pos)
        case "binary":
            let left = try container.decode(Node.self, forKey: .left)
            let op = try container.decode(BinaryOperator.self, forKey: .op)
            let right = try container.decode(Node.self, forKey: .right)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .binary(left: left, op: op, right: right, position: pos)
        case "unary":
            let op = try container.decode(UnaryOperator.self, forKey: .op)
            let operand = try container.decode(Node.self, forKey: .operand)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .unary(op: op, operand: operand, position: pos)
        case "function":
            let name = try container.decode(MathFunction.self, forKey: .name)
            let argument = try container.decode(Node.self, forKey: .argument)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .function(name: name, argument: argument, position: pos)
        case "constant":
            let constant = try container.decode(MathConstant.self, forKey: .name)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .constant(constant, position: pos)
        case "variable":
            let name = try container.decode(String.self, forKey: .name)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .variable(name, position: pos)
        case "symbolicFunction":
            let name = try container.decode(String.self, forKey: .name)
            let arguments = try container.decode([Node].self, forKey: .arguments)
            let pos = try container.decode(SourcePosition.self, forKey: .position)
            self = .symbolicFunction(name: name, arguments: arguments, position: pos)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown Node type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .number(let value, let pos):
            try container.encode("number", forKey: .type)
            try container.encode(value, forKey: .value)
            try container.encode(pos, forKey: .position)
        case .binary(let left, let op, let right, let pos):
            try container.encode("binary", forKey: .type)
            try container.encode(left, forKey: .left)
            try container.encode(op, forKey: .op)
            try container.encode(right, forKey: .right)
            try container.encode(pos, forKey: .position)
        case .unary(let op, let operand, let pos):
            try container.encode("unary", forKey: .type)
            try container.encode(op, forKey: .op)
            try container.encode(operand, forKey: .operand)
            try container.encode(pos, forKey: .position)
        case .function(let name, let argument, let pos):
            try container.encode("function", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(argument, forKey: .argument)
            try container.encode(pos, forKey: .position)
        case .constant(let constant, let pos):
            try container.encode("constant", forKey: .type)
            try container.encode(constant, forKey: .name)
            try container.encode(pos, forKey: .position)
        case .variable(let name, let pos):
            try container.encode("variable", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(pos, forKey: .position)
        case .symbolicFunction(let name, let arguments, let pos):
            try container.encode("symbolicFunction", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(arguments, forKey: .arguments)
            try container.encode(pos, forKey: .position)
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
        case .symbolicFunction(let name, let args, _):
            let argList = args.map { $0.description }.joined(separator: ", ")
            return "\(name)(\(argList))"
        }
    }
}
