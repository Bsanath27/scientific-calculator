// UI/Dashboard/DashboardConstantsCard.swift
import SwiftUI

struct DashboardConstantsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    let constants = [
        ("π", "PI"),
        ("e", "E"),
        ("c", "299792458"),
        ("G", "6.674e-11"),
        ("h", "6.626e-34"),
        ("g", "9.806")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scientific Constants", systemImage: "atom")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(constants, id: \.0) { symbol, value in
                    Button(action: { viewModel.insertText(value) }) {
                        VStack(spacing: 2) {
                            Text(symbol)
                                .font(.system(.body, design: .serif))
                                .bold()
                            Text(value == "PI" || value == "E" ? "" : value)
                                .font(.system(size: 8, design: .monospaced))
                                .lineLimit(1)
                                .foregroundColor(.secondary)
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
        .padding()
        .background(themeManager.current.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
