// UI/Notebook/BlockViews.swift
// Scientific Calculator - Notebook Block Views

import SwiftUI

struct BlockView: View {
    let block: NotebookBlock
    @ObservedObject var viewModel: NotebookViewModel
    @ObservedObject var theme: ThemeManager
    
    @State private var isEditing = false
    @State private var editContent = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp / Gutter
            VStack {
                Text(block.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if !isEditing {
                    Button(action: { startEditing() }) {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(theme.current.accent.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .frame(width: 50, alignment: .trailing)
            .padding(.top, 4)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    HStack {
                        TextField("Edit content...", text: $editContent, onCommit: {
                            commitEdit()
                        })
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(theme.current.surface)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.current.accent, lineWidth: 1))
                        
                        Button("Done") { commitEdit() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        
                        Button("Cancel") { isEditing = false }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                } else {
                    switch block.type {
                    case .calculation(let expr, let result):
                        CalculationBlock(expression: expr, result: result, theme: theme)
                            .onTapGesture(count: 2) { startEditing() }
                    case .text(let content):
                        TextBlock(content: content, theme: theme)
                            .onTapGesture(count: 2) { startEditing() }
                    case .variableDefinition(let name, let value, let expr):
                        VariableBlock(name: name, value: value, expression: expr, theme: theme)
                            .onTapGesture(count: 2) { startEditing() }
                    case .error(let message):
                        ErrorBlock(message: message, theme: theme)
                            .onTapGesture(count: 2) { startEditing() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
    
    private func startEditing() {
        switch block.type {
        case .calculation(let expr, _): editContent = expr
        case .text(let content): editContent = content
        case .variableDefinition(let name, _, let expr): editContent = "\(name) = \(expr)"
        case .error: editContent = "" // Or some heuristic
        }
        isEditing = true
    }
    
    private func commitEdit() {
        viewModel.updateBlock(id: block.id, newContent: editContent)
        isEditing = false
    }
}

// MARK: - Subviews

struct CalculationBlock: View {
    let expression: String
    let result: String
    var theme: ThemeManager
    
    private var formattedResult: String {
        if result.isLatex {
            return LatexFormatter.format(result)
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(expression)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(theme.current.textPrimary)
            
            HStack {
                Image(systemName: "equal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formattedResult)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(theme.current.accent)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
        .background(theme.current.surface)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TextBlock: View {
    let content: String
    var theme: ThemeManager
    
    var body: some View {
        Text(LocalizedStringKey(content))
            .font(.body)
            .foregroundColor(theme.current.textPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VariableBlock: View {
    let name: String
    let value: String
    let expression: String
    var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "cube.box.fill")
                    .font(.caption)
                    .foregroundColor(theme.current.accent)
                Text(name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                Text("=")
                    .foregroundColor(.secondary)
                Text(expression)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer().frame(width: 24)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(theme.current.accent)
            }
        }
        .padding(10)
        .background(theme.current.surface.opacity(0.4))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.current.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ErrorBlock: View {
    let message: String
    var theme: ThemeManager
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundColor(.red)
                .padding(.top, 2)
            Text(message)
                .font(.callout)
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}
