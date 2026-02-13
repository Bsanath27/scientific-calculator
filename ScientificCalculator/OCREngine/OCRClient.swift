// OCREngine/OCRClient.swift
// Scientific Calculator - Phase 4: OCR HTTP Client
// Communicates with Python OCR service for equation recognition.
// OCR is input only — returns text/LaTeX, never evaluates.

import Foundation

/// Result from OCR recognition
struct OCRResult {
    let expression: String
    let latex: String
    let confidence: Double
    let processingTimeMs: Double
    /// SymPy-standardized calculator expression (available when validated = true)
    let canonicalExpression: String?
    /// Whether SymPy successfully parsed and validated the LaTeX
    let validated: Bool
}

/// Errors from OCR service communication
enum OCRClientError: Error, LocalizedError {
    case invalidURL
    case serviceUnavailable
    case timeout
    case invalidResponse
    case noEquationFound
    case lowConfidence(Double)
    case serverError(String)
    case networkError(Error)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OCR service URL"
        case .serviceUnavailable:
            return "OCR service not running (start PythonOCR/ocr_service.py)"
        case .timeout:
            return "OCR recognition timeout (>10s)"
        case .invalidResponse:
            return "Invalid response from OCR service"
        case .noEquationFound:
            return "No equation detected in image"
        case .lowConfidence(let score):
            return String(format: "Low confidence recognition (%.0f%%)", score * 100)
        case .serverError(let msg):
            return "OCR error: \(msg)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidImageData:
            return "Could not encode image data"
        }
    }
}

/// HTTP client for Python OCR service
class OCRClient {
    /// Default base URL for local OCR service.
    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "http://127.0.0.1:5002") else {
            fatalError("Invalid default OCR service URL")
        }
        return url
    }()
    
    private let baseURL: URL
    private let timeout: TimeInterval
    private let session: URLSession
    
    /// Minimum confidence threshold for accepting results
    private let confidenceThreshold: Double = 0.4
    
    /// Initialize with OCR service URL
    init(baseURL: URL = OCRClient.defaultBaseURL, timeout: TimeInterval = 10.0) {
        self.baseURL = baseURL
        self.timeout = timeout
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Recognition
    
    /// Recognize equation from image data
    /// Returns LaTeX/text expression — never evaluates math
    func recognize(imageData: Data) async throws -> OCRResult {
        guard let url = URL(string: "\(baseURL.absoluteString)/recognize") else {
            throw OCRClientError.invalidURL
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        // Encode image as base64
        let base64Image = imageData.base64EncodedString()
        let body: [String: String] = ["image": base64Image]
        
        #if DEBUG
        print("OCRClient: Sending recognition request (\(imageData.count) bytes)")
        #endif
        
        request.httpBody = try? JSONEncoder().encode(body)
        
        // Execute request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OCRClientError.invalidResponse
            }
            
            // Handle HTTP errors
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMsg = errorData["error"] {
                    if errorMsg.contains("No equation") {
                        throw OCRClientError.noEquationFound
                    }
                    throw OCRClientError.serverError(errorMsg)
                }
                throw OCRClientError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // Parse response
            let result = try parseResponse(data)
            
            // Check confidence
            if result.confidence < confidenceThreshold {
                throw OCRClientError.lowConfidence(result.confidence)
            }
            
            return result
            
        } catch is URLError {
            throw OCRClientError.serviceUnavailable
        } catch let error as OCRClientError {
            throw error
        } catch {
            throw OCRClientError.networkError(error)
        }
    }
    
    /// Check if OCR service is available
    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL.absoluteString)/health") else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// Verify if an equation satisfies a mathematical identity (LHS - RHS = 0)
    /// - Parameter expression: The equation expression (e.g. "sin(x)^2 + cos(x)^2 - 1")
    /// - Returns: True if the identity holds (simplifies to 0)
    func verifyEquation(expression: String) async throws -> Bool {
        // Use SymPy service for verification (port 5001)
        guard let verifyURL = URL(string: "http://127.0.0.1:5001/verify") else {
            throw OCRClientError.invalidURL
        }
        
        // Prepare request
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        let body: [String: String] = ["expression": expression]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw OCRClientError.serverError("Verification failed")
            }
            
            struct VerifyResponse: Codable {
                let verified: Bool
                let result: String
            }
            
            let result = try JSONDecoder().decode(VerifyResponse.self, from: data)
            return result.verified
            
        } catch {
            throw OCRClientError.networkError(error)
        }
    }
    
    // MARK: - Private
    
    private func parseResponse(_ data: Data) throws -> OCRResult {
        struct Response: Codable {
            let expression: String
            let latex: String
            let confidence: Double
            let processing_time_ms: Double
            let canonical_expression: String?
            let validated: Bool?
        }
        
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            return OCRResult(
                expression: response.expression,
                latex: response.latex,
                confidence: response.confidence,
                processingTimeMs: response.processing_time_ms,
                canonicalExpression: response.canonical_expression,
                validated: response.validated ?? false
            )
        } catch {
            throw OCRClientError.invalidResponse
        }
    }
}
