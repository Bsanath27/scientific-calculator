// Assistant/AssistantView.swift
// Scientific Calculator - Phase 5: Assistant Chat UI
// Chat-style panel with expression preview and edit-before-evaluate.

import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel = AssistantViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// Callback to send expression to calculator
    var onUseExpression: ((String) -> Void)?
    
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .foregroundColor(.accentColor)
                Text("Math Assistant")
                    .font(.headline)
                Spacer()
                
                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear chat")
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, onUseExpression: onUseExpression, dismiss: dismiss)
                        }
                        
                        if viewModel.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Expression Preview + Edit Pane
            if viewModel.showPreview {
                ExpressionPreviewPane(viewModel: viewModel)
            }
            
            // Quick Actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuickAction.allCases, id: \.self) { action in
                        Button(action: {
                            viewModel.inputText = action.prefix
                        }) {
                            Text(action.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Input
            HStack(spacing: 8) {
                TextField("Ask a math question...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.translate()
                        // Keep focus
                        isInputFocused = true
                    }
                
                // Translate button (shows preview)
                Button(action: { viewModel.translate() }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.inputText.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                .help("Translate & Preview")
                
                // Quick evaluate (skip preview)
                Button(action: { viewModel.send() }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.inputText.isEmpty ? .secondary : .green)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                .help("Quick Evaluate (skip preview)")
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            isInputFocused = true
        }
    }
}

// MARK: - Expression Preview Pane

struct ExpressionPreviewPane: View {
    @ObservedObject var viewModel: AssistantViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.blue)
                Text("Expression Preview")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Confidence badge
                Text("\(Int(viewModel.previewConfidence * 100))%")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.15))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(4)
                
                // Operation badge
                if viewModel.previewOperation != .evaluate {
                    Text(viewModel.previewOperation.rawValue.capitalized)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                
                Button(action: { viewModel.dismissPreview() }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            // Editable expression field
            HStack(spacing: 8) {
                TextField("Expression", text: $viewModel.previewExpression)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Button("Evaluate") {
                    viewModel.evaluate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if let variable = viewModel.previewVariable {
                HStack {
                    Text("Variable: \(variable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
    }
    
    private var confidenceColor: Color {
        switch viewModel.previewConfidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var onUseExpression: ((String) -> Void)?
    var dismiss: DismissAction
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(.body, design: message.role == .assistant ? .monospaced : .default))
                    .textSelection(.enabled)
                    .padding(10)
                    .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                // Metrics display for assistant messages
                if message.role == .assistant, let metrics = message.metrics {
                    Text(metrics.summary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // "Use in Calculator" button for assistant messages with expressions
                if message.role == .assistant, let expr = message.translatedExpression {
                    Button("Use in Calculator") {
                        onUseExpression?(expr)
                        dismiss()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    AssistantView()
}

// MARK: - Quick Actions

enum QuickAction: String, CaseIterable {
    case solve = "Solve"
    case differentiate = "Differentiate"
    case integrate = "Integrate"
    case factor = "Factor"
    case limit = "Limit"
    case simplify = "Simplify"
    case clear = "Clear"
    
    var prefix: String {
        switch self {
        case .solve: return "solve "
        case .differentiate: return "differentiate "
        case .integrate: return "integrate "
        case .factor: return "factor "
        case .limit: return "limit of "
        case .simplify: return "simplify "
        case .clear: return ""
        }
    }
}
