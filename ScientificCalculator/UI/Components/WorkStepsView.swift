// UI/Components/WorkStepsView.swift
// Scientific Calculator - Step-by-Step Derivation View (Luxe UI)

import SwiftUI

struct WorkStepsView: View {
    let steps: [Node]
    let finalResult: String
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Derivation Steps")
                .font(.headline)
                .foregroundColor(theme.current.textPrimary)
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, node in
                        HStack(alignment: .top, spacing: 12) {
                            // Step Number Circle
                            ZStack {
                                Circle()
                                    .fill(theme.current.accent.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(theme.current.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // The expression at this step
                                Text(node.description)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(theme.current.textPrimary)
                                    .padding(.vertical, 4)
                                
                                // Explanation of what changed if not the first step
                                if index < steps.count - 1 {
                                    HStack {
                                        Image(systemName: "arrow.down")
                                            .font(.caption2)
                                        Text(getSimplificationLabel(from: node, to: steps[index + 1]))
                                            .font(.caption)
                                            .italic()
                                    }
                                    .foregroundColor(theme.current.textSecondary)
                                }
                            }
                        }
                        
                        if index < steps.count - 1 {
                            Divider()
                                .background(theme.current.divider)
                                .padding(.leading, 36)
                        }
                    }
                    
                    // Final Result Badge
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Result")
                                .font(.caption2)
                                .foregroundColor(theme.current.accent)
                            Text(finalResult)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(theme.current.textPrimary)
                        }
                        .padding()
                        .background(theme.current.accent.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.current.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .padding()
        .background(theme.current.displayBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private func getSimplificationLabel(from: Node, to: Node) -> String {
        // Simple heuristic to describe what happened
        switch from {
        case .binary(_, let op, _, _):
            return "Evaluating \(op.rawValue)"
        case .function(let name, _, _):
            return "Calculating \(name.rawValue)"
        case .unary(let op, _, _):
            return "Applying \(op.rawValue)"
        case .variable(let name, _):
            return "Substituting \(name)"
        default:
            return "Simplifying expression"
        }
    }
}
