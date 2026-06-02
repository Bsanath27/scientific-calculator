// ScientificCalculator/PhysicsEngine/PhysicsSimulator.swift
// Physics Simulation Engine: RK4, Analytical Solvers, and Event Detection

import Foundation
import Accelerate

struct SimulationFrame {
    let time: Double
    let state: [String: Any]
    let energy: EnergyState
    let annotations: [FrameAnnotation]
    let fbd: FBDState?
}

struct EnergyState {
    let kinetic: Double
    let potential: Double
    let total: Double
    
    static var zero: EnergyState { .init(kinetic: 0, potential: 0, total: 0) }
}

struct FrameAnnotation: Identifiable {
    let id = UUID()
    let position: WorldPoint
    let label: String
    let type: AnnotationType
    
    enum AnnotationType {
        case info
        case peak
        case event
    }
}

struct FBDState {
    let components: [ForceComponent]
    
    struct ForceComponent: Identifiable {
        let id = UUID()
        let type: ForceType
        let vector: WorldPoint // Direction and magnitude (N)
        let label: String
        
        enum ForceType {
            case gravity, normal, tension, friction, drag, spring, applied, net
        }
    }
    
    var netForce: WorldPoint {
        components.reduce(WorldPoint(0, 0)) { WorldPoint($0.x + $1.vector.x, $0.y + $1.vector.y) }
    }
}

struct PhysicsSimulator {
    static let maxFrames = 3600 // 60s at 60fps
    
    /// Entry point for running a simulation.
    func simulate(scenario: PhysicsScenario, parameters: [String: Double]) -> [SimulationFrame] {
        switch scenario.id {
        case "projectile":
            return simulateProjectile(parameters)
        case "pendulum":
            return simulatePendulum(parameters)
        case "springMass":
            return simulateSpringMass(parameters)
        case "standingWave":
            return simulateStandingWave(parameters)
        case "doppler":
            return simulateDoppler(parameters)
        case "idealGas":
            return simulateIdealGas(parameters)
        case "carnot":
            return simulateCarnot(parameters)
        case "electricField":
            return simulateElectricField(parameters)
        case "rcCircuit":
            return simulateRCCircuit(parameters)
        case "snellLaw":
            return simulateSnellLaw(parameters)
        case "lens":
            return simulateLens(parameters)
        case "radioactiveDecay":
            return simulateRadioactiveDecay(parameters)
        case "bohrModel":
            return simulateBohrModel(parameters)
        case "archimedes":
            return FluidSimulator.simulateArchimedes(p: parameters)
        case "terminalVelocity":
            return FluidSimulator.simulateTerminalVelocity(p: parameters)
        default:
            return []
        }
    }

    /// Real-time single step iteration
    func nextFrame(scenario: PhysicsScenario, parameters: [String: Double], previousFrame: SimulationFrame?, dt: Double) -> SimulationFrame {
        switch scenario.id {
        case "projectile":
            return stepProjectile(parameters, previous: previousFrame, dt: dt)
        case "pendulum":
            return stepPendulum(parameters, previous: previousFrame, dt: dt)
        case "springMass":
            return stepSpringMass(parameters, previous: previousFrame, dt: dt)
        case "standingWave":
            return stepStandingWave(parameters, previous: previousFrame, dt: dt)
        case "idealGas":
            return stepIdealGas(parameters, previous: previousFrame, dt: dt)
        case "bohrModel":
            return stepBohrModel(parameters, previous: previousFrame, dt: dt)
        case "archimedes":
            return stepArchimedes(parameters, previous: previousFrame, dt: dt)
        case "terminalVelocity":
            return stepTerminalVelocity(parameters, previous: previousFrame, dt: dt)
        default:
            let t = (previousFrame?.time ?? 0) + dt
            return .init(time: t, state: previousFrame?.state ?? [:], energy: previousFrame?.energy ?? .zero, annotations: [], fbd: nil)
        }
    }

    // MARK: - Real-time Steppers

    private func stepProjectile(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let v0 = p["v0"] ?? 20
        let theta = (p["theta"] ?? 45) * .pi / 180
        let g = p["g"] ?? 9.81
        let h0 = p["h0"] ?? 0
        let m = 1.0
        
        let t = (previous?.time ?? 0) + dt
        let vx = v0 * cos(theta)
        let vy0 = v0 * sin(theta)
        
        let x = vx * t
        let y = max(0, h0 + vy0 * t - 0.5 * g * t * t)
        let vy = vy0 - g * t
        
        let ke = 0.5 * m * (vx*vx + vy*vy)
        let pe = m * g * y
        
        return .init(time: t, state: ["x": x, "y": y, "vx": vx, "vy": vy], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: [], fbd: FBDState(components: [.init(type: .gravity, vector: WorldPoint(0, -m * g), label: "W")]))
    }

    private func stepPendulum(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let L = p["L"] ?? 1.0
        let g = p["g"] ?? 9.81
        let m = 1.0
        
        let prevState = [previous?.state["theta"] as? Double ?? (p["theta0"] ?? 15) * .pi / 180, previous?.state["omega"] as? Double ?? 0.0]
        let derivatives: ([Double]) -> [Double] = { s in [s[1], -(g / L) * sin(s[0])] }
        let nextState = rk4Step(state: prevState, dt: dt, derivatives: derivatives)
        
        let th = nextState[0]
        let om = nextState[1]
        let x = L * sin(th)
        let y = -L * cos(th)
        
        let ke = 0.5 * m * (L * om) * (L * om)
        let pe = m * g * (L * (1 - cos(th)))
        
        let alpha = -(g / L) * sin(th) // Angular acceleration
        let tensionMag = m * g * cos(th) + m * (L * om * om)
        
        let fbd = FBDState(components: [
            .init(type: .gravity, vector: WorldPoint(0, -m * g), label: "W"),
            .init(type: .tension, vector: WorldPoint(-tensionMag * sin(th), tensionMag * cos(th)), label: "T")
        ])
        
        return .init(time: (previous?.time ?? 0) + dt, state: ["theta": th, "x": x, "y": y, "omega": om, "alpha": alpha], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: [], fbd: fbd)
    }

    private func stepSpringMass(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let k = p["k"] ?? 50.0
        let m = p["m"] ?? 1.0
        let b = p["damping"] ?? 0.0
        
        let prevState = [previous?.state["x"] as? Double ?? (p["A"] ?? 0.5), previous?.state["v"] as? Double ?? 0.0]
        let derivatives: ([Double]) -> [Double] = { s in [s[1], (-k * s[0] - b * s[1]) / m] }
        let nextState = rk4Step(state: prevState, dt: dt, derivatives: derivatives)
        
        let x = nextState[0]
        let v = nextState[1]
        let ke = 0.5 * m * v * v
        let pe = 0.5 * k * x * x
        
        let fbd = FBDState(components: [
            .init(type: .spring, vector: WorldPoint(-k * x, 0), label: "Fs"),
            .init(type: .drag, vector: WorldPoint(-b * v, 0), label: "Fd")
        ])
        
        return .init(time: (previous?.time ?? 0) + dt, state: ["x": x, "v": v], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: [], fbd: fbd)
    }

    private func stepIdealGas(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let N = Int(p["N"] ?? 50)
        let temp = p["temp"] ?? 300.0
        let t = (previous?.time ?? 0) + dt
        
        var particles = previous?.state["particles"] as? [WorldPoint] ?? (0..<N).map { _ in WorldPoint(Double.random(in: -14...14), Double.random(in: -14...14)) }
        var velocities = previous?.state["velocities"] as? [WorldPoint] ?? (0..<N).map { _ in
            let speed = sqrt(temp) * 0.5
            let angle = Double.random(in: 0...(2 * .pi))
            return WorldPoint(speed * cos(angle), speed * sin(angle))
        }
        
        for i in 0..<particles.count {
            var newX = particles[i].x + velocities[i].x * dt
            var newY = particles[i].y + velocities[i].y * dt
            if abs(newX) > 15 { velocities[i] = WorldPoint(-velocities[i].x, velocities[i].y); newX = particles[i].x }
            if abs(newY) > 15 { velocities[i] = WorldPoint(velocities[i].x, -velocities[i].y); newY = particles[i].y }
            particles[i] = WorldPoint(newX, newY)
        }
        
        let totalKE = Double(N) * 1.5 * temp
        return .init(time: t, state: ["particles": particles, "velocities": velocities], energy: .init(kinetic: totalKE, potential: 0, total: totalKE), annotations: [], fbd: nil)
    }

    private func stepBohrModel(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let n = Int(p["n"] ?? 2)
        let r_scaled = Double(n * n) * 5.0
        let t = (previous?.time ?? 0) + dt
        let angle = t * 4.0 / Double(n)
        let pos = WorldPoint(r_scaled * cos(angle), r_scaled * sin(angle))
        let energy = -13.6 / Double(n * n)
        return .init(time: t, state: ["electron": pos, "r": r_scaled], energy: .init(kinetic: 0, potential: energy, total: energy), annotations: [], fbd: nil)
    }
    // MARK: - Simulation Implementation

    private func simulateProjectile(_ p: [String: Double]) -> [SimulationFrame] {
        let v0 = p["v0"] ?? 20
        let theta = (p["theta"] ?? 45) * .pi / 180
        let g = p["g"] ?? 9.81
        let h0 = p["h0"] ?? 0
        let m = 1.0 // Unit mass for energy/force calculation
        
        let vx = v0 * cos(theta)
        let vy0 = v0 * sin(theta)
        
        let flightTime = (vy0 + sqrt(vy0*vy0 + 2*g*h0)) / g
        let dt = flightTime / 120 // 120 frames
        
        var frames: [SimulationFrame] = []
        var t = 0.0
        var peakDetected = false
        
        while t <= flightTime + 0.001 {
            let x = vx * t
            let y = max(0, h0 + vy0 * t - 0.5 * g * t * t)
            let vy = vy0 - g * t
            
            let ke = 0.5 * m * (vx*vx + vy*vy)
            let pe = m * g * y
            
            var annotations: [FrameAnnotation] = []
            if !peakDetected && vy <= 0 {
                annotations.append(.init(position: WorldPoint(x, y), label: "Peak: \(String(format: "%.1f", y))m", type: .peak))
                peakDetected = true
            }
            
            if y <= 0 && t > 0 {
                annotations.append(.init(position: WorldPoint(x, 0), label: "Range: \(String(format: "%.1f", x))m", type: .event))
            }
            
            let fbd = FBDState(components: [
                .init(type: .gravity, vector: WorldPoint(0, -m * g), label: "W")
            ])
            
            frames.append(.init(time: t, state: ["x": x, "y": y, "vx": vx, "vy": vy], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: annotations, fbd: fbd))
            
            if y <= 0 && t > 0 { break }
            t += dt
        }
        
        return frames
    }

    private func simulatePendulum(_ p: [String: Double]) -> [SimulationFrame] {
        let L = p["L"] ?? 1.0
        let g = p["g"] ?? 9.81
        let theta0 = (p["theta0"] ?? 15) * .pi / 180
        let m = 1.0
        
        let dt = 1.0 / 60.0
        let duration = 10.0
        
        var state = [theta0, 0.0] // [theta, omega]
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        let derivatives: ([Double]) -> [Double] = { s in
            let th = s[0]
            let om = s[1]
            return [om, -(g / L) * sin(th)]
        }
        
        while t <= duration {
            let th = state[0]
            let om = state[1]
            let x = L * sin(th)
            let y = -L * cos(th)
            
            let ke = 0.5 * m * (L * om) * (L * om)
            let pe = m * g * (L * (1 - cos(th)))
            
            // FBD: Gravity and Tension
            let tensionMag = m * g * cos(th) + m * (L * om * om)
            let fbd = FBDState(components: [
                .init(type: .gravity, vector: WorldPoint(0, -m * g), label: "W"),
                .init(type: .tension, vector: WorldPoint(-tensionMag * sin(th), tensionMag * cos(th)), label: "T")
            ])
            
            frames.append(.init(time: t, state: ["theta": th, "x": x, "y": y, "omega": om], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: [], fbd: fbd))
            
            state = rk4Step(state: state, dt: dt, derivatives: derivatives)
            t += dt
        }
        
        return frames
    }

    private func simulateSpringMass(_ p: [String: Double]) -> [SimulationFrame] {
        let k = p["k"] ?? 50.0
        let m = p["m"] ?? 1.0
        let A = p["A"] ?? 0.5
        let b = p["damping"] ?? 0.0
        
        let omega0 = sqrt(k / m)
        let gamma = b / (2 * m)
        let omega = sqrt(max(0, omega0 * omega0 - gamma * gamma))
        
        let duration = 10.0
        let dt = 1.0 / 60.0
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        while t <= duration {
            let x = A * exp(-gamma * t) * cos(omega * t)
            let v = -A * exp(-gamma * t) * (gamma * cos(omega * t) + omega * sin(omega * t))
            
            let ke = 0.5 * m * v * v
            let pe = 0.5 * k * x * x
            
            let springForce = -k * x
            let dampingForce = -b * v
            
            let fbd = FBDState(components: [
                .init(type: .spring, vector: WorldPoint(springForce, 0), label: "Fs"),
                .init(type: .drag, vector: WorldPoint(dampingForce, 0), label: "Fd")
            ])
            
            frames.append(.init(time: t, state: ["x": x, "v": v], energy: .init(kinetic: ke, potential: pe, total: ke + pe), annotations: [], fbd: fbd))
            t += dt
        }
        
        return frames
    }

    private func stepStandingWave(_ p: [String: Double], previous: SimulationFrame?, dt: Double) -> SimulationFrame {
        let L = p["L"] ?? 1.0
        let T = p["T"] ?? 100.0
        let n = Int(p["n"] ?? 1)
        let mu = 0.01
        let v = sqrt(T / mu)
        let f = Double(n) * v / (2 * L)
        let t = (previous?.time ?? 0) + dt
        
        var points: [WorldPoint] = []
        for i in 0...50 {
            let x = Double(i) * L / 50.0
            let y = 0.2 * sin(Double(n) * .pi * x / L) * cos(2 * .pi * f * t)
            points.append(WorldPoint(x, y))
        }
        return .init(time: t, state: ["points": points] as [String: Any], energy: .zero, annotations: [], fbd: nil)
    }

    // MARK: - Wave Scenarios
    
    private func simulateStandingWave(_ p: [String: Double]) -> [SimulationFrame] {
        let L = p["L"] ?? 1.0
        let T = p["T"] ?? 100.0
        let n = Int(p["n"] ?? 1)
        let mu = 0.01 // Linear density kg/m
        
        let velocity = sqrt(T / mu)
        let frequency = Double(n) * velocity / (2 * L)
        let period = 1.0 / frequency
        
        let dt = 1.0 / 60.0
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        let duration = period * 2
        while t <= duration {
            var points: [WorldPoint] = []
            let resolution = 50
            for i in 0...resolution {
                let x = Double(i) * L / Double(resolution)
                let y = 0.2 * sin(Double(n) * .pi * x / L) * cos(2 * .pi * frequency * t)
                points.append(WorldPoint(x, y))
            }
            frames.append(.init(time: t, state: ["points": points], energy: .zero, annotations: [], fbd: nil))
            t += dt
        }
        return frames
    }
    
    private func simulateDoppler(_ p: [String: Double]) -> [SimulationFrame] {
        let v_s = p["v_s"] ?? 50.0
        let f = p["f"] ?? 440.0
        let v_sound = 340.0
        
        let dt = 1.0 / 60.0
        let duration = 3.0
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        while t <= duration {
            let x = v_s * t
            var waveRadii: [CGFloat] = []
            for i in 0...Int(t * 10) {
                let t_emit = Double(i) * 0.1
                let r = v_sound * (t - t_emit)
                if r > 0 { waveRadii.append(CGFloat(r)) }
            }
            frames.append(.init(time: t, state: ["x": x, "waves": waveRadii], energy: .zero, annotations: [], fbd: nil))
            t += dt
        }
        return frames
    }
    
    // MARK: - Thermodynamics
    
    private func simulateCarnot(_ p: [String: Double]) -> [SimulationFrame] {
        let T_h = p["T_h"] ?? 600.0
        let T_c = p["T_c"] ?? 300.0
        
        var frames: [SimulationFrame] = []
        var history: [WorldPoint] = []
        for i in 0...100 {
            let t = Double(i) / 100.0
            var pVal = 0.0
            var vVal = 0.0
            
            if t < 0.25 {
                vVal = 10 + t * 40; pVal = T_h / vVal
            } else if t < 0.5 {
                vVal = 20 + (t-0.25) * 40; pVal = T_h * pow(20/vVal, 1.4) / 20
            } else if t < 0.75 {
                vVal = 40 - (t-0.5) * 40; pVal = T_c / vVal
            } else {
                vVal = 20 - (t-0.75) * 40; pVal = T_c * pow(20/vVal, 1.4) / 20
            }
            
            history.append(WorldPoint(vVal/2, pVal/2))
            frames.append(.init(time: t, state: ["v": vVal/2, "p": pVal/2, "history": history], energy: .zero, annotations: [], fbd: nil))
        }
        return frames
    }

    private func simulateIdealGas(_ p: [String: Double]) -> [SimulationFrame] {
        let N = Int(p["N"] ?? 50)
        let temp = p["temp"] ?? 300.0
        let k_b = 1.38e-23 // Boltzmann constant
        
        let dt = 1.0 / 60.0
        let duration = 2.0 
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        var particles = (0..<N).map { _ in WorldPoint(Double.random(in: -14...14), Double.random(in: -14...14)) }
        var velocities = (0..<N).map { _ in 
            let speed = sqrt(temp) * 0.5
            let angle = Double.random(in: 0...(2 * .pi))
            return WorldPoint(speed * cos(angle), speed * sin(angle))
        }
        
        while t <= duration {
            for i in 0..<N {
                var newX = particles[i].x + velocities[i].x * dt
                var newY = particles[i].y + velocities[i].y * dt
                
                if abs(newX) > 15 { velocities[i] = WorldPoint(-velocities[i].x, velocities[i].y); newX = particles[i].x }
                if abs(newY) > 15 { velocities[i] = WorldPoint(velocities[i].x, -velocities[i].y); newY = particles[i].y }
                
                particles[i] = WorldPoint(newX, newY)
            }
            
            let totalKE = Double(N) * 1.5 * temp
            
            frames.append(.init(time: t, state: ["particles": particles, "velocities": velocities], energy: .init(kinetic: totalKE, potential: 0, total: totalKE), annotations: [], fbd: nil))
            t += dt
        }
        return frames
    }
    
    private func simulateElectricField(_ p: [String: Double]) -> [SimulationFrame] {
        let q1 = p["q1"] ?? 5.0
        let q2 = p["q2"] ?? -5.0
        let k = 8.99e9 // Coulomb's constant
        
        let charges = [
            (pos: WorldPoint(-10, 0), q: q1),
            (pos: WorldPoint(10, 0), q: q2)
        ]
        
        var fieldLines: [[WorldPoint]] = []
        
        // Trace lines from positive charge
        for charge in charges where charge.q > 0 {
            for angle in stride(from: 0.0, to: 2 * .pi, by: .pi / 8) {
                var line: [WorldPoint] = []
                var current = WorldPoint(charge.pos.x + 0.5 * cos(angle), charge.pos.y + 0.5 * sin(angle))
                
                for _ in 0...100 {
                    line.append(current)
                    
                    // Net E-field at current point
                    var ex = 0.0
                    var ey = 0.0
                    for c in charges {
                        let dx = current.x - c.pos.x
                        let dy = current.y - c.pos.y
                        let r2 = max(0.1, dx*dx + dy*dy)
                        let r = sqrt(r2)
                        let e_mag = k * abs(c.q) / r2
                        let sign = c.q > 0 ? 1.0 : -1.0
                        ex += sign * e_mag * (dx / r)
                        ey += sign * e_mag * (dy / r)
                    }
                    
                    let total_mag = sqrt(ex*ex + ey*ey)
                    let step = 0.5
                    current = WorldPoint(current.x + (ex / total_mag) * step, current.y + (ey / total_mag) * step)
                    
                    // Convergence check
                    if charges.contains(where: { sqrt(pow(current.x - $0.pos.x, 2) + pow(current.y - $0.pos.y, 2)) < 1.0 && $0.q < 0 }) {
                        break
                    }
                    if abs(current.x) > 40 || abs(current.y) > 40 { break }
                }
                fieldLines.append(line)
            }
        }
        
        let state: [String: Any] = ["fieldLines": fieldLines, "charges": charges.map { ["pos": $0.pos, "q": $0.q] }]
        return [.init(time: 0, state: state, energy: .zero, annotations: [], fbd: nil)]
    }
    
    private func simulateRCCircuit(_ p: [String: Double]) -> [SimulationFrame] {
        let R = p["R"] ?? 1000.0
        let C_val = (p["C"] ?? 100.0) * 1e-6
        let V0 = 10.0
        let tau = R * C_val
        
        let dt = tau / 40 // 40 steps per time constant
        let duration = 5 * tau
        var frames: [SimulationFrame] = []
        var t = 0.0
        var history: [WorldPoint] = []
        
        while t <= duration {
            let vc = V0 * (1 - exp(-t / tau))
            let vr = V0 * exp(-t / tau)
            let i = vr / R
            
            history.append(WorldPoint(t, vc))
            
            // Energy in capacitor: 1/2 CV^2
            let energy = 0.5 * C_val * vc * vc
            
            var annotations: [FrameAnnotation] = []
            if abs(t - tau) < dt/2 {
                annotations.append(.init(position: WorldPoint(t, vc), label: "τ (63.2%)", type: .event))
            }
            
            frames.append(.init(time: t, state: ["v_c": vc, "v_r": vr, "i": i, "history": history], energy: .init(kinetic: energy, potential: 0, total: energy), annotations: annotations, fbd: nil))
            t += dt
        }
        return frames
    }
    
    // MARK: - Optics
    
    private func simulateSnellLaw(_ p: [String: Double]) -> [SimulationFrame] {
        let n1 = p["n1"] ?? 1.0
        let n2 = p["n2"] ?? 1.5
        let theta1 = 30.0 * .pi / 180
        
        let sinTheta2 = n1 * sin(theta1) / n2
        if sinTheta2 > 1.0 {
            // Total Internal Reflection
            let incident = [WorldPoint(-20 * sin(theta1), -20 * cos(theta1)), WorldPoint(0, 0)]
            let reflected = [WorldPoint(0, 0), WorldPoint(20 * sin(theta1), -20 * cos(theta1))]
            return [.init(time: 0, state: ["incident": incident, "reflected": reflected, "tir": true], energy: .zero, annotations: [.init(position: WorldPoint(0, 0), label: "TIR", type: .event)], fbd: nil)]
        }
        
        let theta2 = asin(sinTheta2)
        let incident = [WorldPoint(-20 * sin(theta1), -20 * cos(theta1)), WorldPoint(0, 0)]
        let refracted = [WorldPoint(0, 0), WorldPoint(20 * sin(theta2), 20 * cos(theta2))]
        
        return [.init(time: 0, state: ["incident": incident, "refracted": refracted, "tir": false], energy: .zero, annotations: [], fbd: nil)]
    }
    
    private func simulateLens(_ p: [String: Double]) -> [SimulationFrame] {
        let f = p["f"] ?? 10.0
        let d_o = p["d_o"] ?? 15.0
        let h_o = 5.0
        
        // Lens equation: 1/f = 1/do + 1/di
        let d_i = 1.0 / (1.0/f - 1.0/d_o)
        let m = -d_i / d_o
        let h_i = h_o * m
        
        var rays: [[WorldPoint]] = []
        // Ray 1: Parallel then through focus
        rays.append([WorldPoint(-d_o, h_o), WorldPoint(0, h_o), WorldPoint(abs(d_i) > 40 ? 40 * sign(d_i) : d_i, h_i)])
        // Ray 2: Through center
        rays.append([WorldPoint(-d_o, h_o), WorldPoint(0, 0), WorldPoint(abs(d_i) > 40 ? 40 * sign(d_i) : d_i, h_i)])
        
        let state: [String: Any] = ["rays": rays, "d_i": d_i, "h_i": h_i, "real": d_i > 0]
        return [.init(time: 0, state: state, energy: .zero, annotations: [], fbd: nil)]
    }
    
    // MARK: - Modern
    
    private func simulateRadioactiveDecay(_ p: [String: Double]) -> [SimulationFrame] {
        let t_half = p["t_half"] ?? 5.0
        let N0 = Int(p["N0"] ?? 500)
        let lambda = log(2) / t_half
        
        let dt = 0.5
        let duration = 4.0 * t_half
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        var nuclei = (0..<N0).map { _ in WorldPoint(Double.random(in: -15...15), Double.random(in: -15...15)) }
        var activeIndices = Set(0..<N0)
        
        while t <= duration {
            let p_decay = 1.0 - exp(-lambda * dt)
            let currentActive = activeIndices
            for idx in currentActive {
                if Double.random(in: 0...1) < p_decay {
                    activeIndices.remove(idx)
                }
            }
            
            let activePoints = activeIndices.map { nuclei[$0] }
            let decayedPoints = (0..<N0).filter { !activeIndices.contains($0) }.map { nuclei[$0] }
            
            frames.append(.init(time: t, state: ["active": activePoints, "decayed": decayedPoints], energy: .zero, annotations: [], fbd: nil))
            t += dt
        }
        return frames
    }
    
    private func simulateBohrModel(_ p: [String: Double]) -> [SimulationFrame] {
        let n = Int(p["n"] ?? 2)
        let r0 = 0.529e-10 // Bohr radius in m
        let r_scaled = Double(n * n) * 5.0 // Scaled for view
        
        let dt = 1.0 / 60.0
        let duration = 2.0
        var frames: [SimulationFrame] = []
        var t = 0.0
        
        while t <= duration {
            let angle = t * 4.0 / Double(n) // Heuristic velocity
            let pos = WorldPoint(r_scaled * cos(angle), r_scaled * sin(angle))
            
            // Energy: -13.6 eV / n^2
            let energy = -13.6 / Double(n * n)
            
            frames.append(.init(time: t, state: ["electron": pos, "r": r_scaled], energy: .init(kinetic: 0, potential: energy, total: energy), annotations: [], fbd: nil))
            t += dt
        }
        return frames
    }
    
    private func sign(_ x: Double) -> Double {
        return x >= 0 ? 1.0 : -1.0
    }
    
    
    // MARK: - Specialized Simulators

    struct FluidSimulator {
        static func simulateArchimedes(p: [String: Double]) -> [SimulationFrame] {
            let rho_f = p["rho_f"] ?? 1000.0
            let r = p["radius"] ?? 0.05
            let m = p["mass"] ?? 1.0
            let mu = p["viscosity"] ?? 0.001
            
            var frames: [SimulationFrame] = []
            var y = 20.0
            var v = 0.0
            let dt = 0.016
            
            for i in 0..<300 {
                let res = FluidDynamicsEngine.stepFluidMotion(y: y, v: v, m: m, r: r, rho_f: rho_f, mu: mu, dt: dt)
                y = res.0; v = res.1
                frames.append(.init(time: Double(i)*dt, state: ["y": y, "v": v], energy: .init(kinetic: 0.5*m*v*v, potential: m*9.81*y, total: 0), annotations: [], fbd: res.2))
            }
            return frames
        }
        
        static func simulateTerminalVelocity(p: [String: Double]) -> [SimulationFrame] {
            let rho_f = p["rho_f"] ?? 1.225 // Air
            let r = p["radius"] ?? 0.1
            let m = p["mass"] ?? 0.5
            let mu = p["viscosity"] ?? 1.8e-5
            
            var frames: [SimulationFrame] = []
            var y = 100.0
            var v = 0.0
            let dt = 0.1
            
            for i in 0..<200 {
                let res = FluidDynamicsEngine.stepFluidMotion(y: y, v: v, m: m, r: r, rho_f: rho_f, mu: mu, dt: dt)
                y = res.0; v = res.1
                frames.append(.init(time: Double(i)*dt, state: ["y": y, "v": v], energy: .init(kinetic: 0.5*m*v*v, potential: m*9.81*y, total: 0), annotations: [], fbd: res.2))
            }
            return frames
        }
    }
    
    struct GravityFieldSampler {
        static func sample(masses: [(pos: WorldPoint, m: Double)], at point: WorldPoint) -> WorldPoint {
            let G = 6.674e-11
            var totalField = WorldPoint(0, 0)
            
            for body in masses {
                let dx = body.pos.x - point.x
                let dy = body.pos.y - point.y
                let r2 = max(1.0, dx*dx + dy*dy)
                let r = sqrt(r2)
                let g_mag = G * body.m / r2
                
                totalField = WorldPoint(totalField.x + g_mag * dx/r, totalField.y + g_mag * dy/r)
            }
            return totalField
        }
    }
    
    // MARK: - RK4 Integrator
    
    private func rk4Step(state: [Double], dt: Double, derivatives: ([Double]) -> [Double]) -> [Double] {
        let k1 = derivatives(state)
        let k2 = derivatives(zip(state, k1).map { $0 + 0.5 * dt * $1 })
        let k3 = derivatives(zip(state, k2).map { $0 + 0.5 * dt * $1 })
        let k4 = derivatives(zip(state, k3).map { $0 + dt * $1 })
        
        return zip(state, zip(zip(k1, k2), zip(k3, k4))).map { s, ks in
            let ((a, b), (c, d)) = ks
            return s + (dt / 6.0) * (a + 2*b + 2*c + d)
        }
    }
}
