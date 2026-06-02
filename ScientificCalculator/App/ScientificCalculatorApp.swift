// App/ScientificCalculatorApp.swift
// Scientific Calculator - App Entry Point

import SwiftUI

@main
struct ScientificCalculatorApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @StateObject private var keypadContext = KeypadContextEngine()
    @StateObject private var palette = QuickActionPaletteState()
    @StateObject private var variableStore = VariableStore.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notebookViewModel = NotebookViewModel()
    
    @State private var showQuickSolver = false
    
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environmentObject(keypadContext)
                .environmentObject(palette)
                .environmentObject(variableStore)
                .environmentObject(themeManager)
                .environmentObject(notebookViewModel)
        }
        #if os(macOS)
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 900)
        .commands {
            CommandMenu("Solver") {
                Button("Quick Solver") {
                    showQuickSolver.toggle()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
        #endif

        #if os(macOS)
        Window("Quick Solver", id: "quick-solver") {
            QuickSolverView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 400, height: 200)
        .windowResizability(.contentSize)
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupServices()
    }
    func applicationWillTerminate(_ notification: Notification) {
        PythonServiceManager.shared.stopService()
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupServices()
        return true
    }
}
#endif

private func setupServices() {
    print("App: Launching Python Service...")
    PythonServiceManager.shared.startService()
    
    print("App: Starting Local API Server...")
    LocalAPIServer.shared.start()
}
