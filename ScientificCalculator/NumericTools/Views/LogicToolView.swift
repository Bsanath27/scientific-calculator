// UI/Components/LogicToolView.swift
// Scientific Calculator - Logic Gate Simulator View (Luxe UI)

import SwiftUI

struct LogicToolView: View {
    @State private var gates: [LogicGate] = [LogicGate(type: .and)]
    @State private var truthTable: [[Bool]] = []
    @EnvironmentObject var theme: ThemeManager
    
    private let engine = LogicEngine()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Logic Gate Simulator")
                .font(.headline)
                .foregroundColor(theme.current.textPrimary)
            
            // Gate Configuration
            ForEach($gates) { $gate in
                HStack(spacing: 16) {
                    Picker("Gate Type", selection: $gate.type) {
                        ForEach(LogicGateType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<gate.inputs.count, id: \.self) { i in
                            Toggle("", isOn: $gate.inputs[i])
                                .toggleStyle(SwitchToggleStyle(tint: theme.current.accent))
                                .labelsHidden()
                        }
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(theme.current.textSecondary)
                    
                    Text(gate.output ? "TRUE" : "FALSE")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(gate.output ? theme.current.opticsGreen : theme.current.modernRed)
                        .frame(width: 60)
                }
                .padding()
                .background(theme.current.background.opacity(0.5))
                .cornerRadius(10)
            }
            
            Button(action: generateTable) {
                HStack {
                    Image(systemName: "tablecells")
                    Text("Generate Truth Table")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.current.accent.opacity(0.1))
                .foregroundColor(theme.current.accent)
                .cornerRadius(8)
            }
            
            if !truthTable.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Truth Table (A, B → Out)")
                        .font(.caption)
                        .foregroundColor(theme.current.textSecondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(0..<truthTable.count, id: \.self) { rowIndex in
                                HStack(spacing: 12) {
                                    ForEach(0..<truthTable[rowIndex].count, id: \.self) { colIndex in
                                        Text(truthTable[rowIndex][colIndex] ? "1" : "0")
                                            .font(.system(.caption, design: .monospaced))
                                            .frame(width: 20)
                                            .foregroundColor(truthTable[rowIndex][colIndex] ? theme.current.opticsGreen : theme.current.textPrimary)
                                        
                                        if colIndex == truthTable[rowIndex].count - 2 {
                                            Text("|")
                                                .foregroundColor(theme.current.divider)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(rowIndex % 2 == 0 ? theme.current.divider.opacity(0.1) : Color.clear)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(theme.current.displayBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private func generateTable() {
        guard let firstGate = gates.first else { return }
        truthTable = engine.generateTruthTable(inputCount: firstGate.inputs.count) { inputs in
            var tempGate = firstGate
            tempGate.inputs = inputs
            return tempGate.output
        }
    }
}
