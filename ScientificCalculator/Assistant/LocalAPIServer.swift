// Assistant/LocalAPIServer.swift
// Scientific Calculator - Phase 5: Local API Server for Browser Extension
// Provides a local HTTP endpoint (http://localhost:8765) to handle translation/evaluation requests.

import Foundation
import Network
import Combine

/// A simple HTTP server using Network.framework to listen for POST requests
final class LocalAPIServer: ObservableObject {
    static let shared = LocalAPIServer()
    
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 8765
    private let dispatcher = Dispatcher()
    
    @Published var isRunning = false
    @Published var lastRequest: String?
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        
        do {
            listener = try NWListener(using: .tcp, on: port)
        } catch {
            print("Server failed to create listener: \(error)")
            return
        }
        
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Server listening on port \(self.port)")
                self.isRunning = true
            case .failed(let error):
                print("Server failed with error: \(error)")
                self.isRunning = false
            case .cancelled:
                print("Server cancelled")
                self.isRunning = false
            default:
                break
            }
        }
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener?.start(queue: .global(qos: .userInitiated))
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        
        // Read headers first (simplified: assume it's small enough or just read chunk)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let data = data, !data.isEmpty, error == nil else {
                connection.cancel()
                return
            }
            
            self?.processRequest(data: data, connection: connection)
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        // Parse HTTP request - very basic implementation
        guard let requestString = String(data: data, encoding: .utf8) else {
            connection.cancel()
            return
        }
        
        // Check method and path (simplified)
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            connection.cancel()
            return
        }
        
        // Handle CORS Preflight
        if requestLine.contains("OPTIONS") {
            let response = "HTTP/1.1 200 OK\r\n" +
                           "Access-Control-Allow-Origin: *\r\n" +
                           "Access-Control-Allow-Methods: POST, OPTIONS\r\n" +
                           "Access-Control-Allow-Headers: Content-Type\r\n" +
                           "Content-Length: 0\r\n" +
                           "Connection: close\r\n\r\n"
            
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
            return
        }
        
        guard requestLine.contains("POST") else {
            // Only accept POST
            sendResponse(connection: connection, status: "405 Method Not Allowed", body: "Only POST allowed")
            return
        }
        
        // Find body - split by double CRLF
        let parts = requestString.components(separatedBy: "\r\n\r\n")
        guard parts.count > 1, let bodyString = parts.last else {
            sendResponse(connection: connection, status: "400 Bad Request", body: "Missing body")
            return
        }
        
        // Parse JSON
        guard let bodyData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let text = json["text"] as? String else {
            sendResponse(connection: connection, status: "400 Bad Request", body: "Invalid JSON")
            return
        }
        
        DispatchQueue.main.async {
            self.lastRequest = text
        }
        
        // Translate & Evaluate
        let translation = NLTranslator.translate(text)
        
        // If translation failed effectively (empty expression), error out
        if translation.expression.isEmpty {
             let response: [String: Any] = [
                "success": false,
                "error": "Could not translate text"
            ]
            sendJSONResponse(connection: connection, json: response)
            return
        }
        
        // Evaluate
        if translation.operation != .evaluate {
            dispatcher.mode = .symbolic
        }
        
        let report = dispatcher.evaluate(expression: translation.expression)
        dispatcher.mode = .numeric
        
        // Sanitize result (remove LaTeX/extra info)
        let resultLines = report.resultString.components(separatedBy: "\n")
        let cleanResult = resultLines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? report.resultString
        
        let response: [String: Any] = [
            "success": true,
            "expression": translation.expression,
            "result": cleanResult,
            "operation": translation.operation.rawValue,
            "confidence": AssistantMetrics.confidence(for: translation)
        ]
        
        sendJSONResponse(connection: connection, json: response)
    }
    
    private func sendResponse(connection: NWConnection, status: String, body: String) {
        let response = "HTTP/1.1 \(status)\r\n" +
                       "Content-Length: \(body.utf8.count)\r\n" +
                       "Access-Control-Allow-Origin: *\r\n" +
                       "Connection: close\r\n\r\n" +
                       body
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func sendJSONResponse(connection: NWConnection, json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: "500 Internal Server Error", body: "JSON encoding failed")
            return
        }
        
        let response = "HTTP/1.1 200 OK\r\n" +
                       "Content-Type: application/json\r\n" +
                       "Content-Length: \(data.count)\r\n" +
                       "Access-Control-Allow-Origin: *\r\n" +
                       "Connection: close\r\n\r\n" +
                       jsonString
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
