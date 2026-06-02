// UI/Components/ExpressionInputView.swift
// Scientific Calculator - Expression Input with Parenthesis Highlighting

import SwiftUI

/// A custom expression input that highlights unmatched parentheses in red
struct ExpressionInputView: View {
    @Binding var expression: String
    var onSubmit: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalculatorViewModel
    
    /// List of tokens in the current expression
    private var tokens: [Token] {
        var lexer = Tokenizer(input: expression)
        let result = lexer.tokenize()
        if case .success(let positionedTokens) = result {
            return positionedTokens.map { $0.token }.filter { $0 != .eof }
        }
        return []
    }
    
    /// List of syntax errors in the current expression
    private var syntaxErrors: [SyntaxError] {
        guard !expression.isEmpty else { return [] }
        return SyntaxValidator.validate(expression)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Multi-line Tokenized Display
            ScrollView {
                VStack(alignment: .trailing, spacing: 8) {
                    // We use Flow layout-like behavior or just a wrapping HStack
                    // For simplicity in SwiftUI 4+, we can use a lazy grid or custom layout
                    // Here we'll use a simple wrapping logic if possible, or just a ScrollView
                    
                    if expression.isEmpty {
                        Text("0")
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(themeManager.current.textSecondary.opacity(0.4))
                            .padding(.horizontal)
                    } else {
                        // Wrapping tokens flow
                        WrappingHStack(horizontalSpacing: 4, verticalSpacing: 8) {
                            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                                ExpressionTokenView(token: token, isSelected: false)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(minHeight: 100, maxHeight: 200)
            
            // Result & Show Work Area
            HStack {
                if !viewModel.result.isEmpty {
                    Button(action: { viewModel.cycleResultFormat() }) {
                        Text(viewModel.result)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.current.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Show Work Badge
                if !viewModel.derivationSteps.isEmpty || viewModel.isEvaluatingSymbolic {
                    Button(action: { viewModel.toggleWork() }) {
                        HStack(spacing: 6) {
                            if viewModel.isEvaluatingSymbolic {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text("Show Work")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.showWork ? themeManager.current.accent : themeManager.current.accent.opacity(0.1))
                        )
                        .foregroundColor(viewModel.showWork ? .white : themeManager.current.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            // Steps Overlay
            if viewModel.showWork && !viewModel.derivationSteps.isEmpty {
                WorkStepsView(steps: viewModel.derivationSteps, finalResult: viewModel.result)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Syntax Errors
            if let firstError = syntaxErrors.first {
                Text(firstError.message)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
    }
}

/// Simple wrapping layout for tokens
struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeight + verticalSpacing
                maxHeight = 0
            }
            x += size.width + horizontalSpacing
            maxHeight = max(maxHeight, size.height)
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + verticalSpacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + horizontalSpacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}
