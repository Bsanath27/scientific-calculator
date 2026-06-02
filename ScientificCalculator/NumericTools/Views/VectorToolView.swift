// NumericTools/Views/VectorToolView.swift
// Scientific Calculator - Vector Operations Tool

import SwiftUI

struct VectorToolView: View {
    @State private var vectorA = "1 2 3"
    @State private var vectorB = "4 5 6"
    @State private var operation = "Dot Product"
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = VectorEngine()
    private let operations = ["Dot Product", "Cross Product", "Norm", "Normalize", "Add", "Subtract", "Mean", "Sum", "Distance"]
    
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                    .foregroundColor(theme.current.mechanicsBlue)
                Text("Vector Operations")
                    .font(.headline)
                    .foregroundColor(theme.current.textPrimary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vector A (space-separated)")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.textSecondary)
                    TextField("e.g. 1 2 3", text: $vectorA)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(theme.current.displayBackground)
                        .cornerRadius(8)
                        .font(.system(.body, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vector B")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.textSecondary)
                    TextField("e.g. 4 5 6", text: $vectorB)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(theme.current.displayBackground)
                        .cornerRadius(8)
                        .font(.system(.body, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                }
            }
            
            HStack(spacing: 12) {
                Picker("Operation", selection: $operation) {
                    ForEach(operations, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                .padding(4)
                .background(theme.current.background)
                .cornerRadius(8)
                
                Button(action: compute) {
                    Text("Compute")
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(theme.current.mechanicsBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if !result.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.mechanicsBlue)
                    
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.current.displayBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.current.mechanicsBlue.opacity(0.3), lineWidth: 1))
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
    
    private func parseVector(_ text: String) -> [Double]? {
        let cleaned = MatrixToolView.sanitize(text)
        let values = cleaned.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .compactMap { Double($0) }
        return values.isEmpty ? nil : values
    }
    
    private func compute() {
        guard let a = parseVector(vectorA) else {
            result = "Error: Invalid Vector A"
            return
        }
        
        switch operation {
        case "Norm":
            let r = engine.norm(a)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Normalize":
            let r = engine.normalize(a)
            result = formatVector(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Mean":
            let r = engine.mean(a)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        case "Sum":
            let r = engine.sum(a)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
        default:
            guard let b = parseVector(vectorB) else {
                result = "Error: Invalid Vector B"
                return
            }
            switch operation {
            case "Dot Product":
                guard a.count == b.count else { result = "Error: Vectors must have same length"; return }
                let r = engine.dot(a, b)
                result = ResultFormatter.format(r.value)
                metricsText = formatMetrics(r.metrics)
            case "Cross Product":
                guard a.count == 3 && b.count == 3 else { result = "Error: Cross product requires 3D vectors"; return }
                let r = engine.cross(a, b)
                result = formatVector(r.value)
                metricsText = formatMetrics(r.metrics)
            case "Add":
                guard a.count == b.count else { result = "Error: Vectors must have same length"; return }
                let r = engine.add(a, b)
                result = formatVector(r.value)
                metricsText = formatMetrics(r.metrics)
            case "Subtract":
                guard a.count == b.count else { result = "Error: Vectors must have same length"; return }
                let r = engine.subtract(a, b)
                result = formatVector(r.value)
                metricsText = formatMetrics(r.metrics)
            case "Distance":
                guard a.count == b.count else { result = "Error: Vectors must have same length"; return }
                let r = engine.distance(a, b)
                result = ResultFormatter.format(r.value)
                metricsText = formatMetrics(r.metrics)
            default:
                break
            }
        }
    }
    
    private func formatVector(_ v: [Double]) -> String {
        "[ " + v.map { String(format: "%.6f", $0) }.joined(separator: "  ") + " ]"
    }
    
    private func formatMetrics(_ m: NumericToolMetrics) -> String {
        "Time: \(String(format: "%.3f", m.executionTimeMs)) ms | Memory: \(String(format: "%.2f", m.memoryUsageKB)) KB"
    }
}
