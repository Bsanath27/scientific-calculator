// UI/Notebook/NotebookViewModel.swift
// Scientific Calculator - Notebook ViewModel

import Foundation
import Combine

class NotebookViewModel: ObservableObject {
    @Published var notebooks: [Notebook] = []
    @Published var selectedNotebookId: UUID?
    @Published var currentInput: String = ""
    
    // Engine access
    private let dispatcher: Dispatcher
    
    // Variable context (Name -> Value)
    // Now isolation is handled by rebuildVariableContext whenever selectedNotebookId changes.
    private var variables: [String: Double] = [:]
    
    private let storageKey = "saved_notebooks"
    
    var selectedNotebook: Notebook? {
        notebooks.first { $0.id == selectedNotebookId }
    }
    
    var currentBlocks: [NotebookBlock] {
        selectedNotebook?.blocks ?? []
    }
    
    init(dispatcher: Dispatcher = Dispatcher()) {
        self.dispatcher = dispatcher
        loadNotebooks()
        
        // Ensure at least one notebook exists
        if notebooks.isEmpty {
            createNotebook(title: "My First Notebook")
        }
        
        // Select the most recent or first
        if selectedNotebookId == nil {
            selectedNotebookId = notebooks.first?.id
        }
    }
    
    // MARK: - Notebook Management
    
    func createNotebook(title: String) {
        let newNotebook = Notebook(title: title, blocks: [
            NotebookBlock(type: .text(content: "# \(title)"))
        ])
        notebooks.append(newNotebook)
        selectedNotebookId = newNotebook.id
        saveNotebooks()
    }
    
    func deleteNotebook(id: UUID) {
        notebooks.removeAll { $0.id == id }
        if selectedNotebookId == id {
            selectedNotebookId = notebooks.first?.id
        }
        saveNotebooks()
    }
    
    func selectNotebook(id: UUID) {
        selectedNotebookId = id
        rebuildVariableContext()
    }
    
    func clearCurrentNotebook() {
        guard let index = notebooks.firstIndex(where: { $0.id == selectedNotebookId }) else { return }
        notebooks[index].blocks.removeAll()
        variables.removeAll()
        saveNotebooks()
    }
    
    // MARK: - Input Processing
    
    func processInput() {
        guard selectedNotebookId != nil else { return }
        
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        let newBlock = createBlock(from: input)
        addBlock(newBlock)
        
        currentInput = "" // Clear input
    }
    
    func updateBlock(id: UUID, newContent: String) {
        guard let notebookIndex = notebooks.firstIndex(where: { $0.id == selectedNotebookId }),
              let blockIndex = notebooks[notebookIndex].blocks.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let updatedBlock = createBlock(from: newContent)
        notebooks[notebookIndex].blocks[blockIndex].type = updatedBlock.type
        
        // Re-evaluate entire notebook to update dependencies
        rebuildVariableContext()
        saveNotebooks()
    }
    
    private func createBlock(from input: String) -> NotebookBlock {
        if input.starts(with: "#") {
            return NotebookBlock(type: .text(content: input))
        } else if input.contains("=") && !input.starts(with: "==") {
            return processVariableDefinition(input)
        } else {
            return processCalculation(input)
        }
    }
    
    func addBlock(_ block: NotebookBlock) {
        guard let index = notebooks.firstIndex(where: { $0.id == selectedNotebookId }) else { return }
        notebooks[index].blocks.append(block)
        saveNotebooks()
    }
    
    // MARK: - internal Logic
    
    private func processVariableDefinition(_ input: String) -> NotebookBlock {
        // More robust parsing: handle "let x = 10", "x = 10", "x=10"
        let cleaned = input.replacingOccurrences(of: "let ", with: "")
        let parts = cleaned.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        
        if parts.count == 2 {
            let name = parts[0]
            let expression = parts[1]
            
            // Validate name (simple regex or heuristic)
            guard !name.isEmpty && name.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil else {
                return NotebookBlock(type: .error(message: "Invalid variable name: \(name)"))
            }
            
            let result = evaluate(expression)
            
            if !result.starts(with: "Error") {
                // Update local context for immediate use in creation
                if let doubleVal = Double(result) {
                    variables[name] = doubleVal
                }
                return NotebookBlock(type: .variableDefinition(name: name, value: result, expression: expression))
            } else {
                return NotebookBlock(type: .error(message: "Evaluation Error: \(result)"))
            }
        } else {
            return NotebookBlock(type: .error(message: "Invalid format. Use 'x = value'"))
        }
    }
    
    private func processCalculation(_ input: String) -> NotebookBlock {
        let result = evaluate(input)
        return NotebookBlock(type: .calculation(expression: input, result: result))
    }
    
    // MARK: - Engine Interaction
    
    private func evaluate(_ expression: String) -> String {
        let context = EvaluationContext(variableBindings: variables)
        let report = dispatcher.evaluate(expression: expression, context: context)
        return report.resultString
    }
    
    private func rebuildVariableContext() {
        variables.removeAll()
        guard let notebook = selectedNotebook else { return }
        
        for block in notebook.blocks {
            switch block.type {
            case .variableDefinition(let name, let value, _):
                if let doubleVal = Double(value) {
                    variables[name] = doubleVal
                }
            case .calculation(_, _):
                // Optional: We could re-evaluate calculations too to ensure consistency
                // but for now we just care about variables.
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveNotebooks() {
        if let encoded = try? JSONEncoder().encode(notebooks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadNotebooks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Notebook].self, from: data) {
            notebooks = decoded
        }
    }
}
