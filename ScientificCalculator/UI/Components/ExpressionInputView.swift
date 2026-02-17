// UI/Components/ExpressionInputView.swift
// Scientific Calculator - Expression Input with Parenthesis Highlighting

import SwiftUI

/// A custom expression input that highlights unmatched parentheses in red
struct ExpressionInputView: View {
    @Binding var expression: String
    var onSubmit: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    /// List of syntax errors in the current expression
    private var syntaxErrors: [SyntaxError] {
        guard !expression.isEmpty else { return [] }
        return SyntaxValidator.validate(expression)
    }
    
    /// Build an AttributedString with syntax-aware highlighting
    private var highlightedExpression: AttributedString {
        let chars = Array(expression)
        let errors = syntaxErrors
        
        var result = AttributedString()
        for (i, ch) in chars.enumerated() {
            var attrChar = AttributedString(String(ch))
            
            // Check if this character is part of an error range
            if let error = errors.first(where: { i >= $0.position && i < $0.position + $0.length }) {
                attrChar.foregroundColor = .red
                attrChar.font = .system(size: 48, weight: .bold, design: .monospaced)
            } else if ch == "(" || ch == ")" {
                attrChar.foregroundColor = Color(hex: 0xA3BE8C) // Matched/Normal green
                attrChar.font = .system(size: 48, weight: .light, design: .monospaced)
            } else {
                attrChar.font = .system(size: 48, weight: .light, design: .monospaced)
                attrChar.foregroundColor = themeManager.current.textPrimary
            }
            result += attrChar
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .trailing) {
                // Invisible TextField for actual editing
                TextField("0", text: $expression)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .foregroundColor(.clear) // Invisible text
                    .padding(.horizontal)
                    .onSubmit(onSubmit)
                    .accessibilityLabel("Expression input")
                
                // Overlay with highlighted text
                if !expression.isEmpty {
                    Text(highlightedExpression)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal)
                        .allowsHitTesting(false)
                } else {
                    Text("0")
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(themeManager.current.textSecondary.opacity(0.4))
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal)
                        .allowsHitTesting(false)
                }
            }
            
            // Syntax Error badge
            if let firstError = syntaxErrors.first {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(firstError.message)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.12))
                .cornerRadius(6)
                .padding(.trailing, 16)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.2), value: firstError.message)
            }
        }
    }
}
