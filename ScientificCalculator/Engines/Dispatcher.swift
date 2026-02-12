// Engines/Dispatcher.swift
// Scientific Calculator - Engine Dispatcher

import Foundation

/// Dispatches evaluation to appropriate engine based on mode
final class Dispatcher {
    private let numericEngine: MathEngine
    private let symbolicEngine: MathEngine
    
    /// Current computation mode
    var mode: ComputationMode = .numeric
    
    /// Initialize with injectable engines (defaults for production)
    init(numeric: MathEngine = NumericEngine(), symbolic: MathEngine = SymbolicEngine()) {
        self.numericEngine = numeric
        self.symbolicEngine = symbolic
    }
    
    /// Get engine for current mode
    var currentEngine: MathEngine {
        switch mode {
        case .numeric:
            return numericEngine
        case .symbolic:
            return symbolicEngine
        }
    }
    
    /// Evaluate expression string with full metrics
    func evaluate(expression: String) -> EvaluationReport {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = MetricsCollector.currentMemoryKB()
        
        // Parse phase
        let parseStart = CFAbsoluteTimeGetCurrent()
        let parseResult = Parser.parse(expression)
        let parseEnd = CFAbsoluteTimeGetCurrent()
        let parseTimeMs = (parseEnd - parseStart) * 1000
        
        switch parseResult {
        case .failure(let error):
            let endTime = CFAbsoluteTimeGetCurrent()
            let metrics = EvaluationMetrics(
                parseTimeMs: parseTimeMs,
                evalTimeMs: 0,
                totalTimeMs: (endTime - startTime) * 1000,
                peakMemoryKB: MetricsCollector.currentMemoryKB() - startMemory,
                astNodeCount: 0,
                expressionLength: expression.count,
                pythonCallTimeMs: nil,
                conversionTimeMs: nil
            )
            return EvaluationReport(
                result: .error(error.localizedDescription),
                metrics: metrics
            )
            
        case .success(let ast):
            // Evaluation phase
            let evalStart = CFAbsoluteTimeGetCurrent()
            var result = currentEngine.evaluate(ast: ast, context: .empty)
            
            // Fallback to Symbolic Engine for equations or undefined variables
            if case .error(let msg) = result, mode == .numeric {
                if msg.contains("Cannot evaluate equality") || msg.contains("Undefined variable") {
                    #if DEBUG
                    print("Dispatcher: Numeric evaluation failed ('\(msg)'). Switching to Symbolic Engine.")
                    #endif
                    result = symbolicEngine.evaluate(ast: ast, context: .empty)
                }
            }
            let evalEnd = CFAbsoluteTimeGetCurrent()
            let evalTimeMs = (evalEnd - evalStart) * 1000
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let peakMemory = MetricsCollector.currentMemoryKB() - startMemory
            
            // Extract symbolic metrics if present
            var pythonTime: Double? = nil
            var conversionTime: Double? = nil
            
            if case .symbolic(_, _, let metadata) = result, let meta = metadata {
                pythonTime = meta["python"]
                conversionTime = meta["conversion"]
            }
            
            let metrics = EvaluationMetrics(
                parseTimeMs: parseTimeMs,
                evalTimeMs: evalTimeMs,
                totalTimeMs: (endTime - startTime) * 1000,
                peakMemoryKB: max(0, peakMemory),
                astNodeCount: ast.nodeCount,
                expressionLength: expression.count,
                pythonCallTimeMs: pythonTime,
                conversionTimeMs: conversionTime
            )
            
            #if DEBUG
            printMetrics(expression: expression, report: EvaluationReport(result: result, metrics: metrics))
            #endif
            
            return EvaluationReport(result: result, metrics: metrics)
        }
    }
    
    private func printMetrics(expression: String, report: EvaluationReport) {
        print("═══════════════════════════════════════")
        print("Expression: \(expression)")
        print("Result: \(report.resultString)")
        print("───────────────────────────────────────")
        print("Parse time:  \(String(format: "%.3f", report.metrics.parseTimeMs)) ms")
        print("Eval time:   \(String(format: "%.3f", report.metrics.evalTimeMs)) ms")
        print("Total time:  \(String(format: "%.3f", report.metrics.totalTimeMs)) ms")
        print("Memory:      \(String(format: "%.2f", report.metrics.peakMemoryKB)) KB")
        print("AST nodes:   \(report.metrics.astNodeCount)")
        print("Expr length: \(report.metrics.expressionLength)")
        print("═══════════════════════════════════════")
    }
}
