// ScientificCalculator/UI/Components/PhysicsReference.swift
// Unified Physics Reference: Formula Library with Lab Integration

import SwiftUI

struct PhysicsReference: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEquation: PhysicsEquation?
    
    var body: some View {
        NavigationStack {
            List(PhysicsModule.allModules) { module in
                Section(header: Text(module.name).foregroundColor(module.color)) {
                    let moduleEquations = PhysicsEquation.allEquations.filter { $0.moduleId == module.id }
                    
                    if moduleEquations.isEmpty {
                        Text("No equations added yet.").font(.caption).foregroundColor(.secondary)
                    } else {
                        ForEach(moduleEquations) { eq in
                            EquationRow(equation: eq)
                                .onTapGesture { selectedEquation = eq }
                        }
                    }
                }
            }
            .navigationTitle("Physics Reference")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedEquation) { eq in
                EquationDetailView(equation: eq)
            }
        }
        .background(themeManager.current.background)
    }
}

struct EquationRow: View {
    let equation: PhysicsEquation
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(equation.name).font(.headline)
            Text(equation.plainText).font(.system(.subheadline, design: .monospaced)).foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
}

struct EquationDetailView: View {
    let equation: PhysicsEquation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(equation.name).font(.title.bold())
                    
                    SectionHeader(title: "Formula")
                    Text(equation.plainText)
                        .font(.system(.title2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    
                    SectionHeader(title: "Derivation")
                    ForEach(equation.derivation) { step in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(step.stepNumber).").bold()
                                Text(step.physicalPrinciple).font(.caption).padding(4).background(Color.secondary.opacity(0.2)).cornerRadius(4)
                            }
                            Text(step.explanation).font(.subheadline)
                            Text(step.expression).font(.system(.caption, design: .monospaced)).foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    Spacer()
                    
                    Button(action: { /* Link to lab logic */ }) {
                        Label("Open in Physics Lab", systemImage: "flask.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title).font(.headline).foregroundColor(.secondary)
    }
}
