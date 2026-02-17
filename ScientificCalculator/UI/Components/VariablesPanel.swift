// UI/Components/VariablesPanel.swift
// Scientific Calculator - User-Defined Variables Panel

import SwiftUI

struct VariablesPanel: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var newName: String = ""
    @State private var newValue: String = ""
    @State private var editingVariable: String? = nil
    @State private var editValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("Variables", systemImage: "textformat.abc")
                    .font(.headline)
                    .foregroundColor(themeManager.current.textPrimary)
                Spacer()
                Text("\(viewModel.variables.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(themeManager.current.buttonScientific)
                    .cornerRadius(8)
            }
            .padding()
            .background(themeManager.current.displayBackground)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    // Add new variable row
                    HStack(spacing: 8) {
                        TextField("name", text: $newName)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 80)
                            .padding(8)
                            .background(themeManager.current.background)
                            .cornerRadius(6)
                        
                        Text("=")
                            .foregroundColor(.secondary)
                            .bold()
                        
                        TextField("value", text: $newValue)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(themeManager.current.background)
                            .cornerRadius(6)
                            .onSubmit { addVariable() }
                        
                        Button(action: addVariable) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.current.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(newName.isEmpty || newValue.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(themeManager.current.surface.opacity(0.5))
                    .cornerRadius(8)
                    
                    // Existing variables
                    if viewModel.variables.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No variables defined")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Type 'm = 9.81' or add above")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(viewModel.variables.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                            variableRow(name: name, value: value)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 400)
        .background(themeManager.current.surface)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func variableRow(name: String, value: Double) -> some View {
        HStack(spacing: 8) {
            // Tap to insert
            Button(action: { viewModel.insertText(name) }) {
                Text(name)
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .foregroundColor(themeManager.current.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(themeManager.current.accent.opacity(0.12))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Insert '\(name)' into expression")
            
            Spacer()
            
            // Editable value
            if editingVariable == name {
                TextField("", text: $editValue)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 100)
                    .padding(6)
                    .background(themeManager.current.background)
                    .cornerRadius(4)
                    .onSubmit {
                        if let val = Double(editValue) {
                            viewModel.updateVariable(name: name, value: val)
                        }
                        editingVariable = nil
                    }
            } else {
                Button(action: {
                    editValue = formatValue(value)
                    editingVariable = name
                }) {
                    Text(formatValue(value))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(themeManager.current.textPrimary)
                }
                .buttonStyle(.plain)
                .help("Click to edit value")
            }
            
            // Delete
            Button(action: { viewModel.deleteVariable(name: name) }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.current.background.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func addVariable() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty,
              name.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil,
              let val = Double(newValue) else { return }
        viewModel.addVariable(name: name, value: val)
        newName = ""
        newValue = ""
    }
    
    private func formatValue(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e10 {
            return String(format: "%.0f", v)
        }
        return String(format: "%.6g", v)
    }
}
