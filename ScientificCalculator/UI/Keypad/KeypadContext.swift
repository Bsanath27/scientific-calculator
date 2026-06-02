// UI/Keypad/KeypadContext.swift
// Scientific Calculator - Contextual Highlighting Engine

import SwiftUI
import Combine

// MARK: - Button Category
/// Every calculator button belongs to exactly one category.
/// The highlighting engine works at the category level, not per-button.
enum ButtonCategory: String, Hashable, CaseIterable {
    case digit          // 0-9, .
    case basicOp        // + - × ÷ ^
    case equals         // =
    case openParen      // (
    case closeParen     // )
    case function_      // sin, cos, ln, √, etc.
    case constant       // π, e
    case variable       // user-defined variable, Ans
    case clear          // AC, ⌫
    case special        // !, Σ, ∫, d/dx, lim
    case comma          // , (for multi-arg functions)
}

/// The visual weight a button should render with.
enum ButtonHighlight {
    case primary        // fully highlighted — strongly suggested next input
    case normal         // available, no special emphasis
    case dimmed         // not a valid next token; still tappable but visually faded
}

// MARK: - Context Engine

/// Feed this engine the current raw expression string and it publishes
/// a `ButtonCategory → ButtonHighlight` map.
@MainActor
final class KeypadContextEngine: ObservableObject {

    @Published private(set) var highlights: [ButtonCategory: ButtonHighlight] = [:]

    init() {
        update(expression: "")
    }

    func update(expression: String) {
        let map = compute(expression: expression)
        if map != highlights { highlights = map }
    }

    private func compute(expression: String) -> [ButtonCategory: ButtonHighlight] {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return start() }
        let last = lastMeaningfulToken(in: trimmed)
        let parenBalance = openParenCount(in: trimmed) - closeParenCount(in: trimmed)
        return rules(last: last, parenBalance: parenBalance, expression: trimmed)
    }

    private func start() -> [ButtonCategory: ButtonHighlight] {
        var m = allNormal()
        m[.digit] = .primary; m[.function_] = .primary; m[.constant] = .primary; m[.variable] = .primary; m[.openParen] = .primary
        m[.basicOp] = .dimmed; m[.equals] = .dimmed; m[.closeParen] = .dimmed; m[.special] = .dimmed; m[.comma] = .dimmed
        return m
    }

    private func rules(last: TokenKind, parenBalance: Int, expression: String) -> [ButtonCategory: ButtonHighlight] {
        var m = allNormal()
        switch last {
        case .digit, .decimal:
            m[.basicOp] = .primary; m[.equals] = .primary; m[.special] = .primary
            m[.closeParen] = parenBalance > 0 ? .primary : .dimmed
        case .operator_, .openParen, .comma:
            m[.digit] = .primary; m[.function_] = .primary; m[.constant] = .primary; m[.variable] = .primary; m[.openParen] = .primary
            m[.basicOp] = .dimmed; m[.equals] = .dimmed; m[.closeParen] = .dimmed
        case .closeParen, .constant, .variable:
            m[.basicOp] = .primary; m[.equals] = .primary; m[.special] = .primary
            m[.closeParen] = parenBalance > 0 ? .primary : .dimmed
        case .function_:
            m[.openParen] = .primary
            m[.digit] = .dimmed; m[.basicOp] = .dimmed; m[.equals] = .dimmed
        case .unknown: m = allNormal()
        }
        m[.clear] = .normal
        return m
    }

    private enum TokenKind {
        case digit, decimal, operator_, openParen, closeParen
        case function_, constant, variable, comma, unknown
    }

    private func lastMeaningfulToken(in expr: String) -> TokenKind {
        let trimmed = expr.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .unknown }
        let operators: Set<Character> = ["+", "-", "×", "÷", "^", "*", "/"]
        if let last = trimmed.last {
            if last == "(" { return .openParen }
            if last == ")" { return .closeParen }
            if last == "," { return .comma }
            if last == "." { return .decimal }
            if last.isNumber { return .digit }
            if operators.contains(last) { return .operator_ }
        }
        let functions = ["sin", "cos", "tan", "asin", "acos", "atan", "ln", "log", "√", "abs", "∫", "d/dx", "lim", "Σ"]
        for fn in functions where trimmed.hasSuffix(fn) { return .function_ }
        if let last = trimmed.last, last.isLetter { return .variable }
        return .unknown
    }

    private func openParenCount(in expr: String) -> Int { expr.filter { $0 == "(" }.count }
    private func closeParenCount(in expr: String) -> Int { expr.filter { $0 == ")" }.count }
    private func allNormal() -> [ButtonCategory: ButtonHighlight] {
        var m: [ButtonCategory: ButtonHighlight] = [:]
        for cat in ButtonCategory.allCases { m[cat] = .normal }; return m
    }
}

// Environment Key for Button Category
struct ButtonCategoryKey: EnvironmentKey {
    static let defaultValue: ButtonCategory = .digit
}

extension EnvironmentValues {
    var buttonCategory: ButtonCategory {
        get { self[ButtonCategoryKey.self] }
        set { self[ButtonCategoryKey.self] = newValue }
    }
}
