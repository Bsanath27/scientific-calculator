// ScientificCalculator/PhysicsEngine/USDZModelLibrary.swift
// 3D Model Registry: Bundled Assets and Physics Metadata

import Foundation
import RealityKit
import Combine

enum USDZModelLibrary: String, CaseIterable, Identifiable {
    case ironSphere = "iron_sphere"
    case woodenCube = "wooden_cube"
    case rubberBall = "rubber_ball"
    case carbonFiberPlane = "carbon_fiber_plane"
    case aluminumCan = "aluminum_can"
    case glassPrism = "glass_prism"
    case plasticGear = "plastic_gear"
    case ceramicTorus = "ceramic_torus"
    
    var id: String { rawValue }
    
    struct Metadata {
        let name: String
        let defaultMass: Double
        let defaultFriction: Double
        let defaultRestitution: Double
        let compatibleScenarios: [String]
    }
    
    var metadata: Metadata {
        switch self {
        case .ironSphere:
            return Metadata(name: "Iron Sphere", defaultMass: 7.8, defaultFriction: 0.3, defaultRestitution: 0.6, compatibleScenarios: ["collisions", "gravityField", "buoyancy"])
        case .woodenCube:
            return Metadata(name: "Wooden Cube", defaultMass: 0.7, defaultFriction: 0.5, defaultRestitution: 0.4, compatibleScenarios: ["collisions", "buoyancy"])
        case .rubberBall:
            return Metadata(name: "Rubber Ball", defaultMass: 0.1, defaultFriction: 0.8, defaultRestitution: 0.9, compatibleScenarios: ["projectile", "collisions"])
        case .carbonFiberPlane:
            return Metadata(name: "Carbon Fiber Plane", defaultMass: 0.05, defaultFriction: 0.1, defaultRestitution: 0.2, compatibleScenarios: ["terminalVelocity"])
        case .aluminumCan:
            return Metadata(name: "Aluminum Can", defaultMass: 0.2, defaultFriction: 0.4, defaultRestitution: 0.5, compatibleScenarios: ["collisions", "buoyancy"])
        case .glassPrism:
            return Metadata(name: "Glass Prism", defaultMass: 2.5, defaultFriction: 0.2, defaultRestitution: 0.3, compatibleScenarios: ["snellLaw", "lens"])
        case .plasticGear:
            return Metadata(name: "Plastic Gear", defaultMass: 0.3, defaultFriction: 0.3, defaultRestitution: 0.5, compatibleScenarios: ["collisions"])
        case .ceramicTorus:
            return Metadata(name: "Ceramic Torus", defaultMass: 1.5, defaultFriction: 0.4, defaultRestitution: 0.4, compatibleScenarios: ["gravityField"])
        }
    }
    
    /// Load model asynchronously from the app bundle
    @MainActor
    static func loadModel(named name: String) async throws -> Entity {
        // In actual implementation, this expects .usdz files in the bundle
        // RealityKit.Entity.loadAsync is the modern way
        return try await Entity.load(named: name)
    }
}
