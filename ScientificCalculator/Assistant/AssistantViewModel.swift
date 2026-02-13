// Assistant/AssistantViewModel.swift
// Scientific Calculator - Phase 5: Assistant State Management
// Manages chat messages: NL input → translate → evaluate → explain.

import Foundation
import Combine

/// A single message in the assistant chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let translatedExpression: String?
    let timestamp: Date
    
    enum MessageRole {
        case user
        case assistant
    }
    
    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, content: text, translatedExpression: nil, timestamp: Date())
    }
    
    static func assistant(_ text: String, translated: String? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: text, translatedExpression: translated, timestamp: Date())
    }
}

/// ViewModel for the Assistant chat panel
final class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    
    private let dispatcher = Dispatcher()
    
    init() {
        // Welcome message
        messages.append(.assistant("Type a math question in plain English or enter an expression directly.\n\nExamples:\n• \"square root of 144\"\n• \"derivative of x^3\"\n• \"solve x^2 - 4 = 0 for x\"\n• \"15 percent of 200\""))
    }
    
    /// Send user message and process it
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        messages.append(.user(text))
        inputText = ""
        isProcessing = true
        
        // Process on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let translation = NLTranslator.translate(text)
            let response = self.processTranslation(translation, originalInput: text)
            
            DispatchQueue.main.async {
                self.messages.append(response)
                self.isProcessing = false
            }
        }
    }
    
    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        messages.append(.assistant("Chat cleared. Ask me anything!"))
    }
    
    /// Get the last expression for "Use in Calculator"
    var lastExpression: String? {
        messages.last(where: { $0.role == .assistant && $0.translatedExpression != nil })?.translatedExpression
    }
    
    // MARK: - Private
    
    private func processTranslation(_ translation: NLTranslation, originalInput: String) -> ChatMessage {
        let expr = translation.expression
        
        guard !expr.isEmpty else {
            return .assistant("I couldn't understand that. Try phrasing it differently, or enter a math expression directly.")
        }
        
        switch translation.operation {
        case .evaluate:
            return evaluateExpression(expr, translated: translation.didTranslate)
            
        case .simplify:
            dispatcher.mode = .symbolic
            let report = dispatcher.evaluate(expression: expr)
            dispatcher.mode = .numeric
            return formatResult(expr: expr, result: report.resultString, operation: "Simplify", translated: translation.didTranslate)
            
        case .differentiate:
            return evaluateSymbolic(expr: expr, operation: "differentiate", variable: translation.variable ?? "x")
            
        case .integrate:
            return evaluateSymbolic(expr: expr, operation: "integrate", variable: translation.variable ?? "x")
            
        case .solve:
            return evaluateSymbolic(expr: expr, operation: "solve", variable: translation.variable ?? "x")
        }
    }
    
    private func evaluateExpression(_ expr: String, translated: Bool) -> ChatMessage {
        let report = dispatcher.evaluate(expression: expr)
        return formatResult(expr: expr, result: report.resultString, operation: "Evaluate", translated: translated)
    }
    
    private func evaluateSymbolic(expr: String, operation: String, variable: String) -> ChatMessage {
        // Switch to symbolic mode for calculus/solve
        dispatcher.mode = .symbolic
        let report = dispatcher.evaluate(expression: expr)
        dispatcher.mode = .numeric
        
        let opLabel = operation.capitalized
        return formatResult(expr: expr, result: report.resultString, operation: opLabel, translated: true, variable: variable)
    }
    
    private func formatResult(expr: String, result: String, operation: String, translated: Bool, variable: String? = nil) -> ChatMessage {
        var lines: [String] = []
        
        if translated {
            lines.append("Expression: `\(expr)`")
        }
        
        if let v = variable {
            lines.append("Operation: \(operation) (variable: \(v))")
        }
        
        lines.append("Result: **\(result)**")
        
        let content = lines.joined(separator: "\n")
        return .assistant(content, translated: expr)
    }
}
