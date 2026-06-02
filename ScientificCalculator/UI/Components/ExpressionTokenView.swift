// UI/Components/ExpressionTokenView.swift
// Scientific Calculator - Interactive Expression Tokens (Luxe UI)

import SwiftUI

struct ExpressionTokenView: View {
    let token: Token
    let isSelected: Bool
    @EnvironmentObject var theme: ThemeManager
    
    @EnvironmentObject var viewModel: CalculatorViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tokenLabel)
                .font(.system(.body, design: .monospaced))
            
            // Unit Tag (Prompt 6)
            if let unit = viewModel.units[tokenValue] {
                Text(unit)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(theme.current.accent.opacity(0.2))
                    .foregroundColor(theme.current.accent)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? theme.current.accent : Color.clear, lineWidth: 2)
        )
        .foregroundColor(textColor)
        .shadow(color: isSelected ? theme.current.accent.opacity(0.3) : .clear, radius: 4)
        .contextMenu {
            if isNumber || isVariable {
                Section("Attach Unit") {
                    Button("Distance (m)") { viewModel.attachUnit(to: tokenValue, unit: "m") }
                    Button("Mass (kg)") { viewModel.attachUnit(to: tokenValue, unit: "kg") }
                    Button("Time (s)") { viewModel.attachUnit(to: tokenValue, unit: "s") }
                    Button("Force (N)") { viewModel.attachUnit(to: tokenValue, unit: "N") }
                    Button("Energy (J)") { viewModel.attachUnit(to: tokenValue, unit: "J") }
                    Button("Power (W)") { viewModel.attachUnit(to: tokenValue, unit: "W") }
                    Button("Pressure (Pa)") { viewModel.attachUnit(to: tokenValue, unit: "Pa") }
                }
                Divider()
                Button("Clear Unit", role: .destructive) { viewModel.units.removeValue(forKey: tokenValue) }
            }
        }
    }
    
    private var isNumber: Bool {
        if case .number = token { return true }
        return false
    }
    
    private var isVariable: Bool {
        if case .variable = token { return true }
        return false
    }
    
    private var tokenValue: String {
        switch token {
        case .number(let v): return "\(v)"
        case .variable(let n): return n
        default: return tokenLabel
        }
    }
    
    private var tokenLabel: String {
        switch token {
        case .number(let val): return String(format: "%.4g", val)
        case .binaryOperator(let op): return op.rawValue
        case .leftParen: return "("
        case .rightParen: return ")"
        case .comma: return ","
        case .function(let fn): return fn.rawValue
        case .constant(let c): return c.rawValue
        case .variable(let v): return v
        case .eof: return ""
        }
    }
    
    private var backgroundColor: Color {
        switch token {
        case .number, .constant: return theme.current.accent.opacity(0.1)
        case .binaryOperator: return theme.current.textSecondary.opacity(0.1)
        case .function: return theme.current.opticsGreen.opacity(0.15)
        case .variable: return theme.current.mechanicsBlue.opacity(0.15)
        default: return theme.current.background.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        switch token {
        case .number, .constant: return theme.current.accent
        case .function: return theme.current.opticsGreen
        case .variable: return theme.current.mechanicsBlue
        default: return theme.current.textPrimary
        }
    }
}
