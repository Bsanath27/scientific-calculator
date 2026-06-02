// ScientificCalculator/PhysicsEngine/PhysicsModule.swift
// Physics Lab Module System: Mechanics, Waves, Thermo, EM, Optics, Modern

import SwiftUI

struct PhysicsModule: Identifiable {
    let id: String
    let name: String
    let icon: String          // SF Symbol
    let color: Color          // Accent color
    let description: String
    let scenarios: [PhysicsScenario]
    let difficulty: Difficulty

    enum Difficulty: String { 
        case introductory = "Intro"
        case intermediate = "Inter"
        case advanced     = "Adv"
    }
}

extension PhysicsModule {
    static let mechanics = PhysicsModule(
        id: "mechanics",
        name: "Classical Mechanics",
        icon: "arrow.up.right.circle",
        color: .blue,
        description: "Motion, forces, energy, and momentum in macroscopic systems.",
        scenarios: [.projectile, .pendulum, .springMass, .doublePendulum, .planetaryOrbit, .collisions],
        difficulty: .introductory
    )
    
    static let waves = PhysicsModule(
        id: "waves",
        name: "Waves & Oscillations",
        icon: "waveform",
        color: .purple,
        description: "Periodic motion, sound, and wave behavior.",
        scenarios: [.standingWave, .doppler, .interference, .soundBeats, .shockWave, .huygensPrinciple],
        difficulty: .intermediate
    )
    
    static let thermodynamics = PhysicsModule(
        id: "thermodynamics",
        name: "Thermodynamics",
        icon: "flame",
        color: .orange,
        description: "Heat, temperature, and statistical mechanics.",
        scenarios: [.idealGas, .carnot, .entropyIncrease, .blackbodyRadiation, .stirlingEngine, .refrigerator],
        difficulty: .intermediate
    )
    
    static let electromagnetism = PhysicsModule(
        id: "electromagnetism",
        name: "Electromagnetism",
        icon: "bolt.circle",
        color: .yellow,
        description: "Electric fields, circuits, and magnetic phenomena.",
        scenarios: [.electricField, .rcCircuit, .lcrCircuit, .cyclotron, .magneticTorque, .faradayLaw],
        difficulty: .advanced
    )
    
    static let optics = PhysicsModule(
        id: "optics",
        name: "Optics",
        icon: "rays",
        color: .green,
        description: "Light behavior, lenses, mirrors, and diffraction.",
        scenarios: [.snellLaw, .lens, .rainbowRefraction, .diffractionGrating, .polarization, .telescope],
        difficulty: .intermediate
    )
    
    static let modern = PhysicsModule(
        id: "modern",
        name: "Modern Physics",
        icon: "atom",
        color: .pink,
        description: "Quantum mechanics, relativity, and atomic/nuclear phenomena.",
        scenarios: [.radioactiveDecay, .bohrModel, .photoelectricEffect, .comptonScattering, .specialRelativityTime, .schrodingerCat],
        difficulty: .advanced
    )

    static let fluids = PhysicsModule(
        id: "fluids",
        name: "Fluid Dynamics",
        icon: "drop.fill",
        color: .cyan,
        description: "Buoyancy, pressure, and flow in liquids and gases.",
        scenarios: [.archimedes, .terminalVelocity],
        difficulty: .intermediate
    )
    
    static let allModules: [PhysicsModule] = [
        .mechanics, .waves, .thermodynamics, .electromagnetism, .optics, .modern, .fluids
    ]
}
