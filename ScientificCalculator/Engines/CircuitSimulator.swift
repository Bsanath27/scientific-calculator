// Engines/CircuitSimulator.swift
// Scientific Calculator - Nodal Analysis Engine (MNA)

import Foundation
import Accelerate

/// Represents a component in a circuit
struct CircuitComponent: Identifiable, Codable {
    let id: UUID
    var type: ComponentType
    var value: Double // Resistance, Capacitance, Inductance, Voltage, Current
    var nodes: [Int] // Typically [node1, node2]
    
    enum ComponentType: String, CaseIterable, Codable {
        case resistor = "R"
        case capacitor = "C"
        case inductor = "L"
        case voltageSource = "V"
        case currentSource = "I"
        case sw = "Switch"
    }
}

/// Solution containing node voltages and branch currents
struct CircuitSolution {
    let nodeVoltages: [Int: Double] // Node index -> Voltage
    let branchCurrents: [UUID: Double] // Component ID -> Current
}

/// Nodal Analysis Engine (Modified Nodal Analysis)
class CircuitSimulator {
    
    /// Solves a DC/Instantaneous circuit state
    /// - Parameter components: List of components
    /// - Returns: Solution or nil if unsolvable
    func solve(components: [CircuitComponent]) -> CircuitSolution? {
        // 1. Map nodes to indices (Node 0 is always Ground)
        var nodeMap = Set<Int>()
        for comp in components {
            for node in comp.nodes {
                nodeMap.insert(node)
            }
        }
        
        let sortedNodes = Array(nodeMap).sorted()
        let n = sortedNodes.count - 1 // Number of non-ground nodes
        if n <= 0 { return nil }
        
        // 2. Identify voltage sources for MNA matrix expansion
        let vSources = components.filter { $0.type == .voltageSource }
        let m = vSources.count
        let size = n + m
        
        var matrix = [[Double]](repeating: [Double](repeating: 0.0, count: size), count: size)
        var rhs = [Double](repeating: 0.0, count: size)
        
        // 3. Populate Matrix G (Conductance) and RHS (Current Sources)
        for comp in components {
            let idx1 = sortedNodes.firstIndex(of: comp.nodes[0])! - 1
            let idx2 = comp.nodes.count > 1 ? sortedNodes.firstIndex(of: comp.nodes[1])! - 1 : -1
            
            switch comp.type {
            case .resistor:
                let g = 1.0 / comp.value
                applyConductance(matrix: &matrix, i: idx1, j: idx2, g: g)
            case .currentSource:
                if idx1 >= 0 { rhs[idx1] -= comp.value }
                if idx2 >= 0 { rhs[idx2] += comp.value }
            case .sw:
                // For now, treat open switch as high resistance, closed as low
                let g = comp.value > 0.5 ? 1e6 : 1e-9 // 1M Ohm vs 1n Ohm
                applyConductance(matrix: &matrix, i: idx1, j: idx2, g: g)
            case .capacitor, .inductor:
                // Instantaneous model (treat capacitor as voltage source with prev voltage, etc.)
                // For pure DC analysis, C is open, L is short.
                let g = comp.type == .capacitor ? 1e-12 : 1e6
                applyConductance(matrix: &matrix, i: idx1, j: idx2, g: g)
            default: break
            }
        }
        
        // 4. Populate Matrix B (Voltage Source Couplings) and RHS (Voltage Values)
        for (index, vSource) in vSources.enumerated() {
            let row = n + index
            let idx1 = sortedNodes.firstIndex(of: vSource.nodes[0])! - 1
            let idx2 = vSource.nodes.count > 1 ? sortedNodes.firstIndex(of: vSource.nodes[1])! - 1 : -1
            
            if idx1 >= 0 {
                matrix[idx1][row] += 1
                matrix[row][idx1] += 1
            }
            if idx2 >= 0 {
                matrix[idx2][row] -= 1
                matrix[row][idx2] -= 1
            }
            rhs[row] = vSource.value
        }
        
        // 5. Solve Linear System: AX = B
        guard let x = solveLinearSystem(A: matrix, B: rhs) else { return nil }
        
        // 6. Format Result
        var nodeVoltages: [Int: Double] = [0: 0.0] // Node 0 is 0V
        for i in 0..<n {
            nodeVoltages[sortedNodes[i+1]] = x[i]
        }
        
        var branchCurrents: [UUID: Double] = [:]
        for comp in components {
            let v1 = nodeVoltages[comp.nodes[0]] ?? 0.0
            let v2 = comp.nodes.count > 1 ? (nodeVoltages[comp.nodes[1]] ?? 0.0) : 0.0
            
            switch comp.type {
            case .resistor:
                branchCurrents[comp.id] = (v1 - v2) / comp.value
            case .voltageSource:
                // Current is in the second part of X
                if let idx = vSources.firstIndex(where: { $0.id == comp.id }) {
                    branchCurrents[comp.id] = x[n + idx]
                }
            default:
                branchCurrents[comp.id] = 0.0
            }
        }
        
        return CircuitSolution(nodeVoltages: nodeVoltages, branchCurrents: branchCurrents)
    }
    
    private func applyConductance(matrix: inout [[Double]], i: Int, j: Int, g: Double) {
        if i >= 0 { matrix[i][i] += g }
        if j >= 0 { matrix[j][j] += g }
        if i >= 0 && j >= 0 {
            matrix[i][j] -= g
            matrix[j][i] -= g
        }
    }
    
    private func solveLinearSystem(A: [[Double]], B: [Double]) -> [Double]? {
        let n = Int32(B.count)
        var flatA = A.flatMap { $0 }
        var bMutable = B
        var pivots = [Int32](repeating: 0, count: Int(n))
        var info: Int32 = 0
        
        // LU Factorization using dgesv_
        var nVar = n
        var nrhs: Int32 = 1
        dgesv_(&nVar, &nrhs, &flatA, &nVar, &pivots, &bMutable, &nVar, &info)
        
        if info == 0 {
            return bMutable
        } else {
            return nil
        }
    }
}
