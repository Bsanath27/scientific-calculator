// OCREngine/OCRView.swift
// Scientific Calculator - Phase 4: OCR UI
// Minimal, functional UI for equation recognition.
// Image import → OCR → preview expression → edit → evaluate.

import SwiftUI
import UniformTypeIdentifiers

struct OCRView: View {
    @StateObject private var viewModel = OCRViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// Callback to send recognized expression to calculator
    var onExpressionRecognized: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("OCR Equation Scanner")
                    .font(.headline)
                Spacer()
                
                // Service status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isServiceAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isServiceAvailable ? "Service Online" : "Service Offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Input Section
            GroupBox("Import Equation") {
                HStack(spacing: 12) {
                    Button("Import Image/PDF") {
                        viewModel.importFile()
                    }
                    
                    Button("Paste from Clipboard") {
                        viewModel.pasteFromClipboard()
                    }
                    
                    Spacer()
                    
                    if viewModel.selectedImage != nil {
                        Button("Clear") {
                            viewModel.clear()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Image Preview
            if let image = viewModel.selectedImage {
                GroupBox("Image Preview") {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(4)
                }
            }
            
            // Status / Loading
            switch viewModel.state {
            case .loading:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Recognizing equation...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
            default:
                EmptyView()
            }
            
            // Raw LaTeX (collapsible)
            if !viewModel.rawLatex.isEmpty {
                GroupBox("Raw LaTeX") {
                    Text(viewModel.rawLatex)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Recognized Expression (editable)
            if viewModel.state != .idle && viewModel.state != .loading {
                GroupBox("Expression") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Recognized expression", text: $viewModel.recognizedExpression)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                            
                            // Confidence badge
                            if viewModel.confidenceScore > 0 {
                                Text(String(format: "%.0f%%", viewModel.confidenceScore * 100))
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(confidenceColor.opacity(0.2))
                                    .foregroundColor(confidenceColor)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text("Edit the expression if OCR made errors, then evaluate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Action Buttons
            if !viewModel.recognizedExpression.isEmpty {
                HStack {
                    Button("Evaluate") {
                        let expression = viewModel.recognizedExpression
                        onExpressionRecognized?(expression)
                        dismiss()
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    
                    Button("Copy Expression") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(viewModel.recognizedExpression, forType: .string)
                    }
                }
            }
            
            // Metrics
            if !viewModel.metricsText.isEmpty {
                GroupBox("Metrics") {
                    Text(viewModel.metricsText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
            
            // Footer
            Text("Phase 4: OCR Equation Engine")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var confidenceColor: Color {
        if viewModel.confidenceScore >= 0.8 { return .green }
        if viewModel.confidenceScore >= 0.5 { return .orange }
        return .red
    }
}

#Preview {
    OCRView()
}
