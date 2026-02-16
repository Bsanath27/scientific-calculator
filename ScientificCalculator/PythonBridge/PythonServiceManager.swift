// ScientificCalculator/PythonBridge/PythonServiceManager.swift

import Foundation
import Combine

/// Manages the lifecycle of the background Python SymPy service.
final class PythonServiceManager: ObservableObject {
    static let shared = PythonServiceManager()
    
    private var process: Process?
    private var pipe: Pipe?
    
    @Published var isRunning = false
    @Published var serviceOutput = ""
    
    private let port = 8001
    
    // Dev path fallback since files might not be in Bundle during dev
    private let devScriptPath = "/Users/sanathbs/03_Dev_Lab/scientific-calculator/PythonBridge/SympyService.py"
    
    private init() {}
    
    /// Start the Python service if not already running
    func startService() {
        guard !isRunning else { return }
        
        // 1. Check if port is already in use (simplistic check, or just try to start)
        // For now, we'll assume if we aren't tracking a process, we should try to start one.
        // In a real app, we might check `lsof` or try to connect to the port first.
        
        let scriptPath: String
        
        // Check Bundle first (Production)
        if let bundlePath = Bundle.main.path(forResource: "SympyService", ofType: "py") {
            scriptPath = bundlePath
        } else {
            // Fallback to Dev Path
            scriptPath = devScriptPath
        }
        
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            print("PythonServiceManager: Script not found at \(scriptPath)")
            return
        }
        
        print("PythonServiceManager: Starting service at \(scriptPath) on port \(port)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3") // Use system python or bundled
        process.arguments = [scriptPath, "--port", "\(port)"]
        
        // 2. Set Environment Variables
        // Important: When running in Xcode (even Sandbox), we need to help it find user-installed packages
        // like Flask and SymPy which are likely in ~/Library/Python/3.9/lib/python/site-packages
        var env = ProcessInfo.processInfo.environment
        let userSitePackages = "/Users/sanathbs/Library/Python/3.9/lib/python/site-packages"
        if let existingPath = env["PYTHONPATH"] {
            env["PYTHONPATH"] = "\(existingPath):\(userSitePackages)"
        } else {
            env["PYTHONPATH"] = userSitePackages
        }
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        self.pipe = pipe
        self.process = process
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                DispatchQueue.main.async {
                    self?.serviceOutput += str
                    // print("PythonService: \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
        
        do {
            try process.run()
            self.isRunning = true
            print("PythonServiceManager: Service started with PID \(process.processIdentifier)")
        } catch {
            print("PythonServiceManager: Failed to launch process: \(error)")
        }
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                print("PythonServiceManager: Service terminated")
            }
        }
    }
    
    /// Stop the background service
    func stopService() {
        guard let process = process, process.isRunning else { return }
        print("PythonServiceManager: Stopping service...")
        process.terminate()
        self.process = nil
        self.pipe = nil
    }
}
