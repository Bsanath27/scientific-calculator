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
            
            // Image Preview (with drag-and-drop)
            Group {
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
                } else {
                    // Drop zone when no image is loaded
                    GroupBox("Drop Equation Image Here") {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Drag and drop an image or PDF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                    }
                }
            }
            .onDrop(of: [.png, .jpeg, .tiff, .pdf, .fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers)
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
                
            case .verifying:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Verifying identity...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .verified(let isValid):
                HStack {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isValid ? .green : .red)
                    Text(isValid ? "Identity verified" : "Identity does not hold")
                        .font(.caption)
                        .foregroundColor(isValid ? .green : .red)
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
                GroupBox("Final Result") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Choice Picker
                        Picker("Interpretation Strategy", selection: $viewModel.useRefinedResult) {
                            Text("Refined").tag(true)
                            Text("Raw").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .help("Refined uses heuristics to fix OCR errors (like split variables). Raw stays closer to the exact visual result.")
                        
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
                        
                        Text("Choose the best interpretation, refine it if needed, and evaluate.")
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
                    
                    Button("Verify Identity") {
                        viewModel.verifyCurrentExpression()
                    }
                    .help("Check if the expression is a valid identity (simplifies to 0)")
                    
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
    
    // MARK: - Drag and Drop
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Try to load a file URL first (covers all file types)
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    let ext = url.pathExtension.lowercased()
                    guard ["png", "jpg", "jpeg", "tiff", "tif", "pdf"].contains(ext) else { return }
                    
                    DispatchQueue.main.async {
                        if let imageData = OCRPreprocessor.loadFromFile(url) {
                            viewModel.selectedImage = NSImage(contentsOf: url) ?? NSImage(data: imageData)
                            viewModel.recognizeCurrentImage()
                        }
                    }
                }
                return true
            }
        }
        
        // Try to load raw image data
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { image, _ in
                    guard let nsImage = image as? NSImage else { return }
                    DispatchQueue.main.async {
                        viewModel.selectedImage = nsImage
                        viewModel.recognizeCurrentImage()
                    }
                }
                return true
            }
        }
        
        return false
    }
}

#Preview {
    OCRView()
}
