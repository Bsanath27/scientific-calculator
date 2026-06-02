import Foundation
#if canImport(UIKit)
import UIKit
public typealias NativeImage = UIImage
public typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias NativeImage = NSImage
public typealias NativeColor = NSColor
#endif
import PDFKit

/// Preprocesses images and PDFs for OCR recognition
struct OCRPreprocessor {
    
    /// Maximum image dimension for OCR (model works best with reasonable sizes)
    private static let maxDimension: CGFloat = 1024
    
    /// Prepare image data from NativeImage for OCR
    /// - Parameter image: Input NativeImage
    /// - Returns: PNG-encoded image data, resized if needed
    static func prepareImage(_ image: NativeImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #else
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
    
    /// Extract first page of PDF as image data for OCR
    /// - Parameter url: URL to PDF file
    /// - Returns: PNG-encoded image data of the first page
    static func extractPDFPage(_ url: URL) -> Data? {
        guard let document = PDFDocument(url: url) else { return nil }
        guard let page = document.page(at: 0) else { return nil }
        
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = min(maxDimension / bounds.width, maxDimension / bounds.height, 2.0)
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: bounds.width * scale, height: bounds.height * scale))
        let imgData = renderer.pngData { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: bounds.width * scale, height: bounds.height * scale))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return imgData
        #else
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let image = NativeImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current {
            NSColor.white.setFill()
            NSBezierPath.fill(NSRect(origin: .zero, size: size))
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        image.unlockFocus()
        return prepareImage(image)
        #endif
    }
    
    /// Load image from file URL (supports PNG, JPG, TIFF, PDF)
    /// - Parameter url: File URL
    /// - Returns: PNG-encoded image data ready for OCR
    static func loadFromFile(_ url: URL) -> Data? {
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" { return extractPDFPage(url) }
        
        #if canImport(UIKit)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        #else
        guard let image = NativeImage(contentsOf: url) else { return nil }
        #endif
        return prepareImage(image)
    }
    
    /// Extract image data from the system clipboard/pasteboard
    /// - Returns: PNG-encoded image data if found
    static func fromClipboard() -> Data? {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        guard let tiffData = pasteboard.data(forType: .tiff) else { return nil }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #elseif canImport(UIKit)
        guard let image = UIPasteboard.general.image else { return nil }
        return image.pngData()
        #else
        return nil
        #endif
    }
}
