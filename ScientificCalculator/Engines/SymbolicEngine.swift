// Engines/SymbolicEngine.swift
// Scientific Calculator - Symbolic Math Engine (Phase 2)

import Foundation

/// Symbolic math engine using Python + SymPy
class SymbolicEngine: MathEngine {
    private let pythonClient: PythonClient
    
    var engineName: String { "SymbolicEngine" }
    var mode: ComputationMode { .symbolic }
    
    /// Initializes symbolic engine with Python client
    /// - Parameter pythonClient: HTTP client for SymPy service (default: localhost:8001)
    init(pythonClient: PythonClient = PythonClient()) {
        self.pythonClient = pythonClient
    }
    
    /// Synchronous evaluate — kept for protocol conformance (delegates to async internally)
    func evaluate(ast: Node, context: EvaluationContext) -> EvaluationResult {
        // Fallback: run async inside a task and wait synchronously
        // This path should NOT be called from the main thread; callers should use evaluateAsync instead.
        let semaphore = DispatchSemaphore(value: 0)
        var result: EvaluationResult = .error("Symbolic evaluation failed", issue: nil)
        
        Task { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }
            result = await self.evaluateAsync(ast: ast, context: context)
            semaphore.signal()
        }
        
        let timeout = semaphore.wait(timeout: .now() + .seconds(30))
        if timeout == .timedOut {
            return .error("Symbolic evaluation timeout (>30s)", issue: nil)
        }
        return result
    }
    
    /// Proper async evaluation — no blocking, no semaphores
    func evaluateAsync(ast: Node, context: EvaluationContext) async -> EvaluationResult {
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
        
        // Call Python service with timeout via TaskGroup
        let pythonStart = CFAbsoluteTimeGetCurrent()
        
        do {
            let symbolicResult: SymbolicResult = try await withThrowingTaskGroup(of: SymbolicResult.self) { group in
                group.addTask {
                    if isEquation {
                        return try await self.pythonClient.solve(sympyExpression, variable: targetVariable)
                    } else {
                        return try await self.pythonClient.simplify(sympyExpression)
                    }
                }
                
                // Timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                    throw CancellationError()
                }
                
                // Return whichever finishes first
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            
            let pythonEnd = CFAbsoluteTimeGetCurrent()
            let pythonTimeMs = (pythonEnd - pythonStart) * 1000
            
            let formattedLatex = LatexFormatter.format(symbolicResult.latex)
            
            let metadata: [String: Double] = [
                "conversion": conversionTimeMs,
                "python": pythonTimeMs
            ]
            
            return .symbolic(symbolicResult.result, latex: formattedLatex, metadata: metadata)
        } catch is CancellationError {
            return .error("Symbolic evaluation timeout (>30s)", issue: nil)
        } catch let error as PythonClientError {
            return .error(error.localizedDescription, issue: nil)
        } catch {
            return .error("Symbolic evaluation failed: \(error.localizedDescription)", issue: nil)
        }
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
