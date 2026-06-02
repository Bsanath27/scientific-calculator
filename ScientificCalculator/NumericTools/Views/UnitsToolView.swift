// NumericTools/Views/UnitsToolView.swift
// Scientific Calculator - Unit Conversion Tool

import SwiftUI

struct UnitsToolView: View {
    @State private var value = "100"
    @State private var selectedCategory: UnitCategory = .length
    @State private var fromUnit: MeasurementUnit = .kilometer
    @State private var toUnit: MeasurementUnit = .meter
    @State private var result = ""
    @State private var metricsText = ""
    
    private let engine = UnitsEngine()
    
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(theme.current.modernRed)
                Text("Unit Conversion")
                    .font(.headline)
                    .foregroundColor(theme.current.textPrimary)
            }
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(UnitCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 4)
            .onChange(of: selectedCategory) {
                let units = MeasurementUnit.units(in: selectedCategory)
                fromUnit = units.first ?? .meter
                toUnit = units.count > 1 ? units[1] : units.first ?? .meter
                result = ""
            }
            
            HStack(spacing: 12) {
                TextField("Value", text: $value)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .frame(width: 90)
                    .background(theme.current.displayBackground)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.current.divider, lineWidth: 1))
                
                VStack(spacing: 4) {
                    Picker("From", selection: $fromUnit) {
                        ForEach(MeasurementUnit.units(in: selectedCategory), id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .frame(width: 120)
                }
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(theme.current.textSecondary)
                
                VStack(spacing: 4) {
                    Picker("To", selection: $toUnit) {
                        ForEach(MeasurementUnit.units(in: selectedCategory), id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .frame(width: 120)
                }
                
                Button(action: convert) {
                    Text("Go")
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.current.modernRed)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if !result.isEmpty {
                HStack {
                    Text(result)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(theme.current.textPrimary)
                    
                    Text(toUnit.rawValue)
                        .font(.caption)
                        .foregroundColor(theme.current.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.current.displayBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.current.modernRed.opacity(0.3), lineWidth: 1))
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
