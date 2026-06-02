// UI/Workspace/WorkspaceView.swift
import SwiftUI

struct WorkspaceView: View {
    @StateObject private var manager = WorkspaceManager.shared
    @EnvironmentObject var theme: ThemeManager
    @State private var showExport = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Research Workspace")
                            .font(.system(.title2, design: .serif))
                            .fontWeight(.bold)
                        Text("\(manager.entries.count) items in current session")
                            .font(.caption)
                            .foregroundColor(theme.current.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showExport = true }) {
                        Label("Export PDF", systemImage: "doc.badge.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(theme.current.accent)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(theme.current.displayBackground)
                
                Divider()
                    .background(theme.current.divider)
                
                // Timeline Content
                if manager.entries.isEmpty {
                    EmptyWorkspaceView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(manager.entries) { entry in
                                WorkspaceTimelineRow(entry: entry)
                                
                                // Timeline Connector Line
                                Rectangle()
                                    .fill(theme.current.divider.opacity(0.3))
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 34)
                            }
                        }
                        .padding()
                    }
                }
                
                // Bottom Padding
                Spacer()
                    .frame(height: DeviceLayout.tabBarPadding(width: geo.size.width))
            }
        }
        .background(theme.current.background)
        .sheet(isPresented: $showExport) {
            PDFExportPreview(content: manager.generateReport())
        }
    }
}

struct WorkspaceTimelineRow: View {
    let entry: WorkspaceEntry
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Iconic Timeline Pin
            ZStack {
                Circle()
                    .fill(theme.current.accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconFor(entry.type))
                    .font(.caption)
                    .foregroundColor(theme.current.accent)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.title)
                        .font(.headline)
                        .foregroundColor(theme.current.textPrimary)
                    
                    Spacer()
                    
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(theme.current.textSecondary)
                }
                
                // Rich Snippet Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.content)
                        .font(.system(.subheadline, design: .monospaced))
                        .lineLimit(3)
                        .foregroundColor(theme.current.textSecondary)
                    
                    if let mod = entry.metadata?["module"] {
                        Text(mod.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.current.accent.opacity(0.15))
                            .foregroundColor(theme.current.accent)
                            .cornerRadius(4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.current.displayBackground.opacity(0.5))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.current.divider, lineWidth: 1))
            }
        }
    }
    
    private func iconFor(_ type: WorkspaceEntryType) -> String {
        switch type {
        case .calculation: return "function"
        case .simulation: return "waveform.path"
        case .toolResult: return "hammer.fill"
        case .note: return "note.text"
        }
    }
}

struct EmptyWorkspaceView: View {
    @EnvironmentObject var theme: ThemeManager
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.below.ecg.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.current.textSecondary.opacity(0.2))
            Text("Your Research Timeline is Empty")
                .font(.headline)
            Text("Calculations and simulations will appear here as you work.")
                .font(.subheadline)
                .foregroundColor(theme.current.textSecondary)
            Spacer()
        }
    }
}

/// Placeholder for PDF Export Preview
struct PDFExportPreview: View {
    let content: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .padding()
                    .font(.system(.body, design: .monospaced))
            }
            .navigationTitle("Research Report")
            .toolbar {
                Button("Close") { dismiss() }
            }
        }
    }
}
