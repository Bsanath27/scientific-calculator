// Engines/SymbolicEngine.swift
// Scientific Calculator - Symbolic Math Engine (Phase 2)

import Foundation

/// Symbolic math engine using Python + SymPy
class SymbolicEngine: MathEngine {
    private let pythonClient: PythonClient
    
    var engineName: String { "SymbolicEngine" }
    var mode: ComputationMode { .symbolic }
    
    /// Initializes symbolic engine with Python client
    /// - Parameter pythonClient: HTTP client for SymPy service (default: localhost:5001)
    init(pythonClient: PythonClient = PythonClient()) {
        self.pythonClient = pythonClient
    }
    
    /// Evaluate AST using SymPy symbolic mathematics
    func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult {
        // Convert AST → SymPy expression
        let conversionStart = CFAbsoluteTimeGetCurrent()
        let sympyExpression = ASTToSympyConverter.convert(ast)
        #if DEBUG
        print("SymbolicEngine: Converted AST to SymPy expression: '\(sympyExpression)'")
        #endif
        let conversionEnd = CFAbsoluteTimeGetCurrent()
        let conversionTimeMs = (conversionEnd - conversionStart) * 1000
        
        // Check if AST is an equality (equation)
        var isEquation = false
        if case .binary(_, let op, _, _) = ast, op == .equals {
            isEquation = true
        }
        
        let variables = extractVariables(from: ast)
        let targetVariable = variables.contains("x") ? "x" : (variables.first ?? "x")
        
        // Call Python service using structured concurrency
        let pythonStart = CFAbsoluteTimeGetCurrent()
        var result: EvaluationResult = .error("Symbolic evaluation failed", issue: nil)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task { // Removed @MainActor to avoid deadlock if called from Main Thread
            do {
                let symbolicResult: SymbolicResult
                
                if isEquation {
                    // Use solve endpoint for equations
                    symbolicResult = try await pythonClient.solve(sympyExpression, variable: targetVariable)
                } else {
                    // Use simplify endpoint for expressions
                    symbolicResult = try await pythonClient.simplify(sympyExpression)
                }
                
                let pythonEnd = CFAbsoluteTimeGetCurrent()
                let pythonTimeMs = (pythonEnd - pythonStart) * 1000
                
                let formattedLatex = LatexFormatter.format(symbolicResult.latex)
                
                let metadata: [String: Double] = [
                    "conversion": conversionTimeMs,
                    "python": pythonTimeMs
                ]
                
                result = .symbolic(symbolicResult.result, latex: formattedLatex, metadata: metadata)
            } catch let error as PythonClientError {
                result = .error(error.localizedDescription, issue: nil)
            } catch {
                result = .error("Symbolic evaluation failed: \(error.localizedDescription)", issue: nil)
            }
            
            semaphore.signal()
        }
        
        
        // Wait for async operation to complete (with timeout)
        let timeout = DispatchTime.now() + .seconds(30)
        let timeoutResult = semaphore.wait(timeout: timeout)
        
        if timeoutResult == .timedOut {
            return .error("Symbolic evaluation timeout (>30s)", issue: nil)
        }
        
        return result
    }
    
    // MARK: - Private Helpers
    
    /// Extract all variable names from AST
    private func extractVariables(from node: Node) -> Set<String> {
        switch node {
        case .variable(let name, _):
            return [name]
        case .binary(let left, _, let right, _):
            return extractVariables(from: left).union(extractVariables(from: right))
        case .unary(_, let operand, _):
            return extractVariables(from: operand)
        case .function(_, let arg, _):
            return extractVariables(from: arg)
        case .number, .constant:
            return []
        case .symbolicFunction(_, let args, _):
            return args.reduce(into: Set<String>()) { result, arg in
                result.formUnion(extractVariables(from: arg))
            }
        }
    }
}
