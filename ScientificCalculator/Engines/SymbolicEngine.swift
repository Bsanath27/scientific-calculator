// Engines/SymbolicEngine.swift
// Scientific Calculator - Symbolic Math Engine (Phase 2)

import Foundation

/// Symbolic math engine using Python + SymPy
class SymbolicEngine: MathEngine {
    private let pythonClient: PythonClient
    
    var engineName: String { "SymbolicEngine" }
    var mode: ComputationMode { .symbolic }
    
    /// Initializes symbolic engine with Python client
    /// - Parameter pythonClient: HTTP client for SymPy service (default: localhost:5000)
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
        
        // Call Python service using structured concurrency
        let pythonStart = CFAbsoluteTimeGetCurrent()
        var result: EvaluationResult = .error("Symbolic evaluation failed")
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task { // Removed @MainActor to avoid deadlock if called from Main Thread
            do {
                let symbolicResult = try await pythonClient.simplify(sympyExpression)
                
                let pythonEnd = CFAbsoluteTimeGetCurrent()
                let pythonTimeMs = (pythonEnd - pythonStart) * 1000
                
                let formattedLatex = LatexFormatter.format(symbolicResult.latex)
                
                let metadata: [String: Double] = [
                    "conversion": conversionTimeMs,
                    "python": pythonTimeMs
                ]
                
                result = .symbolic(symbolicResult.result, latex: formattedLatex, metadata: metadata)
            } catch let error as PythonClientError {
                result = .error(error.localizedDescription)
            } catch {
                result = .error("Symbolic evaluation failed: \(error.localizedDescription)")
            }
            
            semaphore.signal()
        }
        
        
        // Wait for async operation to complete (with timeout)
        let timeout = DispatchTime.now() + .seconds(30)
        let timeoutResult = semaphore.wait(timeout: timeout)
        
        if timeoutResult == .timedOut {
            return .error("Symbolic evaluation timeout (>30s)")
        }
        
        return result
    }
}
