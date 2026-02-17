// UI/VariableStore.swift
// Scientific Calculator - Shared Variable Storage

import Foundation
import Combine

/// Singleton shared variable store used by all ViewModels.
/// Persists to a single UserDefaults key and migrates legacy keys on first launch.
final class VariableStore: ObservableObject {
    static let shared = VariableStore()
    
    @Published var variables: [String: Double] = [:]
    
    private let storageKey = "user_variables"
    
    // Legacy keys to migrate from
    private let legacyKeys = ["calculator_variables", "dashboard_variables"]
    
    private init() {
        migrateIfNeeded()
        load()
    }
    
    // MARK: - Public API
    
    func addVariable(name: String, value: Double) {
        let key = name.lowercased()
        variables[key] = value
        save()
    }
    
    func deleteVariable(name: String) {
        let key = name.lowercased()
        variables.removeValue(forKey: key)
        save()
    }
    
    func updateVariable(name: String, value: Double) {
        let key = name.lowercased()
        variables[key] = value
        save()
    }
    
    /// Create an EvaluationContext from current variables
    func evaluationContext() -> EvaluationContext {
        // Return context with current bindings
        EvaluationContext(variableBindings: variables)
    }
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(variables, forKey: storageKey)
    }
    
    private func load() {
        if let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Double] {
            // Ensure all loaded keys are lowercased for consistency
            var consistent: [String: Double] = [:]
            for (name, value) in saved {
                consistent[name.lowercased()] = value
            }
            variables = consistent
        }
    }
    
    /// One-time migration: merge legacy calculator_variables and dashboard_variables into unified key
    private func migrateIfNeeded() {
        // Only migrate if unified key doesn't exist yet
        guard UserDefaults.standard.dictionary(forKey: storageKey) == nil else { return }
        
        var merged: [String: Double] = [:]
        for key in legacyKeys {
            if let legacy = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] {
                for (name, value) in legacy {
                    merged[name.lowercased()] = value
                }
                // Remove legacy key after migration
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        if !merged.isEmpty {
            UserDefaults.standard.set(merged, forKey: storageKey)
        }
    }
}
