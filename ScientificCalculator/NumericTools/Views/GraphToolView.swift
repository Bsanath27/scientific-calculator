// NumericTools/GraphView.swift
// Scientific Calculator - Phase 3: Graph Plotting View
// Uses Swift Charts for rendering function plots

import SwiftUI
import Charts

struct GraphToolView: View {
    @StateObject private var viewModel = GraphViewModel()
    
    var body: some View {
        GeometryReader { geometry in
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
                        ScrollView(.horizontal, showsIndicators: false) {
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
                            }
                        }
                        
                        Spacer()
                        
                        Button("Plot All") { viewModel.plotAll() }
                            .font(.caption)
                            .disabled(viewModel.isPlotting)
                    }
                }
                
                // Range Controls
                Group {
                    if geometry.size.width > 500 {
                        HStack(spacing: 16) {
                            xRangeControls
                            pointsControls
                            Spacer()
                            resetButton
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                xRangeControls
                                Spacer()
                                resetButton
                            }
                            pointsControls
                        }
                    }
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
    }
    
    private var xRangeControls: some View {
        HStack(spacing: 4) {
            Text("x:")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("min", value: $viewModel.xMin, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
            Text("-")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("max", value: $viewModel.xMax, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
        }
    }
    
    private var pointsControls: some View {
        HStack(spacing: 4) {
            Text("Points:")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("count", value: $viewModel.pointCount, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
        }
    }
    
    private var resetButton: some View {
        Button("Reset") { viewModel.reset() }
            .font(.caption)
    }
    
    @ViewBuilder
    private var chartView: some View {
        autoreleasepool {
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
                    
                    // Selected Point Indicator
                    if let selectedPoint = viewModel.selectedPoint, selectedPoint.expression == fn.expression {
                        PointMark(
                            x: .value("x", selectedPoint.x),
                            y: .value("y", selectedPoint.y)
                        )
                        .symbolSize(100)
                        .foregroundStyle(chartColor(fn.color))
                        .annotation(position: .top, spacing: 0) {
                            AnnotationBubble(point: selectedPoint)
                        }
                    }
                }
            }
            .chartXAxisLabel("x")
            .chartYAxisLabel("y")
            .chartLegend(viewModel.plotFunctions.count > 1 ? .visible : .hidden)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            handleTap(at: location, proxy: proxy)
                        }
                }
            }
        }
    }
    
    private func handleTap(at location: CGPoint, proxy: ChartProxy) {
        if let x: Double = proxy.value(atX: location.x) {
            viewModel.annotate(at: x)
        }
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

struct AnnotationBubble: View {
    let point: GraphAnnotation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("x: \(String(format: "%.3f", point.x))")
            Text("y: \(String(format: "%.3f", point.y))")
            Divider().background(.white.opacity(0.3))
            Text("dy/dx: \(String(format: "%.3f", point.slope))")
            Text("∫y dx: \(String(format: "%.3f", point.area))")
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

#Preview {
    GraphToolView()
        .padding()
        .frame(width: 600, height: 500)
}
