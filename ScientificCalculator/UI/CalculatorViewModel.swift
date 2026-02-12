// UI/CalculatorViewModel.swift
// Scientific Calculator - ViewModel

import Foundation
import Combine

/// ViewModel for calculator UI
final class CalculatorViewModel: ObservableObject {
    @Published var expression: String = "" {
        didSet {
            // Clear result when typing new expression
            if oldValue != expression && !result.isEmpty {
                result = ""
                metricsText = ""
            }
        }
    }
    @Published var result: String = ""
    @Published var metricsText: String = ""
    @Published var history: [HistoryEntry] = []
    @Published var isRunningBenchmark: Bool = false
    @Published var benchmarkResult: String = ""
    @Published var mode: ComputationMode = .numeric {
        didSet {
            dispatcher.mode = mode
        }
    }
    
    private let dispatcher = Dispatcher()
    private let benchmarkRunner = BenchmarkRunner()
    
    /// Evaluate current expression
    func evaluate() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            result = ""
            metricsText = ""
            return
        }
        
        // Run on background thread to prevent UI freezing (30s timeout)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let report = self.dispatcher.evaluate(expression: self.expression)
            
            DispatchQueue.main.async {
                self.result = report.resultString
                self.metricsText = ResultFormatter.formatMetrics(report.metrics)
                
                // Add to history
                let entry = HistoryEntry(
                    expression: self.expression,
                    result: self.result,
                    timestamp: Date(),
                    metrics: report.metrics
                )
                self.history.insert(entry, at: 0)
                
                // Keep history limited
                if self.history.count > 50 {
                    self.history = Array(self.history.prefix(50))
                }
            }
        }
    }
    
    /// Clear current input
    func clear() {
        expression = ""
        result = ""
        metricsText = ""
    }
    
    /// Clear all history
    func clearHistory() {
        history.removeAll()
    }
    
    /// Run benchmark on current expression
    func runBenchmark() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isRunningBenchmark = true
        benchmarkResult = ""
        
        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.benchmarkRunner.run(
                expression: self.expression,
                iterations: 1000
            )
            
            DispatchQueue.main.async {
                self.isRunningBenchmark = false
                self.benchmarkResult = """
                Benchmark Complete (1000 iterations)
                ─────────────────────────────────────
                Avg:  \(String(format: "%.4f", results.avgTimeMs)) ms
                P95:  \(String(format: "%.4f", results.p95TimeMs)) ms
                Max:  \(String(format: "%.4f", results.maxTimeMs)) ms
                Memory: \(String(format: "%.2f", results.memoryUsageKB)) KB
                """
            }
        }
    }
    
    /// Load expression from history
    func loadFromHistory(_ entry: HistoryEntry) {
        expression = entry.expression
    }
}

/// History entry model
struct HistoryEntry: Identifiable, Equatable {
    let id = UUID()
    let expression: String
    let result: String
    let timestamp: Date
    let metrics: EvaluationMetrics
    
    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.id == rhs.id
    }
}
