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
        LazyVGrid(columns: columns, spacing: 12) {
            // Row 1: Clear, Delete, Pow, Div
            Group {
                CalculatorButton(label: "AC", color: theme.current.buttonDestructive, textColor: .white, action: onClear)
                CalculatorButton(label: "⌫", color: theme.current.buttonScientific, textColor: theme.current.textPrimary, action: onDelete)
                CalculatorButton(label: "^", color: theme.current.buttonScientific, textColor: theme.current.textPrimary, action: { onKeyPress("^") })
                CalculatorButton(label: "÷", color: theme.current.buttonOperator, textColor: .white, action: { onKeyPress("/") })
            }
            
            // Row 2: 7, 8, 9, Mul
            Group {
                numBtn("7")
                numBtn("8")
                numBtn("9")
                opBtn("×", "*")
            }
            
            // Row 3: 4, 5, 6, Sub
            Group {
                numBtn("4")
                numBtn("5")
                numBtn("6")
                opBtn("-", "-")
            }
            
            // Row 4: 1, 2, 3, Add
            Group {
                numBtn("1")
                numBtn("2")
                numBtn("3")
                opBtn("+", "+")
            }
            
            // Row 5: 0, ., Ans, =
            Group {
                CalculatorButton(label: "0", color: theme.current.buttonNumber, textColor: theme.current.textPrimary, action: { onKeyPress("0") })
                CalculatorButton(label: ".", color: theme.current.buttonNumber, textColor: theme.current.textPrimary, action: { onKeyPress(".") })
                CalculatorButton(label: "Ans", color: theme.current.buttonScientific, textColor: theme.current.textPrimary, action: { onKeyPress("Ans") })
                CalculatorButton(label: "=", color: theme.current.buttonAction, textColor: .white, action: onEvaluate)
            }
        }
        .padding()
    }
    
    // Helpers
    func numBtn(_ label: String) -> some View {
        CalculatorButton(
            label: label,
            color: theme.current.buttonNumber,
            textColor: theme.current.textPrimary,
            action: { onKeyPress(label) }
        )
    }
    
    func opBtn(_ label: String, _ value: String) -> some View {
        CalculatorButton(
            label: label,
            color: theme.current.buttonOperator,
            textColor: .white,
            action: { onKeyPress(value) }
        )
    }
}
