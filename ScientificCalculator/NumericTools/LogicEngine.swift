// NumericTools/LogicEngine.swift
// Scientific Calculator - Bitwise Logic Gate Simulator

import Foundation

enum LogicGateType: String, CaseIterable, Codable {
    case and = "AND"
    case or = "OR"
    case not = "NOT"
    case xor = "XOR"
    case nand = "NAND"
    case nor = "NOR"
}

struct LogicGate: Identifiable, Codable {
    let id: UUID
    var type: LogicGateType
    var inputs: [Bool]
    
    init(type: LogicGateType, inputCount: Int = 2) {
        self.id = UUID()
        self.type = type
        self.inputs = [Bool](repeating: false, count: inputCount)
    }
    
    var output: Bool {
        switch type {
        case .and: return inputs.allSatisfy { $0 }
        case .or: return inputs.contains { $0 }
        case .not: return !inputs[0]
        case .xor: return inputs.filter { $0 }.count % 2 != 0
        case .nand: return !inputs.allSatisfy { $0 }
        case .nor: return !inputs.contains { $0 }
        }
    }
}

/// Digital Logic Simulation Engine
final class LogicEngine {
    
    /// Generates a truth table for a given set of inputs and an expression (simplified)
    func generateTruthTable(inputCount: Int, logic: ([Bool]) -> Bool) -> [[Bool]] {
        let rowCount = Int(pow(2.0, Double(inputCount)))
        var table: [[Bool]] = []
        
        for i in 0..<rowCount {
            var row: [Bool] = []
            for j in 0..<inputCount {
                // Extract bits
                let bit = (i >> (inputCount - 1 - j)) & 1
                row.append(bit == 1)
            }
            // Add result
            row.append(logic(row))
            table.append(row)
        }
        
        return table
    }
    
    /// Simplifies a simple boolean expression (Karnaugh Map Placeholder)
    func simplifyLogic(table: [[Bool]]) -> String {
        // This would normally involve Quine-McCluskey or K-Maps
        // For now, we'll return a placeholder string or a very basic SOP form
        return "SOP: " + table.filter { $0.last == true }
            .map { row in
                row.enumerated().dropLast().map { idx, val in
                    val ? "A\(idx)" : "!A\(idx)"
                }.joined(separator: "⋅")
            }.joined(separator: " + ")
    }
}
