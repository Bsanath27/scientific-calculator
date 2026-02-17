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
    
    /// Evaluate expression string synchronously (numeric path — safe for background thread)
    func evaluate(expression: String, context: EvaluationContext = .empty) -> EvaluationReport {
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
                operationType: "numeric",
                pythonCallTimeMs: nil,
                conversionTimeMs: nil,
                ocrTimeMs: nil,
                ocrConfidence: nil
            )
            return EvaluationReport(
                result: .error(error.localizedDescription),
                metrics: metrics
            )
            
        case .success(let ast):
            // Evaluation phase
            let evalStart = CFAbsoluteTimeGetCurrent()
            var result = currentEngine.evaluate(ast: ast, context: context)
            var opType = mode == .numeric ? "numeric" : "symbolic"
            
            // Fallback to Symbolic Engine for equations or undefined variables,
            // based on structured error issues rather than fragile string matching.
            if case .error(let msg, let issue) = result, mode == .numeric {
                if issue == .cannotEvaluateEquality || issue == .undefinedVariable || issue == .symbolicComputationRequired {
                    #if DEBUG
                    print("Dispatcher: Numeric evaluation failed ('\(msg)'). Switching to Symbolic Engine.")
                    #endif
                    result = symbolicEngine.evaluate(ast: ast, context: context)
                    opType = "fallback"
                }
            }
            let evalEnd = CFAbsoluteTimeGetCurrent()
            let evalTimeMs = (evalEnd - evalStart) * 1000
            
            return buildReport(result: result, opType: opType, ast: ast, expression: expression,
                             parseTimeMs: parseTimeMs, evalTimeMs: evalTimeMs,
                             startTime: startTime, startMemory: startMemory)
        }
    }
    
    /// Evaluate expression string asynchronously (uses async engines — safe for UI callers)
    func evaluateAsync(expression: String, context: EvaluationContext = .empty) async -> EvaluationReport {
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
                operationType: "numeric",
                pythonCallTimeMs: nil,
                conversionTimeMs: nil,
                ocrTimeMs: nil,
                ocrConfidence: nil
            )
            return EvaluationReport(
                result: .error(error.localizedDescription),
                metrics: metrics
            )
            
        case .success(let ast):
            let evalStart = CFAbsoluteTimeGetCurrent()
            var result = await currentEngine.evaluateAsync(ast: ast, context: context)
            var opType = mode == .numeric ? "numeric" : "symbolic"
            
            // Fallback to Symbolic Engine
            if case .error(let msg, let issue) = result, mode == .numeric {
                if issue == .cannotEvaluateEquality || issue == .undefinedVariable || issue == .symbolicComputationRequired {
                    #if DEBUG
                    print("Dispatcher: Numeric evaluation failed ('\(msg)'). Switching to Symbolic Engine.")
                    #endif
                    result = await symbolicEngine.evaluateAsync(ast: ast, context: context)
                    opType = "fallback"
                }
            }
            let evalEnd = CFAbsoluteTimeGetCurrent()
            let evalTimeMs = (evalEnd - evalStart) * 1000
            
            return buildReport(result: result, opType: opType, ast: ast, expression: expression,
                             parseTimeMs: parseTimeMs, evalTimeMs: evalTimeMs,
                             startTime: startTime, startMemory: startMemory)
        }
    }
    
    // MARK: - Private
    
    private func buildReport(result: EvaluationResult, opType: String, ast: Node,
                            expression: String, parseTimeMs: Double, evalTimeMs: Double,
                            startTime: CFAbsoluteTime, startMemory: Double) -> EvaluationReport {
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
            operationType: opType,
            pythonCallTimeMs: pythonTime,
            conversionTimeMs: conversionTime,
            ocrTimeMs: nil,
            ocrConfidence: nil
        )
        
        #if DEBUG
        printMetrics(expression: expression, report: EvaluationReport(result: result, metrics: metrics))
        #endif
        
        return EvaluationReport(result: result, metrics: metrics)
    }
    
    private func printMetrics(expression: String, report: EvaluationReport) {
        print("═══════════════════════════════════════")
        print("Expression: \(expression)")
        print("Result: \(report.resultString)")
        print("───────────────────────────────────────")
        print("Op Type:     \(report.metrics.operationType)")
        print("Parse time:  \(String(format: "%.3f", report.metrics.parseTimeMs)) ms")
        print("Eval time:   \(String(format: "%.3f", report.metrics.evalTimeMs)) ms")
        print("Total time:  \(String(format: "%.3f", report.metrics.totalTimeMs)) ms")
        print("Memory:      \(String(format: "%.2f", report.metrics.peakMemoryKB)) KB")
        print("AST nodes:   \(report.metrics.astNodeCount)")
        print("Expr length: \(report.metrics.expressionLength)")
        print("═══════════════════════════════════════")
    }
}
