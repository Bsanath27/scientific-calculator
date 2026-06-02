// ScientificCalculator/PhysicsEngine/FluidDynamicsEngine.swift
// Fluid Dynamics: Buoyancy, Stokes' Law, and Terminal Velocity Solvers

import Foundation

struct FluidDynamicsEngine {
    
    /// Archimedes' Principle: F_b = rho * V * g
    static func buoyancyForce(displacedVolume: Double, fluidDensity: Double, g: Double = 9.81) -> Double {
        return fluidDensity * displacedVolume * g
    }
    
    /// Stokes' Law: F_d = 6 * pi * mu * r * v (for low Reynolds numbers)
    static func stokesDragForce(velocity: Double, radius: Double, viscosity: Double) -> Double {
        return 6 * .pi * viscosity * radius * velocity
    }
    
    /// Quadratic Drag: F_d = 0.5 * rho * v^2 * C_d * A (for high Reynolds numbers)
    static func quadraticDragForce(velocity: Double, area: Double, dragCoefficient: Double, fluidDensity: Double) -> Double {
        return 0.5 * fluidDensity * velocity * velocity * dragCoefficient * area
    }
    
    /// Calculate Terminal Velocity where Drag = Net Gravitational Force (Weight - Buoyancy)
    static func computeTerminalVelocity(mass: Double, radius: Double, fluidDensity: Double, bodyDensity: Double, viscosity: Double) -> Double {
        let g = 9.81
        let volume = (4.0/3.0) * .pi * pow(radius, 3)
        let weight = mass * g
        let buoyancy = buoyancyForce(displacedVolume: volume, fluidDensity: fluidDensity, g: g)
        let netWeight = weight - buoyancy
        
        // Using Stokes' Law for small spheres in viscous fluid
        return netWeight / (6 * .pi * viscosity * radius)
    }
    
    /// Full RK4 Step for a falling body with buoyancy and drag
    static func stepFluidMotion(y: Double, v: Double, m: Double, r: Double, rho_f: Double, mu: Double, dt: Double) -> (Double, Double, FBDState) {
        let g = 9.81
        let vol = (4.0/3.0) * .pi * pow(r, 3)
        let weight = m * g
        let buoyancy = buoyancyForce(displacedVolume: vol, fluidDensity: rho_f, g: g)
        
        let derivatives: (Double, Double) -> (Double, Double) = { _, v_curr in
            let drag = stokesDragForce(velocity: v_curr, radius: r, viscosity: mu)
            let accel = (weight - buoyancy - drag) / m
            return (v_curr, -accel) // y is down positive or up positive? Assuming down is positive for ease.
        }
        
        // Simple RK2/Euler or call standard RK4. Let's do a quick RK4 here for precision.
        let k1v = (weight - buoyancy - stokesDragForce(velocity: v, radius: r, viscosity: mu)) / m
        let k1y = v
        
        let k2v = (weight - buoyancy - stokesDragForce(velocity: v + k1v * dt/2, radius: r, viscosity: mu)) / m
        let k2y = v + k1v * dt/2
        
        let k3v = (weight - buoyancy - stokesDragForce(velocity: v + k2v * dt/2, radius: r, viscosity: mu)) / m
        let k3y = v + k2v * dt/2
        
        let k4v = (weight - buoyancy - stokesDragForce(velocity: v + k3v * dt, radius: r, viscosity: mu)) / m
        let k4y = v + k3v * dt
        
        let nextV = v + (dt/6.0) * (k1v + 2*k2v + 2*k3v + k4v)
        let nextY = y + (dt/6.0) * (k1y + 2*k2y + 2*k3y + k4y)
        
        let fbd = FBDState(components: [
            .init(type: .gravity, vector: WorldPoint(0, -weight), label: "W"),
            .init(type: .drag, vector: WorldPoint(0, stokesDragForce(velocity: v, radius: r, viscosity: mu)), label: "F_d"),
            .init(type: .normal, vector: WorldPoint(0, buoyancy), label: "B") // Buoyancy acts up
        ])
        
        return (nextY, nextV, fbd)
    }
}
