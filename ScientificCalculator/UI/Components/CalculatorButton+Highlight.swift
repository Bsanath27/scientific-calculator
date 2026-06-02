// UI/Components/CalculatorButton+Highlight.swift
// Scientific Calculator - Button Highlighting & Styling

import SwiftUI

// MARK: - View Modifiers

struct ButtonHighlightModifier: ViewModifier {
    let highlight: ButtonHighlight
    let theme: ColorPalette

    func body(content: Content) -> some View {
        content
            .opacity(highlight == .dimmed ? 0.35 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.accent.opacity(highlight == .primary ? 0.6 : 0), lineWidth: 2)
                    .shadow(color: theme.accent.opacity(highlight == .primary ? 0.6 : 0), radius: 8)
            )
            .scaleEffect(highlight == .primary ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlight)
    }
}

extension View {
    func highlightedStyle(highlight: ButtonHighlight, theme: ColorPalette) -> some View {
        modifier(ButtonHighlightModifier(highlight: highlight, theme: theme))
    }
}

// MARK: - Highlighted Button Wrapper

struct HighlightedButton: View {
    let label: String
    let category: ButtonCategory
    let action: () -> Void
    
    // Optional styling overrides
    var baseColor: Color? = nil
    var textColor: Color? = nil
    var isDoubleWidth: Bool = false
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var context: KeypadContextEngine
    
    var body: some View {
        let highlight = context.highlights[category] ?? .normal
        let theme = themeManager.current
        
        // Use predefined colors based on category if not overridden
        let backgroundColor = baseColor ?? defaultColor(for: category, theme: theme)
        let foregroundColor = textColor ?? defaultTextColor(for: category, theme: theme)
        
        CalculatorButton(
            label: label,
            color: backgroundColor,
            textColor: foregroundColor,
            isDoubleWidth: isDoubleWidth,
            action: action
        )
        .environment(\.buttonCategory, category)
        .highlightedStyle(highlight: highlight, theme: theme)
    }
    
    private func defaultColor(for cat: ButtonCategory, theme: ColorPalette) -> Color {
        switch cat {
        case .digit: return theme.surface
        case .basicOp: return theme.displayBackground
        case .equals: return theme.accent
        case .clear: return theme.modernRed.opacity(0.8)
        case .function_, .special: return theme.displayBackground.opacity(0.7)
        case .constant, .variable: return theme.surface.opacity(0.8)
        default: return theme.surface
        }
    }
    
    private func defaultTextColor(for cat: ButtonCategory, theme: ColorPalette) -> Color {
        switch cat {
        case .equals: return .white
        case .clear: return .white
        default: return theme.textPrimary
        }
    }
}
