// NumericTools/Views/MatrixToolView.swift
// Scientific Calculator - Matrix Operations Tool

import SwiftUI

struct MatrixToolView: View {
    @State private var rowsA = "2"
    @State private var colsA = "2"
    @State private var dataA = "1 2\n3 4"
    @State private var dataB = "5 6\n7 8"
    @State private var operation = "Multiply"
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = MatrixEngine()
    private let operations = ["Add", "Subtract", "Multiply", "Transpose", "Determinant", "Inverse", "Eigenvalues"]
    
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "grid")
                    .foregroundColor(theme.current.accent)
                Text("Matrix Operations")
                    .font(.headline)
                    .foregroundColor(theme.current.textPrimary)
            }
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Matrix A", systemImage: "square.fill")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.textSecondary)
                    
                    TextEditor(text: $dataA)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 100)
                        .padding(4)
                        .background(theme.current.displayBackground)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Matrix B", systemImage: "square.fill")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.textSecondary)
                    
                    TextEditor(text: $dataB)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 100)
                        .padding(4)
                        .background(theme.current.displayBackground)
                        .cornerRadius(8)
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
                        .background(theme.current.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if !result.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result")
                        .font(.caption2.bold())
                        .foregroundColor(theme.current.accent)
                    
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.current.displayBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.current.accent.opacity(0.3), lineWidth: 1))
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
    
    /// Sanitize input: strip brackets, replace commas/semicolons, normalize whitespace
    static func sanitize(_ text: String) -> String {
        var s = text
        // Remove brackets
        for ch: Character in ["[", "]", "(", ")", "{", "}"] {
            s = s.filter { $0 != ch }
        }
        // Semicolons become newlines (MatLab/Octave style)
        s = s.replacingOccurrences(of: ";", with: "\n")
        // Commas become spaces
        s = s.replacingOccurrences(of: ",", with: " ")
        return s
    }

    private func parseMatrix(_ text: String) -> Matrix? {
        let cleaned = Self.sanitize(text)
        let rows = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !rows.isEmpty else { return nil }
        
        var data: [[Double]] = []
        for row in rows {
            let values = row.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .compactMap { Double($0) }
            if values.isEmpty { return nil }
            data.append(values)
        }
        
        guard data.allSatisfy({ $0.count == data[0].count }) else { return nil }
        return Matrix(data)
    }
    
    private func compute() {
        guard let a = parseMatrix(dataA) else {
            result = "Error: Invalid Matrix A"
            return
        }
        
        switch operation {
        case "Transpose":
            let r = engine.transpose(a)
            result = r.value.description
            metricsText = formatMetrics(r.metrics)
            
        case "Determinant":
            guard a.isSquare else {
                result = "Error: Determinant requires a square matrix"
                return
            }
            let r = engine.determinant(a)
            result = ResultFormatter.format(r.value)
            metricsText = formatMetrics(r.metrics)
            
        case "Inverse":
            guard a.isSquare else {
                result = "Error: Inverse requires a square matrix"
                return
            }
            let r = engine.inverse(a)
            result = r.value?.description ?? "Matrix is singular (no inverse)"
            metricsText = formatMetrics(r.metrics)
            
        case "Eigenvalues":
            guard a.isSquare else {
                result = "Error: Eigenvalues require a square matrix"
                return
            }
            let r = engine.eigenvalues(a)
            let eigenStr = zip(r.value.real, r.value.imaginary).map { real, imag in
                if abs(imag) < 1e-10 {
                    return String(format: "%.6f", real)
                } else {
                    return String(format: "%.6f + %.6fi", real, imag)
                }
            }.joined(separator: "\n")
            result = eigenStr.isEmpty ? "Failed to compute eigenvalues" : eigenStr
            metricsText = formatMetrics(r.metrics)
            
        default:
            guard let b = parseMatrix(dataB) else {
                result = "Error: Invalid Matrix B"
                return
            }
            
            switch operation {
            case "Add":
                guard a.rows == b.rows && a.cols == b.cols else {
                    result = "Error: Dimensions must match"
                    return
                }
                let r = engine.add(a, b)
                result = r.value.description
                metricsText = formatMetrics(r.metrics)
            case "Subtract":
                guard a.rows == b.rows && a.cols == b.cols else {
                    result = "Error: Dimensions must match"
                    return
                }
                let r = engine.subtract(a, b)
                result = r.value.description
                metricsText = formatMetrics(r.metrics)
            case "Multiply":
                guard a.cols == b.rows else {
                    result = "Error: A cols must equal B rows"
                    return
                }
                let r = engine.multiply(a, b)
                result = r.value.description
                metricsText = formatMetrics(r.metrics)
            default:
                break
            }
        }
    }
    
    private func formatMetrics(_ m: NumericToolMetrics) -> String {
        "Time: \(String(format: "%.3f", m.executionTimeMs)) ms | Memory: \(String(format: "%.2f", m.memoryUsageKB)) KB"
    }
}
