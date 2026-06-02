// ScientificCalculator/PythonBridge/PythonServiceManager.swift

import Foundation
import Combine

/// Manages the lifecycle of the background Python SymPy service.
final class PythonServiceManager: ObservableObject {
    static let shared = PythonServiceManager()
    
    #if os(macOS)
    private var process: Any? // Use Any to hide Process from compiler if needed, but #if should work
    private var pipe: Any?
    #endif
    
    @Published var isRunning = false
    @Published var serviceOutput = ""
    
    private let port = 8001
    
    private init() {}
    
    private func discoverScriptPath() -> String? {
        #if os(macOS)
        if let bundlePath = Bundle.main.path(forResource: "SympyService", ofType: "py") {
            return bundlePath
        }
        let fileManager = FileManager.default
        if let execURL = Bundle.main.executableURL {
            var dir = execURL.deletingLastPathComponent()
            for _ in 0..<8 {
                let candidate = dir.appendingPathComponent("PythonBridge/SympyService.py").path
                if fileManager.fileExists(atPath: candidate) { return candidate }
                dir = dir.deletingLastPathComponent()
            }
        }
        #endif
        return nil
    }
    
    private func discoverUserSitePackages() -> String? {
        #if os(macOS)
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
        #else
        return nil
        #endif
    }
    
    func startService() {
        #if os(macOS)
        guard !isRunning else { return }
        guard let scriptPath = discoverScriptPath() else { return }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        proc.arguments = [scriptPath, "--port", "\(port)"]
        
        var env = ProcessInfo.processInfo.environment
        if let userSitePackages = discoverUserSitePackages() {
            if let existingPath = env["PYTHONPATH"] {
                env["PYTHONPATH"] = "\(existingPath):\(userSitePackages)"
            } else {
                env["PYTHONPATH"] = userSitePackages
            }
        }
        proc.environment = env
        
        let p = Pipe()
        proc.standardOutput = p
        proc.standardError = p
        
        self.pipe = p
        self.process = proc
        
        p.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                DispatchQueue.main.async {
                    self?.serviceOutput += str
                }
            }
        }
        
        do {
            try proc.run()
            self.isRunning = true
        } catch {
            print("PythonServiceManager: \(error)")
        }
        
        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
        #endif
    }
    
    func stopService() {
        #if os(macOS)
        if let proc = process as? Process, proc.isRunning {
            proc.terminate()
        }
        self.process = nil
        self.pipe = nil
        #endif
    }
}
