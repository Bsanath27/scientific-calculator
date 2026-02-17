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
    
    // MARK: - Input Handling
    
    /// Append input with validation (prevent multiple operators, invalid decimals)
    func handleInput(_ key: String) {
        // 1. Clear "Error" state on new input
        if result.starts(with: "Error") {
            result = ""
        }
        
        let operators = ["+", "-", "*", "/", "^"]
        let lastChar = expression.last.map(String.init) ?? ""
        
        // 2. Operator Replacement Logic
        if operators.contains(key) {
            if expression.isEmpty {
                // Allow minus at start for negative numbers
                if key == "-" {
                    expression += key
                }
                // Else ignore leading operators
                return
            }
            
            if operators.contains(lastChar) {
                // Replace last operator
                expression.removeLast()
                expression += key
                return
            }
        }
        
        // 3. Decimal Logic
        if key == "." {
            // Get current number segment (traverse back until operator)
            var currentNumber = ""
            for char in expression.reversed() {
                let s = String(char)
                if operators.contains(s) { break }
                currentNumber = s + currentNumber
            }
            
            if currentNumber.contains(".") {
                return // Ignore double decimals
            }
            
            if currentNumber.isEmpty {
                expression += "0" // "0." for naked decimal
            }
        }
        
        // 4. Default Append
        expression += key
    }
    @Published var metricsText: String = ""
    @Published var history: [HistoryEntry] = []
    @Published var isRunningBenchmark: Bool = false
    @Published var benchmarkResult: String = ""
    @Published var mode: ComputationMode = .numeric {
        didSet {
            dispatcher.mode = mode
        }
    }
    
    /// Shared variable store — single source of truth for all views
    let variableStore: VariableStore
    
    /// Convenience accessor for variables (delegates to shared store)
    var variables: [String: Double] {
        get { variableStore.variables }
        set { variableStore.variables = newValue }
    }
    
    private let dispatcher = Dispatcher()
    private let benchmarkRunner = BenchmarkRunner()
    private var variableStoreSubscription: AnyCancellable?
    
    init(variableStore: VariableStore = .shared) {
        self.variableStore = variableStore
        
        // Forward variable store changes to trigger UI updates
        variableStoreSubscription = variableStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    /// Evaluate current expression
    func evaluate() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            result = ""
            metricsText = ""
            return
        }
        
        // Check for variable assignment: "x = 42"
        if expression.contains("=") && !expression.contains("==") {
            let parts = expression.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                let name = parts[0]
                let valueExpr = parts[1]
                // Name must be letters only
                if !name.isEmpty && name.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
                    // Evaluate the RHS
                    let context = variableStore.evaluationContext()
                    let report = dispatcher.evaluate(expression: valueExpr, context: context)
                    if let val = report.result.doubleValue {
                        DispatchQueue.main.async {
                            self.variableStore.addVariable(name: name, value: val)
                            self.result = "\(name) = \(val)"
                            self.metricsText = ResultFormatter.formatMetrics(report.metrics)
                        }
                        return
                    }
                }
            }
        }
        
        // Run evaluation asynchronously via Task
        let expr = self.expression
        let context = variableStore.evaluationContext()
        
        Task { [weak self] in
            guard let self = self else { return }
            let report = await self.dispatcher.evaluateAsync(expression: expr, context: context)
            
            await MainActor.run {
                self.result = report.resultString
                self.metricsText = ResultFormatter.formatMetrics(report.metrics)
                
                // Add to history
                let entry = HistoryEntry(
                    expression: expr,
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
    
    /// Insert text into expression
    func insertText(_ text: String) {
        expression += text
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
    
    // MARK: - Variable Management (delegates to shared store)
    
    func addVariable(name: String, value: Double) {
        variableStore.addVariable(name: name, value: value)
    }
    
    func deleteVariable(name: String) {
        variableStore.deleteVariable(name: name)
    }
    
    func updateVariable(name: String, value: Double) {
        variableStore.updateVariable(name: name, value: value)
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
struct HistoryEntry: Identifiable, Equatable, Codable {
    let id = UUID()
    let expression: String
    let result: String
    let timestamp: Date
    let metrics: EvaluationMetrics
    
    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.id == rhs.id
    }
}
