// OCREngine/OCRPreprocessor.swift
// Scientific Calculator - Phase 4: Image Preprocessing for OCR
// Prepares images and PDFs before sending to OCR service.
// No math logic — image manipulation only.

import Foundation
import AppKit
import PDFKit

/// Preprocesses images and PDFs for OCR recognition
struct OCRPreprocessor {
    
    /// Maximum image dimension for OCR (model works best with reasonable sizes)
    private static let maxDimension: CGFloat = 1024
    
    /// Prepare image data from NSImage for OCR
    /// - Parameter image: Input NSImage
    /// - Returns: PNG-encoded image data, resized if needed
    static func prepareImage(_ image: NSImage) -> Data? {
        guard let resized = resizeIfNeeded(image) else { return nil }
        return pngData(from: resized)
    }
    
    /// Extract first page of PDF as image data for OCR
    /// - Parameter url: URL to PDF file
    /// - Returns: PNG-encoded image data of the first page
    static func extractPDFPage(_ url: URL) -> Data? {
        guard let document = PDFDocument(url: url) else { return nil }
        guard let page = document.page(at: 0) else { return nil }
        
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = min(maxDimension / bounds.width, maxDimension / bounds.height, 2.0)
        let size = NSSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
        
        let image = NSImage(size: size)
        image.lockFocus()
        
        if let context = NSGraphicsContext.current {
            // White background
            NSColor.white.setFill()
            NSBezierPath.fill(NSRect(origin: .zero, size: size))
            
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        image.unlockFocus()
        return pngData(from: image)
    }
    
    /// Load image from file URL (supports PNG, JPG, TIFF, PDF)
    /// - Parameter url: File URL
    /// - Returns: PNG-encoded image data ready for OCR
    static func loadFromFile(_ url: URL) -> Data? {
        let ext = url.pathExtension.lowercased()
        
        if ext == "pdf" {
            return extractPDFPage(url)
        }
        
        guard let image = NSImage(contentsOf: url) else { return nil }
        return prepareImage(image)
    }
    
    /// Get image from clipboard
    /// - Returns: PNG-encoded image data if clipboard contains an image
    static func fromClipboard() -> Data? {
        let pasteboard = NSPasteboard.general
        
        guard let image = NSImage(pasteboard: pasteboard) else { return nil }
        return prepareImage(image)
    }
    
    // MARK: - Private Helpers
    
    /// Resize image if it exceeds max dimensions
    private static func resizeIfNeeded(_ image: NSImage) -> NSImage? {
        let size = image.size
        
        // Check if resize needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate scale to fit within max dimensions
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = NSSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        
        return resized
    }
    
    /// Convert NSImage to PNG data
    private static func pngData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
