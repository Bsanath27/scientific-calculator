// UI/Components/HistoryPanel.swift
// Scientific Calculator - Calculation History with Derivation Timeline (Luxe UI)

import SwiftUI

struct HistoryPanel: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.headline)
                    .foregroundColor(theme.current.textPrimary)
                
                Spacer()
                
                Button(action: { viewModel.clearHistory() }) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(theme.current.modernRed)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.current.displayBackground)
            
            Divider()
                .background(theme.current.divider)
            
            // List
            if viewModel.history.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(theme.current.textSecondary.opacity(0.3))
                        .padding(.bottom, 8)
                    Text("No calculations yet")
                        .font(.subheadline)
                        .foregroundColor(theme.current.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.history) { entry in
                            HistoryRow(entry: entry, viewModel: viewModel)
                            
                            Divider()
                                .background(theme.current.divider)
                        }
                    }
                }
            }
        }
        .background(theme.current.background)
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    @ObservedObject var viewModel: CalculatorViewModel
    @EnvironmentObject var theme: ThemeManager
    @State private var isShowingSteps = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.expression)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.current.textPrimary)
                    
                    Text("= \(entry.result)")
                        .font(.headline)
                        .foregroundColor(theme.current.accent)
                }
                
                Spacer()
                
                // Show Work Button
                if !entry.steps.isEmpty {
                    Button(action: { isShowingSteps.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                            Text("Work")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.current.accent.opacity(0.1))
                        .foregroundColor(theme.current.accent)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // Load Button
                Button(action: { viewModel.loadFromHistory(entry) }) {
                    Image(systemName: "arrow.up.left.circle")
                        .foregroundColor(theme.current.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            if isShowingSteps && !entry.steps.isEmpty {
                WorkStepsView(steps: entry.steps, finalResult: entry.result)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
            
            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10))
                .foregroundColor(theme.current.textSecondary.opacity(0.6))
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.loadFromHistory(entry)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowingSteps)
    }
}

