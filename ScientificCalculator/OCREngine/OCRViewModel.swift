// OCREngine/OCRViewModel.swift
// Scientific Calculator - Phase 4: OCR State Management
// Manages the OCR pipeline: image → recognition → normalization → expression.
// Never evaluates math — only produces expression text for the existing pipeline.

import Foundation
import AppKit
import Combine

/// OCR pipeline states
enum OCRState: Equatable {
    case idle
    case loading
    case recognized(String)
    case verifying
    case verified(Bool)
    case error(String)
    
    static func == (lhs: OCRState, rhs: OCRState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.verifying, .verifying): return true
        case (.recognized(let a), .recognized(let b)): return a == b
        case (.verified(let a), .verified(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// ViewModel for OCR recognition pipeline
final class OCRViewModel: ObservableObject {
    @Published var state: OCRState = .idle
    @Published var recognizedExpression: String = ""
    @Published var rawLatex: String = ""
    @Published var metricsText: String = ""
    @Published var selectedImage: NSImage? = nil
    @Published var confidenceScore: Double = 0.0
    @Published var isServiceAvailable: Bool = false
    
    private let ocrClient = OCRClient()
    
    init() {
        checkServiceHealth()
    }
    
    /// Check if OCR service is running
    func checkServiceHealth() {
        Task {
            let available = await ocrClient.healthCheck()
            await MainActor.run {
                self.isServiceAvailable = available
            }
        }
    }
    
    /// Open file picker for image/PDF import
    func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .png, .jpeg, .tiff, .pdf
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an image or PDF containing a math equation"
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFromFile(url)
        }
    }
    
    /// Paste image from clipboard
    func pasteFromClipboard() {
        guard let imageData = OCRPreprocessor.fromClipboard() else {
            state = .error("No image found in clipboard")
            return
        }
        
        let image = NSImage(data: imageData)
        selectedImage = image
        recognizeImage(data: imageData)
    }
    
    /// Recognize equation from currently loaded image
    func recognizeCurrentImage() {
        guard let image = selectedImage else {
            state = .error("No image loaded")
            return
        }
        
        guard let imageData = OCRPreprocessor.prepareImage(image) else {
            state = .error("Could not process image")
            return
        }
        
        recognizeImage(data: imageData)
    }
    
    /// Clear all state
    func clear() {
        state = .idle
        recognizedExpression = ""
        rawLatex = ""
        metricsText = ""
        selectedImage = nil
        confidenceScore = 0.0
    }
    
    /// Verify the current expression as a mathematical identity
    func verifyCurrentExpression() {
        guard !recognizedExpression.isEmpty else { return }
        
        let expressionToVerify = recognizedExpression
        state = .verifying
        
        Task {
            do {
                let isVerified = try await ocrClient.verifyEquation(expression: expressionToVerify)
                await MainActor.run {
                    self.state = .verified(isVerified)
                }
            } catch {
                await MainActor.run {
                    // Revert to recognized state but show error? 
                    // Or just show error state.
                    self.state = .error("Verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func loadFromFile(_ url: URL) {
        guard let imageData = OCRPreprocessor.loadFromFile(url) else {
            state = .error("Could not load file: \(url.lastPathComponent)")
            return
        }
        
        // Show image preview
        if url.pathExtension.lowercased() == "pdf" {
            selectedImage = NSImage(data: imageData)
        } else {
            selectedImage = NSImage(contentsOf: url)
        }
        
        recognizeImage(data: imageData)
    }
    
    private func recognizeImage(data: Data) {
        state = .loading
        let pipelineStart = CFAbsoluteTimeGetCurrent()
        let imageSize = data.count
        
        Task {
            do {
                // Step 1: OCR Recognition (on Python service)
                let ocrResult = try await ocrClient.recognize(imageData: data)
                
                // Step 2: Get expression — prefer SymPy-validated canonical form
                let normalizeStart = CFAbsoluteTimeGetCurrent()
                let normalized: String
                if ocrResult.validated, let canonical = ocrResult.canonicalExpression, !canonical.isEmpty {
                    // SymPy validated — use canonical expression directly
                    normalized = canonical
                    #if DEBUG
                    print("OCR: Using SymPy-validated canonical expression: \(canonical)")
                    #endif
                } else {
                    // Fallback to regex-based normalizer
                    normalized = LatexNormalizer.normalize(ocrResult.latex)
                    #if DEBUG
                    print("OCR: SymPy validation failed, using LatexNormalizer fallback")
                    #endif
                }
                let normalizeTimeMs = (CFAbsoluteTimeGetCurrent() - normalizeStart) * 1000
                
                let totalTimeMs = (CFAbsoluteTimeGetCurrent() - pipelineStart) * 1000
                
                // Build metrics
                let metrics = OCRMetrics(
                    ocrTimeMs: ocrResult.processingTimeMs,
                    imageSize: imageSize,
                    confidenceScore: ocrResult.confidence,
                    normalizeTimeMs: normalizeTimeMs,
                    parseTimeMs: 0,  // Filled when user evaluates
                    evalTimeMs: 0,
                    totalTimeMs: totalTimeMs
                )
                
                await MainActor.run {
                    self.rawLatex = ocrResult.latex
                    self.recognizedExpression = normalized
                    self.confidenceScore = ocrResult.confidence
                    self.metricsText = metrics.displayString
                    self.state = .recognized(normalized)
                    
                    #if DEBUG
                    print(metrics.consoleDescription)
                    #endif
                }
                
            } catch let error as OCRClientError {
                await MainActor.run {
                    self.state = .error(error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    self.state = .error("OCR failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
