// UI/Dashboard/DashboardConstantsCard.swift
import SwiftUI

struct DashboardConstantsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // Grouped constants for quick access
    let constantGroups: [(String, [(String, String)])] = [
        ("Mechanics", [
            ("g", "9.80665"),
            ("G", "6.674e-11"),
        ]),
        ("Universal", [
            ("c", "299792458"),
            ("h", "6.626e-34"),
            ("π", "PI"),
            ("e", "E"),
        ]),
        ("Electromagnetism", [
            ("e⁻", "1.602e-19"),
            ("ke", "8.988e9"),
        ]),
        ("Thermo / Quantum", [
            ("kB", "1.381e-23"),
            ("R", "8.314"),
            ("NA", "6.022e23"),
            ("me", "9.109e-31"),
        ]),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Constants", systemImage: "atom")
                .font(.headline)
            
            ForEach(constantGroups, id: \.0) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.0)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 55))], spacing: 6) {
                        ForEach(group.1, id: \.0) { symbol, value in
                            Button(action: { viewModel.insertText(value) }) {
                                VStack(spacing: 1) {
                                    Text(symbol)
                                        .font(.system(.caption, design: .serif))
                                        .bold()
                                    if value != "PI" && value != "E" {
                                        Text(value)
                                            .font(.system(.caption2, design: .monospaced))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(themeManager.current.background)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.current.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
