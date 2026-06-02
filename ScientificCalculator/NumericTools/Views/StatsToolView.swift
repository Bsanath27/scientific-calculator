// NumericTools/Views/StatsToolView.swift
// Scientific Calculator - Statistics Tool

import SwiftUI

struct StatsToolView: View {
    @State private var dataInput = "1 2 3 4 5 6 7 8 9 10"
    @State private var dataInputY = "2 4 5 4 5 7 8 9 10 12"
    @State private var windowSize = "3"
    @State private var operation = "Mean"
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = StatsEngine()
    private let operations = ["Mean", "Median", "Std Dev", "Variance", "Min", "Max", "Correlation", "Linear Regression", "Moving Average"]
    
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(theme.current.opticsGreen)
                Text("Statistics")
                    .font(.headline)
                    .foregroundColor(theme.current.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data X (space-separated)")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.textSecondary)
                    TextField("e.g. 1 2 3 4 5", text: $dataInput)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(theme.current.displayBackground)
                        .cornerRadius(8)
                        .font(.system(.body, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                }
                
                if ["Correlation", "Linear Regression"].contains(operation) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Y")
                            .font(.caption2.bold())
                            .foregroundColor(theme.current.textSecondary)
                        TextField("e.g. 2 4 6 8 10", text: $dataInputY)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(theme.current.displayBackground)
                            .cornerRadius(8)
                            .font(.system(.body, design: .monospaced))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                    }
                }
            }
            
            HStack(spacing: 12) {
                if operation == "Moving Average" {
                    HStack {
                        Text("W:")
                            .font(.caption2.bold())
                            .foregroundColor(theme.current.textSecondary)
                        TextField("", text: $windowSize)
                            .textFieldStyle(.plain)
                            .frame(width: 40)
                            .padding(6)
                            .background(theme.current.displayBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.current.divider, lineWidth: 1))
                    }
                }
                
                Picker("Operation", selection: $operation) {
                    ForEach(operations, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
                .padding(4)
                .background(theme.current.background)
                .cornerRadius(8)
                
                Button(action: compute) {
                    Text("Compute")
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.current.opticsGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if !result.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.opticsGreen)
                    
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.current.displayBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.current.opticsGreen.opacity(0.3), lineWidth: 1))
                        .textSelection(.enabled)
                }
            }
            
            if !metricsText.isEmpty {
                Text(metricsText)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.current.textSecondary.opacity(0.7))
            }
        }
        .padding()
        .background(theme.current.background.opacity(0.3))
        .cornerRadius(16)
    }
    
    private func parseData(_ text: String) -> [Double]? {
        let cleaned = MatrixToolView.sanitize(text)
        let values = cleaned.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .compactMap { Double($0) }
        return values.isEmpty ? nil : values
    }
    
    private func compute() {
        guard let data = parseData(dataInput) else {
            result = "Error: Invalid data"
            return
        }
        
        switch operation {
        case "Mean":
            let r = engine.mean(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Median":
            let r = engine.median(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Std Dev":
            guard data.count > 1 else { result = "Error: Need 2+ values"; return }
            let r = engine.standardDeviation(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Variance":
            guard data.count > 1 else { result = "Error: Need 2+ values"; return }
            let r = engine.variance(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Min":
            let r = engine.min(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Max":
            let r = engine.max(data)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Correlation":
            guard let dataY = parseData(dataInputY), data.count == dataY.count, data.count > 1 else {
                result = "Error: Need equal-length data with 2+ values"
                return
            }
            let r = engine.correlation(data, dataY)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Linear Regression":
            guard let dataY = parseData(dataInputY), data.count == dataY.count, data.count > 1 else {
                result = "Error: Need equal-length data with 2+ values"
                return
            }
            let r = engine.linearRegression(x: data, y: dataY)
            result = r.value.description
            metricsText = formatMetrics(r.metrics)
        case "Moving Average":
            guard let w = Int(windowSize), w > 0, w <= data.count else {
                result = "Error: Invalid window size"
                return
            }
            let r = engine.movingAverage(data, windowSize: w)
            result = r.value.map { String(format: "%.4f", $0) }.joined(separator: "  ")
            metricsText = formatMetrics(r.metrics)
        default:
            break
        }
    }
    
    private func formatMetrics(_ m: NumericToolMetrics) -> String {
        "Time: \(String(format: "%.3f", m.executionTimeMs)) ms | Memory: \(String(format: "%.2f", m.memoryUsageKB)) KB | Size: \(m.dataSize)"
    }
}
