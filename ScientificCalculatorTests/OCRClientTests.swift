// ScientificCalculatorTests/OCRClientTests.swift
// Scientific Calculator - Phase 4: OCR Client Unit Tests

import XCTest
@testable import ScientificCalculator

final class OCRClientTests: XCTestCase {
    
    // MARK: - Error Descriptions
    
    func testErrorDescriptions() {
        let errors: [(OCRClientError, String)] = [
            (.serviceUnavailable, "OCR service not running"),
            (.timeout, "timeout"),
            (.noEquationFound, "No equation detected"),
            (.invalidImageData, "Could not encode"),
            (.invalidURL, "Invalid OCR service URL"),
            (.invalidResponse, "Invalid response"),
        ]
        
        for (error, substring) in errors {
            guard let desc = error.errorDescription else {
                XCTFail("Error \(error) should have a description")
                continue
            }
            XCTAssertTrue(
                desc.contains(substring),
                "'\(desc)' should contain '\(substring)'"
            )
        }
    }
    
    func testLowConfidenceError() {
        let error = OCRClientError.lowConfidence(0.25)
        guard let desc = error.errorDescription else {
            XCTFail("Should have description")
            return
        }
        XCTAssertTrue(desc.contains("25%"), "Should show percentage: \(desc)")
    }
    
    func testServerErrorDescription() {
        let error = OCRClientError.serverError("Model not loaded")
        guard let desc = error.errorDescription else {
            XCTFail("Should have description")
            return
        }
        XCTAssertTrue(desc.contains("Model not loaded"))
    }
    
    // MARK: - Health Check (offline)
    
    func testHealthCheckOffline() async {
        // Use a port that definitely isn't running
        let client = OCRClient(
            baseURL: URL(string: "http://127.0.0.1:59999")!,
            timeout: 1.0
        )
        let available = await client.healthCheck()
        XCTAssertFalse(available, "Health check should fail for unreachable service")
    }
    
    // MARK: - OCR Result
    
    func testOCRResultProperties() {
        let result = OCRResult(
            expression: "x^2 + 1",
            latex: "x^{2} + 1",
            confidence: 0.92,
            processingTimeMs: 150.5
        )
        
        XCTAssertEqual(result.expression, "x^2 + 1")
        XCTAssertEqual(result.latex, "x^{2} + 1")
        XCTAssertEqual(result.confidence, 0.92, accuracy: 0.001)
        XCTAssertEqual(result.processingTimeMs, 150.5, accuracy: 0.1)
    }
    
    // MARK: - OCR Metrics
    
    func testOCRMetricsDisplay() {
        let metrics = OCRMetrics(
            ocrTimeMs: 250.0,
            imageSize: 50000,
            confidenceScore: 0.85,
            normalizeTimeMs: 0.5,
            parseTimeMs: 0.1,
            evalTimeMs: 0.05,
            totalTimeMs: 251.0
        )
        
        let display = metrics.displayString
        XCTAssertTrue(display.contains("250.0"), "Should show OCR time")
        XCTAssertTrue(display.contains("85%"), "Should show confidence")
        XCTAssertTrue(display.contains("50000"), "Should show image size")
    }
    
    func testOCRMetricsConsoleDescription() {
        let metrics = OCRMetrics(
            ocrTimeMs: 100.0,
            imageSize: 30000,
            confidenceScore: 0.95,
            normalizeTimeMs: 0.2,
            parseTimeMs: 0.1,
            evalTimeMs: 0.03,
            totalTimeMs: 100.5
        )
        
        let desc = metrics.consoleDescription
        XCTAssertTrue(desc.contains("OCR Pipeline Metrics"))
        XCTAssertTrue(desc.contains("100.0"))
        XCTAssertTrue(desc.contains("95%"))
    }
}
