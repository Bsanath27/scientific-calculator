// UI/ContentView.swift
// Scientific Calculator - Main UI (Minimal, Functional Only)

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showTools = false
    @State private var showOCR = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Scientific Calculator Core")
                    .font(.headline)
                Spacer()
                Button("OCR") { showOCR = true }
                Button("Tools") { showTools = true }
            }
            
            // Mode Toggle (Phase 2)
            Picker("Mode", selection: $viewModel.mode) {
                Text("Numeric").tag(ComputationMode.numeric)
                Text("Symbolic").tag(ComputationMode.symbolic)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            // Expression Input
            HStack {
                TextField("Enter expression (e.g., 2+3*4, sin(pi/4))", text: $viewModel.expression)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.evaluate() }
                
                Button("Evaluate") { viewModel.evaluate() }
                    .keyboardShortcut(.return, modifiers: [])
                
                Button("Clear") { viewModel.clear() }
            }
            
            // Result
            if !viewModel.result.isEmpty {
                HStack {
                    Text("Result:")
                        .fontWeight(.medium)
                    Text(viewModel.result)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }
            
            // Metrics Panel
            if !viewModel.metricsText.isEmpty {
                GroupBox("Metrics") {
                    Text(viewModel.metricsText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Benchmark Section
            GroupBox("Benchmark") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button("Run Benchmark (1000x)") {
                            viewModel.runBenchmark()
                        }
                        .disabled(viewModel.isRunningBenchmark || viewModel.expression.isEmpty)
                        
                        if viewModel.isRunningBenchmark {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Running...")
                                .font(.caption)
                        }
                    }
                    
                    if !viewModel.benchmarkResult.isEmpty {
                        Text(viewModel.benchmarkResult)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // History
            GroupBox("History") {
                if viewModel.history.isEmpty {
                    Text("No evaluations yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Text("\(viewModel.history.count) entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear") { viewModel.clearHistory() }
                                .font(.caption)
                        }
                        
                        List(viewModel.history) { entry in
                            HistoryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.loadFromHistory(entry)
                                }
                        }
                        .listStyle(.plain)
                        .frame(height: 150)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            Text("Phase 4: OCR Equation Engine")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 500)
        .sheet(isPresented: $showTools) {
            NumericToolsView()
        }
        .sheet(isPresented: $showOCR) {
            OCRView { expression in
                viewModel.expression = expression
                viewModel.evaluate()
            }
        }
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.expression)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
            HStack {
                Text("= \(entry.result)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.3fms", entry.metrics.totalTimeMs))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
