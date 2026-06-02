// ScientificCalculator/PhysicsEngine/PhysicsParameter.swift
// Physics Simulation Parameter Models

import Foundation

struct PhysicsParameter: Identifiable, Hashable {
    let id: String                    // e.g. "v0", "theta", "mass"
    let symbol: String                // e.g. "v₀", "θ", "m"
    let label: String                 // e.g. "Initial Velocity"
    let unit: String                  // e.g. "m/s", "°", "kg"
    var value: Double
    let range: ClosedRange<Double>
    let stepSize: Double
    let physicalMeaning: String       // shown as a tooltip
    
    var clampedValue: Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
