// NumericTools/CircuitEngine.swift
// Scientific Calculator - MNA (Modified Nodal Analysis) Solver

import Foundation
import Accelerate

/// Represents a component in a circuit
enum CircuitComponentType: String, Codable {
    case resistor = "R"
    case capacitor = "C"
    case inductor = "L"
    case voltageSource = "V"
    case currentSource = "I"
    case diode = "D"
}

struct CircuitComponent: Identifiable, Codable {
    let id: UUID
    let type: CircuitComponentType
    let value: Double
    let node1: Int
    let node2: Int
    var label: String
    
    init(type: CircuitComponentType, value: Double, node1: Int, node2: Int, label: String? = nil) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.node1 = node1
        self.node2 = node2
        self.label = label ?? "\(type.rawValue)\(Int.random(in: 1...999))"
    }
}

/// Result of a circuit simulation
struct CircuitSimulationResult {
    let nodeVoltages: [Int: Double]
    let branchCurrents: [String: Double]
    let timestamp: Double
}

/// Modified Nodal Analysis (MNA) Engine
final class CircuitEngine {
    
    /// Solves a DC circuit using MNA
    /// Returns a map of node ID to voltage
    func solveDC(components: [CircuitComponent]) -> CircuitSimulationResult {
        // 1. Identify unique nodes (excluding 0 which is ground)
        let nodes = Set(components.flatMap { [$0.node1, $0.node2] }).filter { $0 > 0 }
        let n = nodes.max() ?? 0
        
        // 2. Identify voltage sources (they increase the size of the matrix)
        let vSources = components.filter { $0.type == .voltageSource }
        let m = vSources.count
        
        let size = n + m
        guard size > 0 else { return CircuitSimulationResult(nodeVoltages: [:], branchCurrents: [:], timestamp: 0) }
        
        // Matrix A (size x size) and vector Z (size)
        var A = [Double](repeating: 0.0, count: size * size)
        var Z = [Double](repeating: 0.0, count: size)
        
        // 3. Populate G matrix (conductance)
        for comp in components {
            let val = comp.value
            let i = comp.node1
            let j = comp.node2
            
            switch comp.type {
            case .resistor:
                let g = 1.0 / val
                addConductance(&A, i: i, j: j, g: g, size: size)
                
            case .currentSource:
                if i > 0 { Z[i-1] -= val }
                if j > 0 { Z[j-1] += val }
                
            default: break
            }
        }
        
        // 4. Populate B matrix (voltage sources)
        for (idx, vSource) in vSources.enumerated() {
            let i = vSource.node1
            let j = vSource.node2
            let row = n + idx
            
            // Equation: Vi - Vj = Vsource
            if i > 0 {
                A[row * size + (i-1)] = 1.0
                A[(i-1) * size + row] = 1.0
            }
            if j > 0 {
                A[row * size + (j-1)] = -1.0
                A[(j-1) * size + row] = -1.0
            }
            Z[row] = vSource.value
        }
        
        // 5. Solve Ax = Z
        let x = solveLinearSystem(A: A, Z: Z, size: size)
        
        // 6. Extract results
        var nodeVoltages: [Int: Double] = [0: 0.0]
        for i in 1...n {
            nodeVoltages[i] = x[i-1]
        }
        
        var branchCurrents: [String: Double] = [:]
        for (idx, vSource) in vSources.enumerated() {
            branchCurrents[vSource.label] = x[n + idx]
        }
        
        return CircuitSimulationResult(nodeVoltages: nodeVoltages, branchCurrents: branchCurrents, timestamp: 0)
    }
    
    private func addConductance(_ A: inout [Double], i: Int, j: Int, g: Double, size: Int) {
        if i > 0 {
            A[(i-1) * size + (i-1)] += g
        }
        if j > 0 {
            A[(j-1) * size + (j-1)] += g
        }
        if i > 0 && j > 0 {
            A[(i-1) * size + (j-1)] -= g
            A[(j-1) * size + (i-1)] -= g
        }
    }
    
    private func solveLinearSystem(A: [Double], Z: [Double], size: Int) -> [Double] {
        var a = A
        var b = Z
        var n = Int32(size)
        var nrhs = Int32(1)
        var ipiv = [Int32](repeating: 0, count: size)
        var info: Int32 = 0
        
        dgesv_(&n, &nrhs, &a, &n, &ipiv, &b, &n, &info)
        
        if info != 0 {
            print("CircuitEngine: Matrix solve failed with info \(info)")
        }
        
        return b
    }
}
