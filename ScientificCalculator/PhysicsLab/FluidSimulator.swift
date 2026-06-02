// ScientificCalculator/PhysicsEngine/FluidSimulator.swift
// Fluid Simulation Extensions: Buoyancy, Drag, and Terminal Velocity

import Foundation

extension PhysicsSimulator {
    
    /// Archimedes' Principle Scenario: Submerged body with buoyancy and drag
    func stepArchimedes(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let rho_f = p["rho_f"] ?? 1000.0 // Water density
        let r = p["radius"] ?? 0.05
        let m = p["mass"] ?? 1.0
        let mu = p["viscosity"] ?? 0.001 // Water viscosity
        let g = 9.81
        
        let y = previous?.state["y"] as? Double ?? 20.0
        let v = previous?.state["v"] as? Double ?? 0.0
        
        let res = FluidDynamicsEngine.stepFluidMotion(y: y, v: v, m: m, r: r, rho_f: rho_f, mu: mu, dt: dt)
        
        return .init(
            time: (previous?.time ?? 0) + dt,
            state: ["y": res.0, "v": res.1],
            energy: .init(kinetic: 0.5 * m * res.1 * res.1, potential: m * g * res.0, total: 0.5 * m * res.1 * res.1 + m * g * res.0),
            annotations: [],
            fbd: res.2
        )
    }
    
    /// Terminal Velocity Scenario: Falling body in air/fluid
    func stepTerminalVelocity(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let rho_f = p["rho_f"] ?? 1.225 // Air density
        let r = p["radius"] ?? 0.1
        let m = p["mass"] ?? 0.5
        let mu = p["viscosity"] ?? 1.8e-5 // Air viscosity
        let g = 9.81
        
        let y = previous?.state["y"] as? Double ?? 100.0
        let v = previous?.state["v"] as? Double ?? 0.0
        
        let res = FluidDynamicsEngine.stepFluidMotion(y: y, v: v, m: m, r: r, rho_f: rho_f, mu: mu, dt: dt)
        
        return .init(
            time: (previous?.time ?? 0) + dt,
            state: ["y": res.0, "v": res.1],
            energy: .init(kinetic: 0.5 * m * res.1 * res.1, potential: m * g * res.0, total: 0.5 * m * res.1 * res.1 + m * g * res.0),
            annotations: [],
            fbd: res.2
        )
    }

    // Static versions for batch simulation if needed
    static func simulateArchimedes(p: [String: Double]) -> [SimulationFrame] {
        let simulator = PhysicsSimulator()
        var frames: [SimulationFrame] = []
        var current: SimulationFrame? = nil
        let dt = 0.016
        for _ in 0..<300 {
            let next = simulator.stepArchimedes(p, previous: current, dt: dt)
            frames.append(next)
            current = next
        }
        return frames
    }
    
    static func simulateTerminalVelocity(p: [String: Double]) -> [SimulationFrame] {
        let simulator = PhysicsSimulator()
        var frames: [SimulationFrame] = []
        var current: SimulationFrame? = nil
        let dt = 0.1
        for _ in 0..<200 {
            let next = simulator.stepTerminalVelocity(p, previous: current, dt: dt)
            frames.append(next)
            current = next
        }
        return frames
    }
}
