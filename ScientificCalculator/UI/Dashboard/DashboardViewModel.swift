// UI/Dashboard/DashboardViewModel.swift
// Scientific Calculator - Dashboard ViewModel

import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var expression: String = ""
    @Published var result: String = ""
    @Published var variables: [String: Double] = [:]
    @Published var history: [HistoryEntry] = []
    @Published var showPlotPreview: Bool = false
    
    private let dispatcher: Dispatcher
    private let variablesKey = "dashboard_variables"
    private let historyKey = "dashboard_history"
    
    init(dispatcher: Dispatcher = Dispatcher()) {
        self.dispatcher = dispatcher
        loadData()
    }
    
    func evaluate() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Detect if it's a plot candidate (contains x)
        showPlotPreview = expression.contains("x")
        
        let context = EvaluationContext(variableBindings: variables)
        let report = dispatcher.evaluate(expression: expression, context: context)
        
        DispatchQueue.main.async {
            self.result = report.resultString
            
            // Add to local history
            let entry = HistoryEntry(
                expression: self.expression,
                result: self.result,
                timestamp: Date(),
                metrics: report.metrics
            )
            self.history.insert(entry, at: 0)
            if self.history.count > 20 { self.history.removeLast() }
            
            // Auto-detect variable definition
            if self.expression.contains("=") {
                self.extractVariable(from: self.expression, value: self.result)
            }
            
            self.saveData()
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
        variables[name] = value
        saveData()
    }
    
    func deleteVariable(name: String) {
        variables.removeValue(forKey: name)
        saveData()
    }
    
    private func extractVariable(from expression: String, value: String) {
        let parts = expression.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2, let doubleVal = Double(value) {
            let name = parts[0].replacingOccurrences(of: "let ", with: "")
            if !name.isEmpty && name.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
                variables[name] = doubleVal
            }
        }
    }
    
    func handleDrop(resultString: String) {
        if let val = Double(resultString) {
            let name = "v\(variables.count + 1)"
            variables[name] = val
            saveData()
        }
    }
    
    private func saveData() {
        UserDefaults.standard.set(variables, forKey: variablesKey)
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadData() {
        if let savedVars = UserDefaults.standard.dictionary(forKey: variablesKey) as? [String: Double] {
            variables = savedVars
        }
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: historyData) {
            history = decoded
        }
    }
}
