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
        let category: ButtonCategory
    }
    
    let buttons: [SciButton] = [
        .init(label: "sin", value: "sin(", category: .function_), .init(label: "cos", value: "cos(", category: .function_), .init(label: "tan", value: "tan(", category: .function_), .init(label: "π", value: "pi", category: .constant),
        .init(label: "asin", value: "asin(", category: .function_), .init(label: "acos", value: "acos(", category: .function_), .init(label: "atan", value: "atan(", category: .function_), .init(label: "e", value: "e", category: .constant),
        .init(label: "sinh", value: "sinh(", category: .function_), .init(label: "cosh", value: "cosh(", category: .function_), .init(label: "tanh", value: "tanh(", category: .function_), .init(label: "^", value: "^", category: .basicOp),
        .init(label: "ln", value: "ln(", category: .function_), .init(label: "log", value: "log(", category: .function_), .init(label: "√", value: "sqrt(", category: .function_), .init(label: "!", value: "!", category: .special),
        .init(label: "∫", value: "integrate(", category: .function_), .init(label: "d/dx", value: "diff(", category: .function_), .init(label: "Σ", value: "sum(", category: .function_), .init(label: "(", value: "(", category: .openParen),
        .init(label: ")", value: ")", category: .closeParen), .init(label: "lim", value: "limit(", category: .function_), .init(label: "abs", value: "abs(", category: .function_), .init(label: ",", value: ",", category: .comma)
    ]
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = DeviceLayout.isCompact(width: geo.size.width)
            let cols = isCompact ? columns : Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            
            ScrollView {
                LazyVGrid(columns: cols, spacing: isCompact ? 6 : 10) {
                    ForEach(buttons, id: \.self) { btn in
                        HighlightedButton(
                            label: btn.label,
                            category: btn.category,
                            action: { onKeyPress(btn.value) }
                        )
                    }
                }
                .padding(isCompact ? 8 : 16)
            }
        }
        .background(theme.current.background)
    }
}
