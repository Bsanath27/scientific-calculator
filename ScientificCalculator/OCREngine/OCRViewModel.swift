// OCREngine/OCRViewModel.swift
// Scientific Calculator - Phase 4: OCR State Management

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
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
    
    @Published var rawExpression: String = ""
    @Published var refinedExpression: String = ""
    @Published var useRefinedResult: Bool = true {
        didSet {
            recognizedExpression = useRefinedResult ? refinedExpression : rawExpression
        }
    }
    
    @Published var metricsText: String = ""
    @Published var selectedImage: NativeImage? = nil
    @Published var confidenceScore: Double = 0.0
    @Published var isServiceAvailable: Bool = false
    
    private let ocrClient = OCRClient()
    
    init() {
        checkServiceHealth()
    }
    
    func checkServiceHealth() {
        Task {
            let available = await ocrClient.healthCheck()
            await MainActor.run {
                self.isServiceAvailable = available
            }
        }
    }
    
    func importFile() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            loadFromFile(url)
        }
        #else
        print("Import file not yet implemented on iOS")
        #endif
    }
    
    func pasteFromClipboard() {
        guard let imageData = OCRPreprocessor.fromClipboard() else {
            state = .error("No image found in clipboard")
            return
        }
        selectedImage = NativeImage(data: imageData)
        recognizeImage(data: imageData)
    }
    
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
    
    func clear() {
        state = .idle
        recognizedExpression = ""
        rawLatex = ""
        metricsText = ""
        selectedImage = nil
        confidenceScore = 0.0
    }
    
    func verifyCurrentExpression() {
        guard !recognizedExpression.isEmpty else { return }
        let expressionToVerify = recognizedExpression
        state = .verifying
        Task {
            do {
                let isVerified = try await ocrClient.verifyEquation(expression: expressionToVerify)
                await MainActor.run { self.state = .verified(isVerified) }
            } catch {
                await MainActor.run { self.state = .error("Verification failed: \(error.localizedDescription)") }
            }
        }
    }
    
    // MARK: - Private
    
    private func loadFromFile(_ url: URL) {
        guard let imageData = OCRPreprocessor.loadFromFile(url) else {
            state = .error("Could not load file")
            return
        }
        if url.pathExtension.lowercased() == "pdf" {
            selectedImage = NativeImage(data: imageData)
        } else {
            #if canImport(AppKit)
            selectedImage = NativeImage(contentsOf: url)
            #else
            selectedImage = NativeImage(contentsOfFile: url.path)
            #endif
        }
        recognizeImage(data: imageData)
    }
    
    private func recognizeImage(data: Data) {
        state = .loading
        let start = CFAbsoluteTimeGetCurrent()
        Task {
            do {
                let result = try await ocrClient.recognize(imageData: data)
                let normalized = result.validated ? (result.canonicalExpression ?? "") : LatexNormalizer.normalize(result.latex)
                let totalTime = (CFAbsoluteTimeGetCurrent() - start) * 1000
                
                await MainActor.run {
                    self.rawLatex = result.latex
                    self.rawExpression = result.rawExpression ?? normalized
                    self.refinedExpression = result.refinedExpression ?? normalized
                    self.recognizedExpression = self.useRefinedResult ? self.refinedExpression : self.rawExpression
                    self.confidenceScore = result.confidence
                    self.state = .recognized(self.recognizedExpression)
                }
            } catch {
                await MainActor.run { self.state = .error(error.localizedDescription) }
            }
        }
    }
}
