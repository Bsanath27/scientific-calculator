// UI/Keypad/ScientificKeypad.swift
// Scientific Calculator - Scientific Functions Keypad

import SwiftUI

struct ScientificKeypad: View {
    @ObservedObject var theme: ThemeManager
    var onKeyPress: (String) -> Void
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    // Button Data Model
    struct SciButton: Hashable {
        let label: String
        let value: String // value to append
    }
    
    let buttons: [SciButton] = [
        .init(label: "sin", value: "sin("), .init(label: "cos", value: "cos("), .init(label: "tan", value: "tan("), .init(label: "π", value: "pi"),
        .init(label: "asin", value: "asin("), .init(label: "acos", value: "acos("), .init(label: "atan", value: "atan("), .init(label: "e", value: "e"),
        .init(label: "sinh", value: "sinh("), .init(label: "cosh", value: "cosh("), .init(label: "tanh", value: "tanh("), .init(label: "^", value: "^"),
        .init(label: "ln", value: "ln("), .init(label: "log", value: "log("), .init(label: "√", value: "sqrt("), .init(label: "!", value: "!"),
        .init(label: "∫", value: "integrate("), .init(label: "d/dx", value: "diff("), .init(label: "Σ", value: "sum("), .init(label: "(", value: "("),
        .init(label: ")", value: ")"), .init(label: "lim", value: "limit("), .init(label: "abs", value: "abs("), .init(label: ",", value: ",")
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(buttons, id: \.self) { btn in
                CalculatorButton(
                    label: btn.label,
                    color: theme.current.buttonScientific,
                    textColor: theme.current.textPrimary,
                    width: 50, // Slightly smaller for dense sci keypad
                    height: 40,
                    action: { onKeyPress(btn.value) }
                )
            }
        }
        .padding()
        .background(theme.current.background)
    }
}
