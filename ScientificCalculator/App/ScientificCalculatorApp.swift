// App/ScientificCalculatorApp.swift
// Scientific Calculator - App Entry Point

import SwiftUI

@main
struct ScientificCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showQuickSolver = false
    
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 600, height: 700)
        .commands {
            CommandMenu("Solver") {
                Button("Quick Solver") {
                    showQuickSolver.toggle()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
        
        // Quick Solver popup window
        Window("Quick Solver", id: "quick-solver") {
            QuickSolverView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 400, height: 200)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App: Launching Python Service...")
        PythonServiceManager.shared.startService()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("App: Terminating Python Service...")
        PythonServiceManager.shared.stopService()
    }
}

