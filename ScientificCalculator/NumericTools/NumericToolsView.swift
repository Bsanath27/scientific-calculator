// NumericTools/NumericToolsView.swift
// Scientific Calculator - Phase 3: Tabbed Numeric Tools Panel

import SwiftUI

/// Tool selection
enum NumericTool: String, CaseIterable {
    case matrix = "Matrix"
    case vector = "Vector"
    case stats = "Stats"
    case graph = "Graph"
    case units = "Units"
    case circuit = "Circuit"
    case logic = "Logic"
}

struct NumericToolsView: View {
    let toolId: String?
    @State private var selectedTool: NumericTool = .graph
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    init(toolId: String? = nil) {
        self.toolId = toolId
    }
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = DeviceLayout.isCompact(width: geo.size.width)
            
            if isCompact {
                iPhoneLayout(geo: geo)
            } else {
                iPadLayout(geo: geo)
            }
        }
        .background(themeManager.current.background)
        .onAppear {
            if let toolId = toolId {
                selectedTool = NumericTool(rawValue: toolId.capitalized) ?? .graph
            }
        }
    }
    
    // MARK: - iPhone Layout
    
    @ViewBuilder
    private func iPhoneLayout(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
                .padding()
            
            // Tool Picker (Chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NumericTool.allCases, id: \.self) { tool in
                        toolChip(tool)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            
            Divider().background(themeManager.current.divider)
            
            // Content
            toolContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Padding for iOS 18 Tab Bar
            Spacer()
                .frame(height: DeviceLayout.tabBarPadding(width: geo.size.width))
        }
    }
    
    // MARK: - iPad Layout
    
    @ViewBuilder
    private func iPadLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 20) {
                headerView
                    .padding(.bottom, 20)
                
                VStack(spacing: 8) {
                    ForEach(NumericTool.allCases, id: \.self) { tool in
                        sidebarItem(tool)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 250)
            .background(themeManager.current.surface.opacity(0.5))
            
            Divider().background(themeManager.current.divider)
            
            // Main Content
            toolContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.current.background.opacity(0.3))
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Numeric Lab")
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.current.textPrimary)
                Text("Interactive Solvers")
                    .font(.caption2)
                    .foregroundColor(themeManager.current.textSecondary)
            }
            Spacer()
            if DeviceLayout.isCompact(width: 400) { // Simplified check for close button
                 Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(themeManager.current.textSecondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func toolChip(_ tool: NumericTool) -> some View {
        Button(action: { selectedTool = tool }) {
            Text(tool.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTool == tool ? themeManager.current.accent : themeManager.current.displayBackground)
                .foregroundColor(selectedTool == tool ? .white : themeManager.current.textPrimary)
                .cornerRadius(20)
                .shadow(color: selectedTool == tool ? themeManager.current.accent.opacity(0.3) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func sidebarItem(_ tool: NumericTool) -> some View {
        Button(action: { selectedTool = tool }) {
            HStack {
                Image(systemName: toolIcon(tool))
                    .frame(width: 24)
                Text(tool.rawValue)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(selectedTool == tool ? themeManager.current.accent.opacity(0.15) : Color.clear)
            .foregroundColor(selectedTool == tool ? themeManager.current.accent : themeManager.current.textPrimary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var toolContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTool {
                case .matrix:
                    MatrixToolView()
                case .vector:
                    VectorToolView()
                case .stats:
                    StatsToolView()
                case .graph:
                    GraphToolView()
                case .units:
                    UnitsToolView()
                case .circuit:
                    CircuitToolView()
                case .logic:
                    LogicToolView()
                }
            }
            .padding()
        }
    }
    
    private func toolIcon(_ tool: NumericTool) -> String {
        switch tool {
        case .matrix: return "grid"
        case .vector: return "arrow.up.right"
        case .stats: return "chart.bar.fill"
        case .graph: return "chart.xyaxis.line"
        case .units: return "scalemass.fill"
        case .circuit: return "square.dashed"
        case .logic: return "cpu"
        }
    }
}

// MARK: - Preview

#Preview {
    NumericToolsView()
}
