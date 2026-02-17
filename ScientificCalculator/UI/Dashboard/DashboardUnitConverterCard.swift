// UI/Dashboard/DashboardUnitConverterCard.swift
import SwiftUI

struct DashboardUnitConverterCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    enum UnitType: String, CaseIterable, Identifiable {
        case length = "Length"
        case mass = "Mass"
        case temperature = "Temperature"
        
        var id: String { rawValue }
    }
    
    @State private var selectedType: UnitType = .length
    @State private var inputValue: String = "1"
    
    // Length Units
    @State private var sourceLength: UnitLength = .meters
    @State private var destLength: UnitLength = .feet
    
    // Mass Units
    @State private var sourceMass: UnitMass = .kilograms
    @State private var destMass: UnitMass = .pounds
    
    // Temperature Units
    @State private var sourceTemp: UnitTemperature = .celsius
    @State private var destTemp: UnitTemperature = .fahrenheit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Unit Converter", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                Spacer()
                
                Picker("", selection: $selectedType) {
                    ForEach(UnitType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)
            }
            
            HStack(spacing: 8) {
                TextField("Value", text: $inputValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                
                // Source Unit Picker
                Group {
                    switch selectedType {
                    case .length:
                        Picker("", selection: $sourceLength) {
                            Text("m").tag(UnitLength.meters)
                            Text("ft").tag(UnitLength.feet)
                            Text("in").tag(UnitLength.inches)
                            Text("cm").tag(UnitLength.centimeters)
                            Text("km").tag(UnitLength.kilometers)
                            Text("mi").tag(UnitLength.miles)
                        }
                    case .mass:
                        Picker("", selection: $sourceMass) {
                            Text("kg").tag(UnitMass.kilograms)
                            Text("lb").tag(UnitMass.pounds)
                            Text("oz").tag(UnitMass.ounces)
                            Text("g").tag(UnitMass.grams)
                        }
                    case .temperature:
                        Picker("", selection: $sourceTemp) {
                            Text("°C").tag(UnitTemperature.celsius)
                            Text("°F").tag(UnitTemperature.fahrenheit)
                            Text("K").tag(UnitTemperature.kelvin)
                        }
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            }
            
            Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: 8) {
                Text(calculateResult())
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                
                // Destination Unit Picker
                Group {
                    switch selectedType {
                    case .length:
                        Picker("", selection: $destLength) {
                            Text("m").tag(UnitLength.meters)
                            Text("ft").tag(UnitLength.feet)
                            Text("in").tag(UnitLength.inches)
                            Text("cm").tag(UnitLength.centimeters)
                            Text("km").tag(UnitLength.kilometers)
                            Text("mi").tag(UnitLength.miles)
                        }
                    case .mass:
                        Picker("", selection: $destMass) {
                            Text("kg").tag(UnitMass.kilograms)
                            Text("lb").tag(UnitMass.pounds)
                            Text("oz").tag(UnitMass.ounces)
                            Text("g").tag(UnitMass.grams)
                        }
                    case .temperature:
                        Picker("", selection: $destTemp) {
                            Text("°C").tag(UnitTemperature.celsius)
                            Text("°F").tag(UnitTemperature.fahrenheit)
                            Text("K").tag(UnitTemperature.kelvin)
                        }
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            }
        }
        .padding()
        .background(themeManager.current.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func calculateResult() -> String {
        guard let value = Double(inputValue) else { return "Invalid" }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        
        var result: Double = 0.0
        
        switch selectedType {
        case .length:
            let input = Measurement(value: value, unit: sourceLength)
            result = input.converted(to: destLength).value
        case .mass:
            let input = Measurement(value: value, unit: sourceMass)
            result = input.converted(to: destMass).value
        case .temperature:
            let input = Measurement(value: value, unit: sourceTemp)
            result = input.converted(to: destTemp).value
        }
        
        return formatter.string(from: NSNumber(value: result)) ?? "\(result)"
    }
}
