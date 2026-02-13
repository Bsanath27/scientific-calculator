// PythonBridge/PythonClient.swift
// Scientific Calculator - HTTP Client for SymPy Service

import Foundation

/// Result from SymPy service
struct SymbolicResult {
    let result: String
    let latex: String
    let executionTimeMs: Double
}

/// Errors from Python service communication
enum PythonClientError: Error, LocalizedError {
    case invalidURL
    case serviceUnavailable
    case timeout
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid service URL"
        case .serviceUnavailable:
            return "Python service not running"
        case .timeout:
            return "Service timeout (>5s)"
        case .invalidResponse:
            return "Invalid response from service"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// HTTP client for SymPy Python service
class PythonClient {
    /// Default base URL for local Python SymPy service.
    /// This is created once and treated as a configuration constant; if the URL
    /// string is ever invalid, we fail fast at startup rather than crashing on
    /// user input later.
    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "http://127.0.0.1:5001") else {
            fatalError("Invalid default Python service URL")
        }
        return url
    }()
    
    private let baseURL: URL
    private let timeout: TimeInterval
    private let session: URLSession
    
    /// Initialize client with service URL
    /// - Parameters:
    ///   - baseURL: Base URL of Python service (default: http://127.0.0.1:5001)
    ///   - timeout: Request timeout in seconds (default: 30.0)
    init(baseURL: URL = PythonClient.defaultBaseURL, timeout: TimeInterval = 30.0) {
        self.baseURL = baseURL
        self.timeout = timeout
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Service Operations
    
    /// Simplify algebraic expression
    func simplify(_ expression: String) async throws -> SymbolicResult {
        return try await request(endpoint: "/simplify", expression: expression)
    }
    
    /// Solve equation
    func solve(_ expression: String, variable: String = "x") async throws -> SymbolicResult {
        return try await request(endpoint: "/solve", expression: expression, variable: variable)
    }
    
    /// Compute derivative
    func differentiate(_ expression: String, variable: String = "x") async throws -> SymbolicResult {
        return try await request(endpoint: "/differentiate", expression: expression, variable: variable)
    }
    
    /// Compute integral
    func integrate(_ expression: String, variable: String = "x") async throws -> SymbolicResult {
        return try await request(endpoint: "/integrate", expression: expression, variable: variable)
    }
    
    /// Evaluate symbolic expression
    func evaluate(_ expression: String) async throws -> SymbolicResult {
        return try await request(endpoint: "/evaluate", expression: expression)
    }
    
    /// Check if service is available
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
    
    // MARK: - Private Helpers
    
    /// Make HTTP POST request to endpoint
    private func request(endpoint: String, expression: String, variable: String? = nil) async throws -> SymbolicResult {
        guard let url = URL(string: "\(baseURL.absoluteString)\(endpoint)") else {
            throw PythonClientError.invalidURL
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        // Prepare body
        var body: [String: String] = ["expression": expression]
        if let variable = variable {
            body["variable"] = variable
        }
        
        #if DEBUG
        print("PythonClient: Sending request to \(endpoint) with body: \(body)")
        #endif
        
        request.httpBody = try? JSONEncoder().encode(body)
        
        // Execute request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PythonClientError.invalidResponse
            }
            
            // Handle HTTP errors
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMsg = errorData["error"] {
                    throw PythonClientError.serverError(errorMsg)
                }
                throw PythonClientError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // Parse response
            let result = try parseResponse(data)
            return result
            
        } catch is URLError {
            throw PythonClientError.serviceUnavailable
        } catch let error as PythonClientError {
            throw error
        } catch {
            throw PythonClientError.networkError(error)
        }
    }
    
    /// Parse JSON response from service
    private func parseResponse(_ data: Data) throws -> SymbolicResult {
        struct Response: Codable {
            let result: String
            let latex: String
            let execution_time_ms: Double
        }
        
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            return SymbolicResult(
                result: response.result,
                latex: response.latex,
                executionTimeMs: response.execution_time_ms
            )
        } catch {
            throw PythonClientError.invalidResponse
        }
    }
}
