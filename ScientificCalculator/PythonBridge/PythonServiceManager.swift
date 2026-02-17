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
    
    private init() {}
    
    /// Discover the Python script path dynamically (Bundle first, then project root)
    private func discoverScriptPath() -> String? {
        // 1. Check Bundle (Production / archived app)
        if let bundlePath = Bundle.main.path(forResource: "SympyService", ofType: "py") {
            return bundlePath
        }
        
        // 2. Dev mode: walk up from bundle to find project root
        // In Xcode dev builds, Bundle.main is inside DerivedData.
        // We look for PythonBridge/SympyService.py relative to common project roots.
        let fileManager = FileManager.default
        
        // Try SOURCE_ROOT from build settings if available
        if let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] {
            let candidate = "\(sourceRoot)/PythonBridge/SympyService.py"
            if fileManager.fileExists(atPath: candidate) { return candidate }
        }
        
        // Try current working directory
        let cwdCandidate = fileManager.currentDirectoryPath + "/PythonBridge/SympyService.py"
        if fileManager.fileExists(atPath: cwdCandidate) { return cwdCandidate }
        
        // Try executable path parent directories
        if let execURL = Bundle.main.executableURL {
            var dir = execURL.deletingLastPathComponent()
            for _ in 0..<8 { // Walk up max 8 levels
                let candidate = dir.appendingPathComponent("PythonBridge/SympyService.py").path
                if fileManager.fileExists(atPath: candidate) { return candidate }
                dir = dir.deletingLastPathComponent()
            }
        }
        
        return nil
    }
    
    /// Discover user site-packages dynamically via python3
    private func discoverUserSitePackages() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-m", "site", "--user-site"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    /// Start the Python service if not already running
    func startService() {
        guard !isRunning else { return }
        
        guard let scriptPath = discoverScriptPath() else {
            print("PythonServiceManager: SympyService.py not found in Bundle or project directory")
            return
        }
        
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            print("PythonServiceManager: Script not found at \(scriptPath)")
            return
        }
        
        print("PythonServiceManager: Starting service at \(scriptPath) on port \(port)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath, "--port", "\(port)"]
        
        // Dynamically discover user site-packages for Flask/SymPy
        var env = ProcessInfo.processInfo.environment
        if let userSitePackages = discoverUserSitePackages() {
            if let existingPath = env["PYTHONPATH"] {
                env["PYTHONPATH"] = "\(existingPath):\(userSitePackages)"
            } else {
                env["PYTHONPATH"] = userSitePackages
            }
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
