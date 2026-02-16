// UI/Notebook/InputActionBar.swift
// Scientific Calculator - Input Action Bar

import SwiftUI

struct InputActionBar: View {
    @ObservedObject var viewModel: NotebookViewModel
    @ObservedObject var theme: ThemeManager
    
    @Binding var showKeypad: Bool
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.current.divider)
            
            HStack(spacing: 12) {
                // Keypad Toggle
                Button(action: { showKeypad.toggle() }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 20))
                        .foregroundColor(showKeypad ? theme.current.accent : .secondary)
                }
                .buttonStyle(.plain)
                
                // Input Field
                TextField("Calculate, define variables, or type # for notes...", text: $viewModel.currentInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(theme.current.surface)
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.processInput()
                        // Keep focus for rapid entry
                        isInputFocused = true
                    }
                
                // Quick Actions
                if viewModel.currentInput.isEmpty {
                    Button(action: {
                        viewModel.currentInput = "# "
                        isInputFocused = true
                    }) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.secondary)
                    }
                    .help("Add Text Note")
                } else {
                    // Send Button
                    Button(action: { viewModel.processInput() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.current.accent)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding()
            .background(theme.current.background) // blends with main bg
        }
    }
}
