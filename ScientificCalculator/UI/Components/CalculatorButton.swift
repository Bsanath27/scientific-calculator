// UI/Components/CalculatorButton.swift
// Scientific Calculator - Styled Button Component

import SwiftUI

struct CalculatorButton: View {
    let label: String
    let color: Color
    let textColor: Color
    var width: CGFloat = 60
    var height: CGFloat = 60
    var isDoubleWidth: Bool = false
    let action: () -> Void
    
    // Environment theme (passed down or accessed via shared state)
    // For simplicity in this component, we rely on the color passed in.
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Responsive
                .aspectRatio(isDoubleWidth ? 2.1 : 1, contentMode: .fit) // Maintain shape
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Modern shape
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Button Press Animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
