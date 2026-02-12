// NumericTools/UnitsEngine.swift
// Scientific Calculator - Phase 3: Unit Conversion Engine
// Simple lookup-table based conversions

import Foundation

/// Unit categories
enum UnitCategory: String, CaseIterable {
    case length = "Length"
    case mass = "Mass"
    case time = "Time"
    case temperature = "Temperature"
    case angle = "Angle"
}

/// Supported units
enum MeasurementUnit: String, CaseIterable {
    // Length
    case millimeter = "mm"
    case centimeter = "cm"
    case meter = "m"
    case kilometer = "km"
    case inch = "in"
    case foot = "ft"
    case yard = "yd"
    case mile = "mi"
    
    // Mass
    case milligram = "mg"
    case gram = "g"
    case kilogram = "kg"
    case pound = "lb"
    case ounce = "oz"
    
    // Time
    case millisecond = "ms"
    case second = "s"
    case minute = "min"
    case hour = "hr"
    case day = "day"
    
    // Temperature
    case celsius = "C"
    case fahrenheit = "F"
    case kelvin = "K"
    
    // Angle
    case degree = "deg"
    case radian = "rad"
    case gradian = "grad"
    
    /// Category this unit belongs to
    var category: UnitCategory {
        switch self {
        case .millimeter, .centimeter, .meter, .kilometer, .inch, .foot, .yard, .mile:
            return .length
        case .milligram, .gram, .kilogram, .pound, .ounce:
            return .mass
        case .millisecond, .second, .minute, .hour, .day:
            return .time
        case .celsius, .fahrenheit, .kelvin:
            return .temperature
        case .degree, .radian, .gradian:
            return .angle
        }
    }
    
    /// Units in a given category
    static func units(in category: UnitCategory) -> [MeasurementUnit] {
        allCases.filter { $0.category == category }
    }
}

/// Unit conversion result
struct ConversionResult {
    let fromValue: Double
    let fromUnit: MeasurementUnit
    let toValue: Double
    let toUnit: MeasurementUnit
    
    var description: String {
        "\(ResultFormatter.format(fromValue)) \(fromUnit.rawValue) = \(ResultFormatter.format(toValue)) \(toUnit.rawValue)"
    }
}

/// Unit conversion engine using lookup tables
final class UnitsEngine {
    
    // MARK: - Conversion Tables (to SI base unit)
    
    // Length → meters
    private static let lengthToMeters: [MeasurementUnit: Double] = [
        .millimeter: 0.001,
        .centimeter: 0.01,
        .meter: 1.0,
        .kilometer: 1000.0,
        .inch: 0.0254,
        .foot: 0.3048,
        .yard: 0.9144,
        .mile: 1609.344
    ]
    
    // Mass → kilograms
    private static let massToKilograms: [MeasurementUnit: Double] = [
        .milligram: 0.000001,
        .gram: 0.001,
        .kilogram: 1.0,
        .pound: 0.453592,
        .ounce: 0.0283495
    ]
    
    // Time → seconds
    private static let timeToSeconds: [MeasurementUnit: Double] = [
        .millisecond: 0.001,
        .second: 1.0,
        .minute: 60.0,
        .hour: 3600.0,
        .day: 86400.0
    ]
    
    // Angle → radians
    private static let angleToRadians: [MeasurementUnit: Double] = [
        .degree: .pi / 180.0,
        .radian: 1.0,
        .gradian: .pi / 200.0
    ]
    
    // MARK: - Conversion
    
    /// Convert value from one unit to another
    func convert(_ value: Double, from: MeasurementUnit, to: MeasurementUnit) -> NumericToolResult<ConversionResult> {
        precondition(from.category == to.category, "Cannot convert between different categories: \(from.category) vs \(to.category)")
        
        return NumericToolRunner.run(operationType: "Unit Convert", dataSize: 1) {
            let converted: Double
            
            if from.category == .temperature {
                converted = Self.convertTemperature(value, from: from, to: to)
            } else {
                converted = Self.convertViaBase(value, from: from, to: to)
            }
            
            return ConversionResult(fromValue: value, fromUnit: from, toValue: converted, toUnit: to)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Convert via SI base unit (multiply by factor to base, divide by factor from base)
    private static func convertViaBase(_ value: Double, from: MeasurementUnit, to: MeasurementUnit) -> Double {
        let table: [MeasurementUnit: Double]
        
        switch from.category {
        case .length: table = lengthToMeters
        case .mass: table = massToKilograms
        case .time: table = timeToSeconds
        case .angle: table = angleToRadians
        case .temperature: fatalError("Use convertTemperature for temperature")
        }
        
        guard let fromFactor = table[from], let toFactor = table[to] else {
            return value  // Same unit or unknown
        }
        
        // value * fromFactor gives SI base, divide by toFactor gives target
        return value * fromFactor / toFactor
    }
    
    /// Temperature conversion (formula-based, not simple ratios)
    private static func convertTemperature(_ value: Double, from: MeasurementUnit, to: MeasurementUnit) -> Double {
        guard from != to else { return value }
        
        // Convert to Celsius first
        let celsius: Double
        switch from {
        case .celsius: celsius = value
        case .fahrenheit: celsius = (value - 32.0) * 5.0 / 9.0
        case .kelvin: celsius = value - 273.15
        default: return value
        }
        
        // Convert from Celsius to target
        switch to {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        case .kelvin: return celsius + 273.15
        default: return value
        }
    }
    
    // MARK: - Parsing
    
    /// Parse a conversion string like "10 km to m"
    func parseAndConvert(_ input: String) -> NumericToolResult<ConversionResult>? {
        // Pattern: <number> <unit> to <unit>
        let components = input.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " to ")
        
        guard components.count == 2 else { return nil }
        
        let leftParts = components[0].trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        guard leftParts.count >= 2 else { return nil }
        
        guard let value = Double(leftParts[0]) else { return nil }
        let fromUnitStr = leftParts[1...].joined(separator: " ")
        let toUnitStr = components[1].trimmingCharacters(in: .whitespaces)
        
        guard let fromUnit = MeasurementUnit(rawValue: fromUnitStr),
              let toUnit = MeasurementUnit(rawValue: toUnitStr) else { return nil }
        
        guard fromUnit.category == toUnit.category else { return nil }
        
        return convert(value, from: fromUnit, to: toUnit)
    }
}
