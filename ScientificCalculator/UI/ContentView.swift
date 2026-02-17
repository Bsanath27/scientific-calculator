// UI/ContentView.swift
// Scientific Calculator - Main UI (Advanced Theming & Layout)

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notebookViewModel: NotebookViewModel
    
    @State private var showTools = false
    @State private var showOCR = false
    @State private var showAssistant = false
    @State private var showVariables = false
    @State private var showPhysics = false
    @State private var isScientificOpen = false // Drawer state
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header (Toolbar)
                    HStack {
                        Text("Scientific Calculator")
                            .font(.headline)
                            .foregroundColor(themeManager.current.textPrimary)
                        
                        Spacer()
                        
                        // Theme Toggle
                        Button(action: { themeManager.toggleTheme() }) {
                            Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(themeManager.current.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        // Feature Toggles
                        HStack(spacing: 12) {
                            ToolButton(icon: "atom", label: "Physics", action: { showPhysics = true }, theme: themeManager)
                            ToolButton(icon: "textformat.abc", label: "Variables", action: { showVariables = true }, theme: themeManager)
                            ToolButton(icon: "text.bubble", label: "Assistant", action: { showAssistant = true }, theme: themeManager)
                            ToolButton(icon: "doc.text.viewfinder", label: "OCR", action: { showOCR = true }, theme: themeManager)
                            ToolButton(icon: "wrench.and.screwdriver", label: "Tools", action: { showTools = true }, theme: themeManager)
                            
                            // Save to Notebook
                            Button(action: saveToNotebook) {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(themeManager.current.accent)
                            }
                            .help("Save to Notebook")
                        }
                    }
                    .padding()
                    .background(themeManager.current.displayBackground)
                    
                    // MARK: - Display Area
                    VStack(alignment: .trailing, spacing: 8) {
                        // History (Last entry)
                        if let last = viewModel.history.first {
                            Text(last.expression + " = " + last.result)
                                .font(.caption)
                                .foregroundColor(themeManager.current.textSecondary)
                                .lineLimit(1)
                                .padding(.horizontal)
                        } else {
                            Text(" ") // Spacer
                                .font(.caption)
                        }
                        
                        // Main Input with Parenthesis Highlighting
                        ExpressionInputView(
                            expression: $viewModel.expression,
                            onSubmit: { viewModel.evaluate() }
                        )
                        
                        // Result (Preview)
                        if !viewModel.result.isEmpty {
                            Text("= " + viewModel.result)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.current.accent)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                    .background(themeManager.current.displayBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(themeManager.current.divider),
                        alignment: .bottom
                    )
                    
                    // MARK: - Keypad Area
                    HStack(spacing: 0) {
                        // Scientific Drawer (Visible on large screens OR toggled)
                        if isScientificOpen || geometry.size.width > 600 {
                            ScientificKeypad(
                                theme: themeManager,
                                onKeyPress: { text in
                                    viewModel.expression += text
                                }
                            )
                            .transition(.move(edge: .leading))
                            .frame(maxWidth: 300)
                            
                            Divider()
                                .background(themeManager.current.divider)
                        }
                        
                        // Basic Keypad (Always Visible)
                        BasicKeypad(
                            theme: themeManager,
                            onKeyPress: { text in viewModel.handleInput(text) },
                            onEvaluate: { viewModel.evaluate() },
                            onClear: { viewModel.clear() },
                            onDelete: {
                                if !viewModel.expression.isEmpty {
                                    viewModel.expression.removeLast()
                                }
                            }
                        )
                    }
                    .frame(maxHeight: .infinity)
                }
                
                // Drawer Toggle (for small screens)
                if geometry.size.width <= 600 {
                    Button(action: { withAnimation { isScientificOpen.toggle() } }) {
                        Image(systemName: isScientificOpen ? "chevron.left" : "function")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(themeManager.current.accent)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    .position(x: 40, y: geometry.size.height - 40)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        // Sheets
        .sheet(isPresented: $showTools) { NumericToolsView() }
        .sheet(isPresented: $showOCR) {
            OCRView { expr in
                viewModel.expression = expr
                viewModel.evaluate()
            }
        }
        .sheet(isPresented: $showAssistant) {
            AssistantView { expr in
                viewModel.expression = expr
                viewModel.evaluate()
            }
        }
        .popover(isPresented: $showVariables) {
            VariablesPanel(viewModel: viewModel)
        }
        .sheet(isPresented: $showPhysics) {
            PhysicsReference { value in
                viewModel.insertText(value)
            }
        }
    }
    
    private func saveToNotebook() {
        guard !viewModel.expression.isEmpty else { return }
        
        let expr = viewModel.expression
        let res = viewModel.result
        
        let block: NotebookBlock
        if res.isEmpty || res.starts(with: "Error") {
            block = NotebookBlock(type: .text(content: expr))
        } else {
            block = NotebookBlock(type: .calculation(expression: expr, result: res))
        }
        
        notebookViewModel.addBlock(block)
    }
}

// Helper for toolbar buttons
struct ToolButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    let theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(theme.current.textSecondary)
            .padding(6)
            .background(theme.current.background)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

