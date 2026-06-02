// UI/Components/CalculatorButton.swift
// Scientific Calculator - Styled Button Component

import SwiftUI

/// Base button component for all keypad interactions.
struct CalculatorButton: View {
    let label: String
    let color: Color
    let textColor: Color
    var isDoubleWidth: Bool = false
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
