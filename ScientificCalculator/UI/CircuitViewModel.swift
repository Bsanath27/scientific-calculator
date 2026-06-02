// ViewModels/CircuitViewModel.swift
// Scientific Calculator - Circuit Simulator State Management

import SwiftUI
import Combine

class CircuitViewModel: ObservableObject {
    @Published var components: [CircuitComponent] = []
    @Published var wires: [Wire] = []
    @Published var solution: CircuitSolution?
    @Published var selectedComponentId: UUID?
    @Published var isSimulating: Bool = true
    @Published var showBridgePrompt: Bool = false
    
    private let simulator = CircuitSimulator()
    private var cancellables = Set<AnyCancellable>()
    
    struct Wire: Identifiable, Codable {
        let id: UUID
        var fromNode: Int
        var toNode: Int
        var points: [CGPoint] // Path on grid
    }
    
    init() {
        // Auto-solve when components change
        $components
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.analyze() }
            .store(in: &cancellables)
            
        // Initial circuit: Simple V + R
        resetToDefault()
    }
    
    func resetToDefault() {
        let vSource = CircuitComponent(id: UUID(), type: .voltageSource, value: 5.0, nodes: [1, 0])
        let resistor = CircuitComponent(id: UUID(), type: .resistor, value: 1000.0, nodes: [1, 0])
        components = [vSource, resistor]
    }
    
    func analyze() {
        guard isSimulating else { return }
        
        if let result = simulator.solve(components: components) {
            DispatchQueue.main.async {
                self.solution = result
                self.checkBridgeToLab()
            }
        }
    }
    
    func addComponent(_ type: CircuitComponent.ComponentType, at pos: CGPoint) {
        // Logic to find nearest grid nodes
        let node1 = Int(pos.x / 40) + Int(pos.y / 40) * 10
        let node2 = node1 + 1
        
        let newComp = CircuitComponent(id: UUID(), type: type, value: defaultValue(for: type), nodes: [node1, node2])
        components.append(newComp)
    }
    
    private func defaultValue(for type: CircuitComponent.ComponentType) -> Double {
        switch type {
        case .resistor: return 1000.0
        case .capacitor: return 1e-6
        case .inductor: return 1e-3
        case .voltageSource: return 5.0
        case .currentSource: return 0.01
        case .sw: return 1.0
        }
    }
    
    private func checkBridgeToLab() {
        let hasReactive = components.contains { [.capacitor, .inductor].contains($0.type) }
        if hasReactive && !showBridgePrompt {
            showBridgePrompt = true
        }
    }
}
