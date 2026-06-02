// Engines/PDFExportEngine.swift
// Scientific Calculator - Workforce Report Generation

import Foundation
import PDFKit
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class PDFExportEngine {
    
    /// Generates a PDF document from workspace entries
    func generatePDF(entries: [WorkspaceEntry]) -> Data? {
        let pdfData = NSMutableData()
        
        // Define page size (Letter)
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil as CFDictionary?) else {
            return nil
        }
        
        context.beginPDFPage(nil as CFDictionary?)
        
        var currentY: CGFloat = pageHeight - 50 // Start from top (CoreGraphics is bottom-left origin)
        
        // Helper to draw text
        func drawText(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat, isBold: Bool = false) {
            let font: CTFont
            if isBold {
                font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
            } else {
                font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: CGColor(gray: 0.2, alpha: 1.0)
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            let path = CGPath(rect: CGRect(x: x, y: y, width: pageWidth - 100, height: fontSize * 1.5), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            
            CTFrameDraw(frame, context)
        }
        
        // Draw Header
        drawText("Physica Research Report", x: 50, y: currentY - 30, fontSize: 24, isBold: true)
        currentY -= 50
        
        drawText("Generated on: \(Date().formatted())", x: 50, y: currentY - 15, fontSize: 10)
        currentY -= 40
        
        // Draw Entries
        for entry in entries {
            if currentY < 100 {
                context.endPDFPage()
                context.beginPDFPage(nil as CFDictionary?)
                currentY = pageHeight - 50
            }
            
            // Entry Header
            drawText("\(entry.title) [\(entry.type.rawValue)]", x: 50, y: currentY - 20, fontSize: 14, isBold: true)
            currentY -= 20
            
            drawText("Module: \(entry.module) | \(entry.timestamp.formatted())", x: 50, y: currentY - 15, fontSize: 9)
            currentY -= 20
            
            // Content (Multi-line)
            let contentFont = CTFontCreateWithName("Courier" as CFString, 10, nil)
            let contentAttr: [NSAttributedString.Key: Any] = [.font: contentFont]
            let attributedContent = NSAttributedString(string: entry.content, attributes: contentAttr)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedContent)
            
            let targetSize = CGSize(width: pageWidth - 100, height: CGFloat.greatestFiniteMagnitude)
            let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, targetSize, nil)
            
            let contentRect = CGRect(x: 50, y: currentY - fitSize.height - 10, width: pageWidth - 100, height: fitSize.height + 5)
            let path = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            CTFrameDraw(frame, context)
            
            currentY -= fitSize.height + 30
            
            // Separator
            context.setStrokeColor(CGColor(gray: 0.8, alpha: 1.0))
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 50, y: currentY + 10))
            context.addLine(to: CGPoint(x: pageWidth - 50, y: currentY + 10))
            context.strokePath()
        }
        
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
}
