// NumericTools/GraphView.swift
// Scientific Calculator - Phase 3: Graph Plotting View
// Uses Swift Charts for rendering function plots

import SwiftUI
import Charts

struct GraphView: View {
    @StateObject private var viewModel = GraphViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expression Input
            HStack {
                TextField("Enter f(x), e.g. sin(x), x^2+1", text: $viewModel.expression)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.plot() }
                
                Button("Plot") { viewModel.plot() }
                    .disabled(viewModel.isPlotting)
                
                Button("Add") { viewModel.addExpression() }
            }
            
            // Multi-expression list
            if !viewModel.expressions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(viewModel.expressions, id: \.self) { expr in
                        HStack(spacing: 4) {
                            Text(expr)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(4)
                            
                            Button {
                                viewModel.removeExpression(expr)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Plot All") { viewModel.plotAll() }
                        .font(.caption)
                        .disabled(viewModel.isPlotting)
                }
            }
            
            // Range Controls
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("x:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("min", value: $viewModel.xMin, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("max", value: $viewModel.xMax, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                
                HStack(spacing: 4) {
                    Text("Points:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("count", value: $viewModel.pointCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                
                Spacer()
                
                Button("Reset") { viewModel.reset() }
                    .font(.caption)
            }
            
            // Chart
            if !viewModel.plotFunctions.isEmpty {
                chartView
                    .frame(minHeight: 250)
                    .padding(.vertical, 4)
            } else if viewModel.isPlotting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Computing plot...")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Enter an expression with 'x' and click Plot")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            // Metrics
            if !viewModel.metricsText.isEmpty {
                Text(viewModel.metricsText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
        Chart {
            ForEach(viewModel.plotFunctions) { fn in
                ForEach(fn.points) { point in
                    LineMark(
                        x: .value("x", point.x),
                        y: .value("y", point.y),
                        series: .value("Function", fn.expression)
                    )
                    .foregroundStyle(chartColor(fn.color))
                }
            }
        }
        .chartXAxisLabel("x")
        .chartYAxisLabel("y")
        .chartLegend(viewModel.plotFunctions.count > 1 ? .visible : .hidden)
    }
    
    private func chartColor(_ color: PlotColor) -> Color {
        switch color {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

#Preview {
    GraphView()
        .padding()
        .frame(width: 600, height: 500)
}
