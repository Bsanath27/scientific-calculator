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

// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(CustomRoundedCorner(radius: radius, corners: corners))
    }
}

struct CustomRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.size.width
        let h = rect.size.height
        let r = radius
        
        // Start top left
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        
        // Top Right
        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: w, y: 0))
        }
        
        // Bottom Right
        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: w, y: h - r))
            path.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: w, y: h))
        }
        
        // Bottom Left
        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: r, y: h))
            path.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: h))
        }
        
        // Top Left
        if corners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        return path
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
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
