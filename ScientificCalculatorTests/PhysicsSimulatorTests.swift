// ScientificCalculatorTests/PhysicsSimulatorTests.swift
// Physics Lab Unit Tests: Analytical & Coordinate Verifications

import XCTest
@testable import ScientificCalculator

final class PhysicsSimulatorTests: XCTestCase {
    
    let simulator = PhysicsSimulator()
    
    // MARK: - Analytical Tests
    
    func testProjectileAnalytical() {
        let params: [String: Double] = ["v0": 20, "theta": 45, "g": 9.81, "h0": 0]
        let scenario = PhysicsScenario.projectile
        let frames = simulator.simulate(scenario: scenario, parameters: params)
        
        guard let last = frames.last else { XCTFail("No frames generated"); return }
        
        // v0=20, theta=45, g=9.81 -> Range approx 40.77m
        let x = last.state["x"] ?? 0
        XCTAssertEqual(x, 40.77, accuracy: 0.1)
    }
    
    func testPendulumEnergyConservation() {
        let params: [String: Double] = ["L": 2.0, "g": 9.81, "theta0": 30]
        let scenario = PhysicsScenario.pendulum
        let frames = simulator.simulate(scenario: scenario, parameters: params)
        
        XCTAssertGreaterThan(frames.count, 0)
        let initialEnergy = frames[0].energy.total
        
        for frame in frames {
            // Check conservation within 1% (numerical integration error)
            XCTAssertEqual(frame.energy.total, initialEnergy, accuracy: initialEnergy * 0.01, "Energy not conserved at t=\(frame.time)")
        }
    }
    
    func testSpringMassAnalytical() {
        let params: [String: Double] = ["k": 100, "m": 1.0, "A": 1.0, "damping": 0]
        let frames = simulator.simulate(scenario: .springMass, parameters: params)
        
        // At t = 0, x = A
        XCTAssertEqual(frames[0].state["x"] as? Double ?? 0, 1.0, accuracy: 0.001)
        
        // Period T = 2pi * sqrt(m/k) = 2pi * 0.1 ~ 0.628s
        // At t = T/2 ~ 0.314s, x = -A
        let midFrame = frames.first { $0.time >= 0.314 }
        XCTAssertEqual(midFrame?.state["x"] as? Double ?? 0, -1.0, accuracy: 0.05)
    }
    
    func testIdealGasEnergy() {
        let params: [String: Double] = ["N": 50, "temp": 300]
        let frames = simulator.simulate(scenario: .idealGas, parameters: params)
        
        let initialEnergy = frames[0].energy.total
        XCTAssertEqual(initialEnergy, 50 * 1.5 * 300, accuracy: 0.001)
    }

    // MARK: - Coordinate System Tests
    
    func testCoordinateSystemRoundTrip() {
        let size = CGSize(width: 800, height: 600)
        let cs = PhysicsCoordinateSystem.make(for: "projectile", canvasSize: size)
        
        let original = WorldPoint(100, 50)
        let screen = cs.toScreen(original)
        let back = cs.toWorld(screen)
        
        XCTAssertEqual(original.x, back.x, accuracy: 0.1)
        XCTAssertEqual(original.y, back.y, accuracy: 0.1)
    }
    
    func testAntiGravityInversion() {
        let size = CGSize(width: 1000, height: 1000)
        let cs = CoordinateSystem.make(for: "projectile", canvasSize: size)
        
        let worldGround = WorldPoint(0, 0)
        let worldAir = WorldPoint(0, 10)
        
        let screenGround = cs.toScreen(worldGround)
        let screenAir = cs.toScreen(worldAir)
        
        // In screen coords, higher world Y MUST be a smaller screen Y value
        XCTAssertTrue(screenAir.y < screenGround.y, "Anti-Gravity Fix Failed: Y-up in world must be Y-down on screen")
    }
}
