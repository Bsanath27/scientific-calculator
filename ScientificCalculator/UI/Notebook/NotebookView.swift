// UI/Notebook/NotebookView.swift
// Scientific Calculator - Main Notebook UI

import SwiftUI

struct NotebookView: View {
    @ObservedObject var viewModel: NotebookViewModel
    @ObservedObject var themeManager: ThemeManager
    
    @State private var showKeypad = false
    
    var body: some View {
        ZStack {
            themeManager.current.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(viewModel.selectedNotebook?.title ?? "Notebook")
                        .font(.headline)
                        .foregroundColor(themeManager.current.textPrimary)
                    Spacer()
                    Button(action: { viewModel.clearCurrentNotebook() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .help("Clear All Blocks")
                    
                    ThemeToggle(manager: themeManager)
                }
                .padding()
                .background(themeManager.current.surface.opacity(0.8))
                
                // Timeline
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.currentBlocks) { block in
                                BlockView(block: block, viewModel: viewModel, theme: themeManager)
                                    .id(block.id)
                            }
                        }
                        .padding()
                        .padding(.bottom, 60) // Space for input bar
                    }
                    .onChange(of: viewModel.currentBlocks.count) {
                        if let lastId = viewModel.currentBlocks.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Bar
                InputActionBar(
                    viewModel: viewModel,
                    theme: themeManager,
                    showKeypad: $showKeypad
                )
            }
            
            // Keypad Overlay / Drawer
            if showKeypad {
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: { showKeypad = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.title2)
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        
                        HStack(alignment: .top) {
                            ScientificKeypad(theme: themeManager, onKeyPress: { key in
                                viewModel.currentInput += key
                            })
                            .frame(maxWidth: 300)
                            
                            Divider()
                            
                            BasicKeypad(
                                theme: themeManager,
                                onKeyPress: { key in viewModel.currentInput += key },
                                onEvaluate: { viewModel.processInput() },
                                onClear: { viewModel.currentInput = "" },
                                onDelete: {
                                    if !viewModel.currentInput.isEmpty {
                                        viewModel.currentInput.removeLast()
                                    }
                                }
                            )
                        }
                        .padding()
                    }
                    .background(themeManager.current.surface)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom))
                }
                .zIndex(1) // Ensure above content
            }
        }
    }
}


// Minimal Theme Toggle
struct ThemeToggle: View {
    @ObservedObject var manager: ThemeManager
    
    var body: some View {
        Button(action: {
            withAnimation { manager.toggleTheme() }
        }) {
            Image(systemName: manager.isDarkMode ? "sun.max.fill" : "moon.fill")
                .foregroundColor(manager.current.accent)
        }
        .help("Toggle Theme")
    }
}
