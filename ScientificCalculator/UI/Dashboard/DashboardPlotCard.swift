// UI/Dashboard/DashboardPlotCard.swift
import SwiftUI
import Charts

struct DashboardPlotCard: View {
    let expression: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var points: [PlotPoint] = []
    private let engine = GraphEngine()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Live Plot", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                Spacer()
                Text(expression)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            if points.isEmpty {
                VStack {
                    ProgressView()
                    Text("Plotting...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("x", point.x),
                            y: .value("y", point.y)
                        )
                        .foregroundStyle(themeManager.current.accent)
                    }
                }
                .frame(minHeight: 120)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .padding()
        .background(themeManager.current.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear { updatePlot() }
        .onChange(of: expression) { updatePlot() }
    }
    
    private func updatePlot() {
        // Run in background to avoid stutter
        DispatchQueue.global(qos: .userInitiated).async {
            let result = engine.sample(expression: expression, pointCount: 100)
            DispatchQueue.main.async {
                self.points = result.value
            }
        }
    }
}
