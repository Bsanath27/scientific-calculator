// UI/Dashboard/DashboardViewModel.swift
// Scientific Calculator - Dashboard ViewModel

import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var expression: String = ""
    @Published var result: String = ""
    @Published var history: [HistoryEntry] = []
    @Published var showPlotPreview: Bool = false
    
    /// Shared variable store — same instance used by Calculator
    let variableStore: VariableStore
    
    /// Convenience accessor (delegates to shared store)
    var variables: [String: Double] {
        get { variableStore.variables }
        set { variableStore.variables = newValue }
    }
    
    private let dispatcher: Dispatcher
    private let historyKey = "dashboard_history"
    private var variableStoreSubscription: AnyCancellable?
    
    init(dispatcher: Dispatcher = Dispatcher(), variableStore: VariableStore = .shared) {
        self.dispatcher = dispatcher
        self.variableStore = variableStore
        loadHistory()
        
        // Forward variable store changes to trigger UI updates
        variableStoreSubscription = variableStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    func evaluate() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Detect if it's a plot candidate (contains x)
        showPlotPreview = expression.contains("x")
        
        let expr = self.expression
        let context = variableStore.evaluationContext()
        
        Task { [weak self] in
            guard let self = self else { return }
            let report = await self.dispatcher.evaluateAsync(expression: expr, context: context)
            
            await MainActor.run {
                self.result = report.resultString
                
                // Add to local history
                let entry = HistoryEntry(
                    expression: expr,
                    result: self.result,
                    timestamp: Date(),
                    metrics: report.metrics
                )
                self.history.insert(entry, at: 0)
                if self.history.count > 20 { self.history.removeLast() }
                
                // Auto-detect variable definition
                if expr.contains("=") {
                    self.extractVariable(from: expr, value: self.result)
                }
                
                self.saveHistory()
            }
        }
    }
    
    func insertText(_ text: String) {
        expression += text
    }
    
    func restoreHistory(_ entry: HistoryEntry) {
        expression = entry.expression
        evaluate()
    }
    
    func addVariable(name: String, value: Double) {
        variableStore.addVariable(name: name, value: value)
    }
    
    func deleteVariable(name: String) {
        variableStore.deleteVariable(name: name)
    }
    
    private func extractVariable(from expression: String, value: String) {
        let parts = expression.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2, let doubleVal = Double(value) {
            let name = parts[0].replacingOccurrences(of: "let ", with: "")
            if !name.isEmpty && name.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
                variableStore.addVariable(name: name, value: doubleVal)
            }
        }
    }
    
    func handleDrop(resultString: String) {
        if let val = Double(resultString) {
            let name = "v\(variables.count + 1)"
            variableStore.addVariable(name: name, value: val)
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: historyData) {
            history = decoded
        }
    }
}
