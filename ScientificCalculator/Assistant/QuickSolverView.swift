// Assistant/QuickSolverView.swift
// Scientific Calculator - Phase 5: Quick Popup Solver
// Minimal floating window for fast calculations. Triggered via ⌘⇧C.

import SwiftUI

struct QuickSolverView: View {
    @State private var input: String = ""
    @State private var result: String = ""
    @State private var translatedExpression: String = ""
    @State private var didTranslate: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private let dispatcher = Dispatcher()
    
    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Quick Solver")
                    .font(.headline)
                Spacer()
                Text("⌘⇧C")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Input
            TextField("Expression or question...", text: $input)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit { solve() }
            
            // Translation indicator
            if didTranslate && !translatedExpression.isEmpty {
                HStack {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(translatedExpression)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            
            // Result
            if !result.isEmpty {
                HStack {
                    Text("=")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(result)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                    Spacer()
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy result")
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(width: 400)
        .background(.ultraThinMaterial)
    }
    
    private func solve() {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Translate NL → expression
        let translation = NLTranslator.translate(input)
        didTranslate = translation.didTranslate
        translatedExpression = translation.expression
        
        // Evaluate
        let expr = translation.expression
        guard !expr.isEmpty else {
            result = "Could not parse"
            return
        }
        
        // Use symbolic mode for calculus/solve operations
        if translation.operation != .evaluate {
            dispatcher.mode = .symbolic
        }
        
        let report = dispatcher.evaluate(expression: expr)
        result = report.resultString
        
        dispatcher.mode = .numeric
    }
}

#Preview {
    QuickSolverView()
}
