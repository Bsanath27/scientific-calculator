// UI/Components/PhysicsReference.swift
// Scientific Calculator - Physics Constants & Formulas Reference

import SwiftUI

// MARK: - Data Models

struct PhysicsConstant: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: String
    let unit: String
    let category: PhysicsCategory
}

struct PhysicsFormula: Identifiable {
    let id = UUID()
    let name: String
    let display: String      // Pretty display (e.g. "F = ma")
    let expression: String   // Calculator-friendly (e.g. "m*a")
    let category: PhysicsCategory
}

enum PhysicsCategory: String, CaseIterable {
    case mechanics = "Mechanics"
    case electromagnetism = "Electromagnetism"
    case thermodynamics = "Thermodynamics"
    case quantum = "Quantum"
    case astrophysics = "Astrophysics"
    case waves = "Waves & Optics"
    
    var icon: String {
        switch self {
        case .mechanics: return "figure.run"
        case .electromagnetism: return "bolt.fill"
        case .thermodynamics: return "flame.fill"
        case .quantum: return "atom"
        case .astrophysics: return "moon.stars.fill"
        case .waves: return "waveform"
        }
    }
    
    var color: Color {
        switch self {
        case .mechanics: return Color(hex: 0xA3BE8C)        // Green
        case .electromagnetism: return Color(hex: 0xEBCB8B)  // Yellow
        case .thermodynamics: return Color(hex: 0xD08770)    // Orange
        case .quantum: return Color(hex: 0xB48EAD)           // Purple
        case .astrophysics: return Color(hex: 0x81A1C1)      // Blue
        case .waves: return Color(hex: 0x88C0D0)             // Cyan
        }
    }
}

// MARK: - Constants Database

let physicsConstants: [PhysicsConstant] = [
    // Mechanics
    PhysicsConstant(symbol: "g", name: "Gravitational Accel.", value: "9.80665", unit: "m/s²", category: .mechanics),
    PhysicsConstant(symbol: "G", name: "Gravitational Constant", value: "6.674e-11", unit: "N·m²/kg²", category: .mechanics),
    PhysicsConstant(symbol: "atm", name: "Standard Atmosphere", value: "101325", unit: "Pa", category: .mechanics),
    
    // Electromagnetism
    PhysicsConstant(symbol: "e", name: "Elementary Charge", value: "1.602e-19", unit: "C", category: .electromagnetism),
    PhysicsConstant(symbol: "ε₀", name: "Permittivity of Free Space", value: "8.854e-12", unit: "F/m", category: .electromagnetism),
    PhysicsConstant(symbol: "μ₀", name: "Permeability of Free Space", value: "1.257e-6", unit: "H/m", category: .electromagnetism),
    PhysicsConstant(symbol: "ke", name: "Coulomb's Constant", value: "8.988e9", unit: "N·m²/C²", category: .electromagnetism),
    
    // Thermodynamics
    PhysicsConstant(symbol: "kB", name: "Boltzmann Constant", value: "1.381e-23", unit: "J/K", category: .thermodynamics),
    PhysicsConstant(symbol: "R", name: "Gas Constant", value: "8.314", unit: "J/(mol·K)", category: .thermodynamics),
    PhysicsConstant(symbol: "NA", name: "Avogadro's Number", value: "6.022e23", unit: "1/mol", category: .thermodynamics),
    PhysicsConstant(symbol: "σ", name: "Stefan-Boltzmann", value: "5.670e-8", unit: "W/(m²·K⁴)", category: .thermodynamics),
    
    // Quantum
    PhysicsConstant(symbol: "h", name: "Planck's Constant", value: "6.626e-34", unit: "J·s", category: .quantum),
    PhysicsConstant(symbol: "ℏ", name: "Reduced Planck", value: "1.055e-34", unit: "J·s", category: .quantum),
    PhysicsConstant(symbol: "me", name: "Electron Mass", value: "9.109e-31", unit: "kg", category: .quantum),
    PhysicsConstant(symbol: "mp", name: "Proton Mass", value: "1.673e-27", unit: "kg", category: .quantum),
    
    // Astrophysics
    PhysicsConstant(symbol: "c", name: "Speed of Light", value: "299792458", unit: "m/s", category: .astrophysics),
    PhysicsConstant(symbol: "AU", name: "Astronomical Unit", value: "1.496e11", unit: "m", category: .astrophysics),
    PhysicsConstant(symbol: "ly", name: "Light Year", value: "9.461e15", unit: "m", category: .astrophysics),
    PhysicsConstant(symbol: "M☉", name: "Solar Mass", value: "1.989e30", unit: "kg", category: .astrophysics),
    
    // Waves
    PhysicsConstant(symbol: "vsound", name: "Speed of Sound (air)", value: "343", unit: "m/s", category: .waves),
]

let physicsFormulas: [PhysicsFormula] = [
    // Mechanics
    PhysicsFormula(name: "Newton's 2nd Law", display: "F = m·a", expression: "m*a", category: .mechanics),
    PhysicsFormula(name: "Kinetic Energy", display: "KE = ½mv²", expression: "0.5*m*v^2", category: .mechanics),
    PhysicsFormula(name: "Potential Energy", display: "PE = mgh", expression: "m*g*h", category: .mechanics),
    PhysicsFormula(name: "Work", display: "W = F·d·cos(θ)", expression: "F*d*cos(theta)", category: .mechanics),
    PhysicsFormula(name: "Momentum", display: "p = m·v", expression: "m*v", category: .mechanics),
    PhysicsFormula(name: "Free Fall", display: "v = v₀ + gt", expression: "v0+9.80665*t", category: .mechanics),
    PhysicsFormula(name: "Displacement", display: "s = v₀t + ½gt²", expression: "v0*t+0.5*9.80665*t^2", category: .mechanics),
    PhysicsFormula(name: "Centripetal Force", display: "F = mv²/r", expression: "m*v^2/r", category: .mechanics),
    
    // Electromagnetism
    PhysicsFormula(name: "Ohm's Law", display: "V = I·R", expression: "I*R", category: .electromagnetism),
    PhysicsFormula(name: "Coulomb's Law", display: "F = ke·q₁q₂/r²", expression: "8.988e9*q1*q2/r^2", category: .electromagnetism),
    PhysicsFormula(name: "Electric Power", display: "P = I·V", expression: "I*V", category: .electromagnetism),
    PhysicsFormula(name: "Capacitor Energy", display: "E = ½CV²", expression: "0.5*C*V^2", category: .electromagnetism),
    
    // Thermodynamics
    PhysicsFormula(name: "Ideal Gas Law", display: "PV = nRT", expression: "n*8.314*T", category: .thermodynamics),
    PhysicsFormula(name: "Heat Transfer", display: "Q = mcΔT", expression: "m*c*dT", category: .thermodynamics),
    PhysicsFormula(name: "Entropy Change", display: "ΔS = Q/T", expression: "Q/T", category: .thermodynamics),
    
    // Quantum
    PhysicsFormula(name: "Photon Energy", display: "E = hf", expression: "6.626e-34*f", category: .quantum),
    PhysicsFormula(name: "de Broglie", display: "λ = h/p", expression: "6.626e-34/p", category: .quantum),
    PhysicsFormula(name: "Mass-Energy", display: "E = mc²", expression: "m*299792458^2", category: .quantum),
    
    // Waves
    PhysicsFormula(name: "Wave Speed", display: "v = fλ", expression: "f*lambda", category: .waves),
    PhysicsFormula(name: "Period", display: "T = 1/f", expression: "1/f", category: .waves),
    PhysicsFormula(name: "Pendulum", display: "T = 2π√(L/g)", expression: "2*pi*sqrt(L/9.80665)", category: .waves),
]

// MARK: - View

struct PhysicsReference: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var onInsert: (String) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedCategory: PhysicsCategory? = nil
    @State private var showingFormulas: Bool = false
    
    private var filteredConstants: [PhysicsConstant] {
        physicsConstants.filter { c in
            let matchCategory = selectedCategory == nil || c.category == selectedCategory
            let matchSearch = searchText.isEmpty ||
                c.name.localizedCaseInsensitiveContains(searchText) ||
                c.symbol.localizedCaseInsensitiveContains(searchText)
            return matchCategory && matchSearch
        }
    }
    
    private var filteredFormulas: [PhysicsFormula] {
        physicsFormulas.filter { f in
            let matchCategory = selectedCategory == nil || f.category == selectedCategory
            let matchSearch = searchText.isEmpty ||
                f.name.localizedCaseInsensitiveContains(searchText) ||
                f.display.localizedCaseInsensitiveContains(searchText)
            return matchCategory && matchSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Physics Reference", systemImage: "atom")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.current.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(themeManager.current.displayBackground)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search constants or formulas...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(themeManager.current.background)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(nil, label: "All", icon: "square.grid.2x2")
                    ForEach(PhysicsCategory.allCases, id: \.self) { cat in
                        categoryChip(cat, label: cat.rawValue, icon: cat.icon)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
            
            // Toggle: Constants / Formulas
            Picker("", selection: $showingFormulas) {
                Text("Constants (\(filteredConstants.count))").tag(false)
                Text("Formulas (\(filteredFormulas.count))").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // Content
            ScrollView {
                if showingFormulas {
                    formulasList
                } else {
                    constantsList
                }
            }
        }
        .frame(width: 520, height: 560)
        .background(themeManager.current.surface)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func categoryChip(_ category: PhysicsCategory?, label: String, icon: String) -> some View {
        Button(action: { selectedCategory = category }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                selectedCategory == category
                    ? (category?.color ?? themeManager.current.accent)
                    : themeManager.current.background
            )
            .foregroundColor(
                selectedCategory == category
                    ? .white
                    : themeManager.current.textSecondary
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var constantsList: some View {
        LazyVStack(spacing: 6) {
            ForEach(filteredConstants) { constant in
                Button(action: {
                    onInsert(constant.value)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text(constant.symbol)
                            .font(.system(.title3, design: .serif))
                            .bold()
                            .foregroundColor(constant.category.color)
                            .frame(width: 40, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(constant.name)
                                .font(.subheadline)
                                .foregroundColor(themeManager.current.textPrimary)
                            Text("\(constant.value) \(constant.unit)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(themeManager.current.accent.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.current.background.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    private var formulasList: some View {
        LazyVStack(spacing: 6) {
            ForEach(filteredFormulas) { formula in
                Button(action: {
                    onInsert(formula.expression)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(formula.category.color.opacity(0.2))
                            .frame(width: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formula.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.current.textPrimary)
                            Text(formula.display)
                                .font(.system(.title3, design: .serif))
                                .foregroundColor(formula.category.color)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formula.category.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(themeManager.current.accent.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.current.background.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}
