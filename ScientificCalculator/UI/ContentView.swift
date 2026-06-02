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
    @State private var showHistory = false
    
    @EnvironmentObject var keypadContext: KeypadContextEngine
    @EnvironmentObject var palette: QuickActionPaletteState
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = DeviceLayout.isCompact(width: geometry.size.width)
            
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Display Area (Prompt 6: Multi-line, Tokenized)
                    VStack(alignment: .trailing, spacing: 0) {
                        ExpressionInputView(
                            expression: $viewModel.expression,
                            onSubmit: { viewModel.evaluate() },
                            viewModel: viewModel
                        )
                        .padding(.top, 10)
                    }
                    .background(themeManager.current.displayBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(themeManager.current.divider),
                        alignment: .bottom
                    )
                    
                    // MARK: - Keypad Area
                    ZStack(alignment: .leading) {
                        if !isCompact {
                            // iPad: Side-by-side Scientific + Basic
                            HStack(spacing: 0) {
                                ScientificKeypad(
                                    theme: themeManager,
                                    onKeyPress: { text in viewModel.handleInput(text) }
                                )
                                .frame(width: geometry.size.width * 0.45)
                                
                                Divider()
                                    .background(themeManager.current.divider)
                                
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
                        } else {
                            // iPhone: Basic Keypad + Drawer for Scientific
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
                            .blur(radius: isScientificOpen ? 3 : 0)
                            
                            if isScientificOpen {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                    .onTapGesture { withAnimation { isScientificOpen = false } }
                                    .transition(.opacity)
                                
                                ScientificKeypad(
                                    theme: themeManager,
                                    onKeyPress: { text in viewModel.handleInput(text) }
                                )
                                .frame(width: geometry.size.width * 0.85)
                                .background(themeManager.current.background)
                                .cornerRadius(16, corners: [.topRight, .bottomRight])
                                .shadow(radius: 10)
                                .transition(.move(edge: .leading))
                                .zIndex(1)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Bottom Padding for Floating Tab Bar (Prompt 5 fix)
                    if isCompact {
                        Spacer()
                            .frame(height: DeviceLayout.tabBarPadding(width: geometry.size.width))
                    }
                }
                
                // MARK: - Floating Action Buttons (Prompt 6)
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Ask Physica
                    FloatingActionButton(icon: "sparkles.bubble.fill", label: "Ask Physica", color: themeManager.current.opticsGreen) {
                        showAssistant = true
                    }
                    
                    // OCR
                    FloatingActionButton(icon: "camera.viewfinder", label: "OCR Scan", color: themeManager.current.mechanicsBlue) {
                        showOCR = true
                    }
                    
                    // Save to Workspace
                    FloatingActionButton(icon: "arrow.down.doc.fill", label: "Save", color: themeManager.current.accent) {
                        saveToNotebook()
                    }
                    
                    // Scientific Toggle (iPhone only)
                    if isCompact {
                        Button(action: { withAnimation { isScientificOpen.toggle() } }) {
                            Image(systemName: isScientificOpen ? "xmark" : "function")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(themeManager.current.accent)
                                .clipShape(Circle())
                                .shadow(color: themeManager.current.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, isCompact ? DeviceLayout.tabBarPadding(width: geometry.size.width) + 20 : 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .animation(.spring(), value: showHistory)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onChange(of: viewModel.expression) { _, newVal in
            keypadContext.update(expression: newVal)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InsertExpression"))) { note in
            if let expr = note.object as? String {
                viewModel.insertText(expr)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SelectPhysicsScenario"))) { _ in
            // When a scenario is selected, we might want to close sheets or triggers
            showPhysics = false
        }
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
            PhysicsReference()
        }
    }
}

extension ContentView {
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
    var compact: Bool = false
    let action: () -> Void
    let theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 1 : 2) {
                Image(systemName: icon)
                    .font(.system(size: compact ? 14 : 16))
                if !compact {
                    Text(label)
                        .font(.caption2)
                }
            }
            .foregroundColor(theme.current.textSecondary)
            .padding(compact ? 4 : 6)
            .background(theme.current.background)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Prompt 6: Components

struct FloatingActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        HStack(spacing: 8) {
            if isExpanded {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            Button(action: {
                action()
                // Auto-collapse after action
                withAnimation { isExpanded = false }
            }) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
        .padding(4)
        .background(isExpanded ? color.opacity(0.8) : Color.clear)
        .cornerRadius(28)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isExpanded = hovering
            }
        }
        // Handle touch-based expansion if on iOS
        .onLongPressGesture(minimumDuration: 0.1) {
            withAnimation { isExpanded.toggle() }
        }
    }
}

#Preview {
    ContentView()
}

