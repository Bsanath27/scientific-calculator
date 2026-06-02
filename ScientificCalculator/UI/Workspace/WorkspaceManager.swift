// UI/Workspace/WorkspaceManager.swift
// Scientific Calculator - Persistence Layer for Physica Session (Luxe UI)

import Foundation
import Combine
import SwiftUI

/// Types of data that can be saved to the Workspace
enum WorkspaceEntryType: String, Codable {
    case calculation = "Calculation"
    case simulation = "Simulation"
    case toolResult = "Tool Result"
    case note = "Note"
}

/// A single item in the Workspace timeline
struct WorkspaceEntry: Identifiable, Codable {
    let id: UUID
    let type: WorkspaceEntryType
    let title: String
    let content: String // JSON or Markdown string
    let timestamp: Date
    var module: String // e.g., "Physics", "Calculator", "Lab"
    var metadata: [String: String]?
    
    init(type: WorkspaceEntryType, title: String, content: String, module: String, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.content = content
        self.timestamp = Date()
        self.module = module
        self.metadata = metadata
    }
}

/// Central manager for Workspace persistence
final class WorkspaceManager: ObservableObject {
    @Published var entries: [WorkspaceEntry] = []
    private let saveKey = "PhysicaWorkspaceEntries"
    
    static let shared = WorkspaceManager()
    
    private init() {
        loadEntries()
    }
    
    /// Save a new entry to the workspace
    func addEntry(type: WorkspaceEntryType, title: String, content: String, module: String, metadata: [String: String]? = nil) {
        let entry = WorkspaceEntry(type: type, title: title, content: content, module: module, metadata: metadata)
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    /// Remove an entry
    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }
    
    /// Clear all entries
    func clearAll() {
        entries.removeAll()
        saveEntries()
    }
    
    // MARK: - Persistence
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([WorkspaceEntry].self, from: data) {
            self.entries = decoded
        }
    }
    
    /// Export current workspace to a professional report (Placeholder)
    func generateReport() -> String {
        var report = "# Physica Research Report\n"
        report += "Generated on: \(Date().formatted())\n\n"
        
        for entry in entries {
            report += "## \(entry.title) [\(entry.type.rawValue)]\n"
            report += "Module: \(entry.module) | \(entry.timestamp.formatted())\n\n"
            report += "\(entry.content)\n\n"
            report += "---\n\n"
        }
        
        return report
    }
}
