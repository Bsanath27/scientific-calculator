// Assistant/AssistantViewModel.swift
// Scientific Calculator - Phase 5: Assistant State Management
// Manages NL input → translate → preview → edit → evaluate flow.

import Foundation
import Combine

/// A single message in the assistant chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let translatedExpression: String?
    let metrics: AssistantMetrics?
    let timestamp: Date
    
    enum MessageRole {
        case user
        case assistant
    }
    
    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, content: text, translatedExpression: nil, metrics: nil, timestamp: Date())
    }
    
    static func assistant(_ text: String, translated: String? = nil, metrics: AssistantMetrics? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: text, translatedExpression: translated, metrics: metrics, timestamp: Date())
    }
}

/// ViewModel for the Assistant panel — two-step: translate → preview/edit → evaluate
final class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    
    // Preview state
    @Published var previewExpression: String = ""
    @Published var previewOperation: MathOperation = .evaluate
    @Published var previewVariable: String? = nil
    @Published var showPreview: Bool = false
    @Published var previewConfidence: Double = 0.0
    @Published var lastMetrics: AssistantMetrics? = nil
    
    private let dispatcher = Dispatcher()
    private var translationTimeMs: Double = 0
    private var originalInput: String = ""
    
    init() {
        messages.append(.assistant("Type a math question in plain English or enter an expression directly.\n\nExamples:\n• \"square root of 144\"\n• \"derivative of x^3\"\n• \"solve x^2 - 4 = 0 for x\"\n• \"15 percent of 200\""))
    }
    
    /// Step 1: Translate NL → expression preview
    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        originalInput = text
        messages.append(.user(text))
        inputText = ""
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let start = CFAbsoluteTimeGetCurrent()
            let translation = NLTranslator.translate(text)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            
            let confidence = AssistantMetrics.confidence(for: translation)
            
            DispatchQueue.main.async {
                self.translationTimeMs = elapsed
                self.previewExpression = translation.expression
                self.previewOperation = translation.operation
                self.previewVariable = translation.variable
                self.previewConfidence = confidence
                self.showPreview = true
                self.isProcessing = false
            }
        }
    }
    
    /// Step 2: Evaluate the (possibly edited) expression
    func evaluate() {
        let expr = previewExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expr.isEmpty else {
            messages.append(.assistant("Empty expression — nothing to evaluate."))
            dismissPreview()
            return
        }
        
        showPreview = false
        isProcessing = true
        
        let operation = previewOperation
        let variable = previewVariable
        let translationMs = translationTimeMs
        let confidence = previewConfidence
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Set mode based on operation
            if operation != .evaluate {
                self.dispatcher.mode = .symbolic
            }
            
            let report = self.dispatcher.evaluate(expression: expr)
            
            // Reset mode
            self.dispatcher.mode = .numeric
            
            let metrics = AssistantMetrics(
                translationTimeMs: translationMs,
                translationConfidence: confidence,
                parseTimeMs: report.metrics.parseTimeMs,
                evalTimeMs: report.metrics.evalTimeMs
            )
            
            let response = self.formatResult(
                expr: expr,
                result: report.resultString,
                operation: operation.rawValue.capitalized,
                translated: true,
                variable: variable,
                metrics: metrics
            )
            
            DispatchQueue.main.async {
                self.messages.append(response)
                self.lastMetrics = metrics
                self.isProcessing = false
                self.dismissPreview()
            }
        }
    }
    
    /// Quick evaluate — translate + evaluate in one step (for power users / QuickSolver)
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messages.append(.user(text))
        inputText = ""
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let start = CFAbsoluteTimeGetCurrent()
            let translation = NLTranslator.translate(text)
            let translationMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
            let confidence = AssistantMetrics.confidence(for: translation)
            
            let response = self.processTranslation(
                translation,
                originalInput: text,
                translationMs: translationMs,
                confidence: confidence
            )
            
            DispatchQueue.main.async {
                self.messages.append(response)
                self.isProcessing = false
            }
        }
    }
    
    /// Dismiss the preview pane
    func dismissPreview() {
        showPreview = false
        previewExpression = ""
        previewOperation = .evaluate
        previewVariable = nil
        previewConfidence = 0.0
    }
    
    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        dismissPreview()
        messages.append(.assistant("Chat cleared. Ask me anything!"))
    }
    
    /// Get the last expression for "Use in Calculator"
    var lastExpression: String? {
        messages.last(where: { $0.role == .assistant && $0.translatedExpression != nil })?.translatedExpression
    }
    
    // MARK: - Private
    
    private func processTranslation(
        _ translation: NLTranslation,
        originalInput: String,
        translationMs: Double,
        confidence: Double
    ) -> ChatMessage {
        let expr = translation.expression
        
        guard !expr.isEmpty else {
            return .assistant("I couldn't understand that. Try phrasing it differently, or enter a math expression directly.")
        }
        
        // Set mode for symbolic operations
        if translation.operation != .evaluate {
            dispatcher.mode = .symbolic
        }
        
        let report = dispatcher.evaluate(expression: expr)
        dispatcher.mode = .numeric
        
        let metrics = AssistantMetrics(
            translationTimeMs: translationMs,
            translationConfidence: confidence,
            parseTimeMs: report.metrics.parseTimeMs,
            evalTimeMs: report.metrics.evalTimeMs
        )
        
        return formatResult(
            expr: expr,
            result: report.resultString,
            operation: translation.operation.rawValue.capitalized,
            translated: translation.didTranslate,
            variable: translation.variable,
            metrics: metrics
        )
    }
    
    private func formatResult(
        expr: String,
        result: String,
        operation: String,
        translated: Bool,
        variable: String? = nil,
        metrics: AssistantMetrics? = nil
    ) -> ChatMessage {
        var lines: [String] = []
        
        if translated {
            lines.append("Expression: `\(expr)`")
        }
        
        if let v = variable {
            lines.append("Operation: \(operation) (variable: \(v))")
        }
        
        lines.append("Result: **\(result)**")
        
        if let m = metrics {
            lines.append("\(m.summary)")
        }
        
        let content = lines.joined(separator: "\n")
        return .assistant(content, translated: expr, metrics: metrics)
    }
}
