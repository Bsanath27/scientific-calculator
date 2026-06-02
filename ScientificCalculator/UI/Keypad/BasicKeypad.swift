// UI/Keypad/BasicKeypad.swift
// Scientific Calculator - Basic Arithmetic Keypad

import SwiftUI

struct BasicKeypad: View {
    @ObservedObject var theme: ThemeManager
    var onKeyPress: (String) -> Void
    var onEvaluate: () -> Void
    var onClear: () -> Void
    var onDelete: () -> Void
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = DeviceLayout.isCompact(width: geo.size.width)
            LazyVGrid(columns: columns, spacing: isCompact ? 8 : 12) {
                // Row 1: Clear, Delete, Pow, Div
                HighlightedButton(label: "AC", category: .clear, action: onClear)
                HighlightedButton(label: "⌫", category: .clear, action: onDelete)
                HighlightedButton(label: "^", category: .basicOp, action: { onKeyPress("^") })
                HighlightedButton(label: "÷", category: .basicOp, action: { onKeyPress("/") })
                
                // Row 2: 7, 8, 9, Mul
                HighlightedButton(label: "7", category: .digit, action: { onKeyPress("7") })
                HighlightedButton(label: "8", category: .digit, action: { onKeyPress("8") })
                HighlightedButton(label: "9", category: .digit, action: { onKeyPress("9") })
                HighlightedButton(label: "×", category: .basicOp, action: { onKeyPress("*") })
                
                // Row 3: 4, 5, 6, Sub
                HighlightedButton(label: "4", category: .digit, action: { onKeyPress("4") })
                HighlightedButton(label: "5", category: .digit, action: { onKeyPress("5") })
                HighlightedButton(label: "6", category: .digit, action: { onKeyPress("6") })
                HighlightedButton(label: "-", category: .basicOp, action: { onKeyPress("-") })
                
                // Row 4: 1, 2, 3, Add
                HighlightedButton(label: "1", category: .digit, action: { onKeyPress("1") })
                HighlightedButton(label: "2", category: .digit, action: { onKeyPress("2") })
                HighlightedButton(label: "3", category: .digit, action: { onKeyPress("3") })
                HighlightedButton(label: "+", category: .basicOp, action: { onKeyPress("+") })
                
                // Row 5: 0, ., Ans, =
                HighlightedButton(label: "0", category: .digit, action: { onKeyPress("0") })
                HighlightedButton(label: ".", category: .digit, action: { onKeyPress(".") })
                HighlightedButton(label: "Ans", category: .variable, action: { onKeyPress("Ans") })
                HighlightedButton(label: "=", category: .equals, action: onEvaluate)
            }
        }
    }
}
