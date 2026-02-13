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
}

struct NumericToolsView: View {
    @State private var selectedTool: NumericTool = .graph
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & Close
            HStack {
                Text("Numeric Tools")
                    .font(.headline)
                Spacer()
                Text("Phase 3")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            // Tool Picker
            Picker("Tool", selection: $selectedTool) {
                ForEach(NumericTool.allCases, id: \.self) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            Divider()
            
            // Tool Content
            ScrollView {
                switch selectedTool {
                case .matrix:
                    MatrixToolView()
                case .vector:
                    VectorToolView()
                case .stats:
                    StatsToolView()
                case .graph:
                    GraphView()
                case .units:
                    UnitsToolView()
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - Matrix Tool View

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Matrix Operations")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Matrix A:")
                        .font(.caption)
                    TextEditor(text: $dataA)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 80)
                        .border(Color.secondary.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Matrix B:")
                        .font(.caption)
                    TextEditor(text: $dataB)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 80)
                        .border(Color.secondary.opacity(0.3))
                }
            }
            
            HStack {
                Picker("Operation", selection: $operation) {
                    ForEach(operations, id: \.self) { Text($0) }
                }
                .frame(width: 180)
                
                Button("Compute") { compute() }
            }
            
            if !result.isEmpty {
                GroupBox("Result") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if !metricsText.isEmpty {
                Text(metricsText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
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

// MARK: - Vector Tool View

struct VectorToolView: View {
    @State private var vectorA = "1 2 3"
    @State private var vectorB = "4 5 6"
    @State private var operation = "Dot Product"
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = VectorEngine()
    private let operations = ["Dot Product", "Cross Product", "Norm", "Normalize", "Add", "Subtract", "Mean", "Sum", "Distance"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vector Operations")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vector A (space-separated):")
                        .font(.caption)
                    TextField("e.g. 1 2 3", text: $vectorA)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vector B:")
                        .font(.caption)
                    TextField("e.g. 4 5 6", text: $vectorB)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            
            HStack {
                Picker("Operation", selection: $operation) {
                    ForEach(operations, id: \.self) { Text($0) }
                }
                .frame(width: 180)
                
                Button("Compute") { compute() }
            }
            
            if !result.isEmpty {
                GroupBox("Result") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if !metricsText.isEmpty {
                Text(metricsText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
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

// MARK: - Stats Tool View

struct StatsToolView: View {
    @State private var dataInput = "1 2 3 4 5 6 7 8 9 10"
    @State private var dataInputY = "2 4 5 4 5 7 8 9 10 12"
    @State private var windowSize = "3"
    @State private var operation = "Mean"
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = StatsEngine()
    private let operations = ["Mean", "Median", "Std Dev", "Variance", "Min", "Max", "Correlation", "Linear Regression", "Moving Average"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistics")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Data X (space-separated):")
                    .font(.caption)
                TextField("e.g. 1 2 3 4 5", text: $dataInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
            }
            
            if ["Correlation", "Linear Regression"].contains(operation) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Y:")
                        .font(.caption)
                    TextField("e.g. 2 4 6 8 10", text: $dataInputY)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            
            if operation == "Moving Average" {
                HStack {
                    Text("Window:")
                        .font(.caption)
                    TextField("size", text: $windowSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
            }
            
            HStack {
                Picker("Operation", selection: $operation) {
                    ForEach(operations, id: \.self) { Text($0) }
                }
                .frame(width: 200)
                
                Button("Compute") { compute() }
            }
            
            if !result.isEmpty {
                GroupBox("Result") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if !metricsText.isEmpty {
                Text(metricsText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
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

// MARK: - Units Tool View

struct UnitsToolView: View {
    @State private var value = "100"
    @State private var selectedCategory: UnitCategory = .length
    @State private var fromUnit: MeasurementUnit = .kilometer
    @State private var toUnit: MeasurementUnit = .meter
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = UnitsEngine()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unit Conversion")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Category picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(UnitCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedCategory) {
                let units = MeasurementUnit.units(in: selectedCategory)
                fromUnit = units.first ?? .meter
                toUnit = units.count > 1 ? units[1] : units.first ?? .meter
                result = ""
            }
            
            HStack(spacing: 12) {
                TextField("Value", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                
                Picker("From", selection: $fromUnit) {
                    ForEach(MeasurementUnit.units(in: selectedCategory), id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .frame(width: 100)
                
                Text("→")
                    .font(.title2)
                
                Picker("To", selection: $toUnit) {
                    ForEach(MeasurementUnit.units(in: selectedCategory), id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .frame(width: 100)
                
                Button("Convert") { convert() }
            }
            
            if !result.isEmpty {
                Text(result)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
            }
            
            if !metricsText.isEmpty {
                Text(metricsText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func convert() {
        guard let val = Double(value) else {
            result = "Error: Invalid number"
            return
        }
        
        let r = engine.convert(val, from: fromUnit, to: toUnit)
        result = r.value.description
        metricsText = "Time: \(String(format: "%.3f", r.metrics.executionTimeMs)) ms"
    }
}

// MARK: - Preview

#Preview {
    NumericToolsView()
}
