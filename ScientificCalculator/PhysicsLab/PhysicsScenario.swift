// ScientificCalculator/PhysicsEngine/PhysicsScenario.swift
// Physics Simulation Metadata & Definitions - 36 Comprehensive Scenarios

import Foundation

struct PhysicsScenario: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let moduleId: String
    let rendererType: RendererType
    let defaultParameters: [PhysicsParameter]
    let curriculumTags: [String]

    enum RendererType: String { 
        case canvas2D
        case realityKit3D
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhysicsScenario, rhs: PhysicsScenario) -> Bool {
        lhs.id == rhs.id
    }
    
    static let allCases: [PhysicsScenario] = [
        // Mechanics
        .projectile, .pendulum, .springMass, .doublePendulum, .planetaryOrbit, .collisions,
        // Waves
        .standingWave, .doppler, .interference, .soundBeats, .shockWave, .huygensPrinciple,
        // Thermo
        .idealGas, .carnot, .entropyIncrease, .blackbodyRadiation, .stirlingEngine, .refrigerator,
        // EM
        .electricField, .rcCircuit, .lcrCircuit, .cyclotron, .magneticTorque, .faradayLaw,
        // Optics
        .snellLaw, .lens, .rainbowRefraction, .diffractionGrating, .polarization, .telescope,
        // Modern
        .radioactiveDecay, .bohrModel, .photoelectricEffect, .comptonScattering, .specialRelativityTime, .schrodingerCat,
        // Fluids (New)
        .archimedes, .terminalVelocity
    ]
}

extension PhysicsScenario {
    // MARK: - Mechanics
    static let projectile = PhysicsScenario(
        id: "projectile", title: "Projectile Motion", subtitle: "Analyze trajectory.",
        description: "Simulates a mass launched under uniform gravity.", icon: "arrow.up.right.circle",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "v0", symbol: "v₀", label: "Velocity", unit: "m/s", value: 20, range: 0...100, stepSize: 1, physicalMeaning: "Velocity at launch."),
            .init(id: "theta", symbol: "θ", label: "Angle", unit: "°", value: 45, range: 0...90, stepSize: 1, physicalMeaning: "Angle relative to horizontal."),
            .init(id: "g", symbol: "g", label: "Gravity", unit: "m/s²", value: 9.81, range: 0.1...25, stepSize: 0.1, physicalMeaning: "Local gravity."),
            .init(id: "h0", symbol: "h₀", label: "Height", unit: "m", value: 0, range: 0...50, stepSize: 1, physicalMeaning: "Initial vertical position.")
        ], curriculumTags: ["Kinematics"]
    )
    
    static let pendulum = PhysicsScenario(
        id: "pendulum", title: "Simple Pendulum", subtitle: "Large angle oscillation.",
        description: "Models a mass suspended from a pivot point.", icon: "timer",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "L", symbol: "L", label: "Length", unit: "m", value: 1.0, range: 0.1...5, stepSize: 0.1, physicalMeaning: "Distance from pivot."),
            .init(id: "theta0", symbol: "θ₀", label: "Init Angle", unit: "°", value: 15, range: 1...170, stepSize: 1, physicalMeaning: "Starting displacement.")
        ], curriculumTags: ["Oscillations"]
    )
    
    static let springMass = PhysicsScenario(
        id: "springMass", title: "Spring-Mass SHM", subtitle: "Hooke's Law.",
        description: "Simulates SHM for a mass attached to a spring.", icon: "cable.connector",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "k", symbol: "k", label: "Spring k", unit: "N/m", value: 50, range: 1...500, stepSize: 1, physicalMeaning: "Stiffness."),
            .init(id: "m", symbol: "m", label: "Mass", unit: "kg", value: 1.0, range: 0.1...10, stepSize: 0.1, physicalMeaning: "Mass of the block."),
            .init(id: "A", symbol: "A", label: "Amplitude", unit: "m", value: 0.5, range: 0.01...2, stepSize: 0.05, physicalMeaning: "Max displacement.")
        ], curriculumTags: ["SHM"]
    )

    static let doublePendulum = PhysicsScenario(
        id: "doublePendulum", title: "Double Pendulum", subtitle: "Chaotic motion.", 
        description: "A sensitive system displaying chaotic behavior through two linked arms.", icon: "arrow.3.trianglepath",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "L1", symbol: "L₁", label: "Length 1", unit: "m", value: 1.0, range: 0.1...2, stepSize: 0.1, physicalMeaning: "First arm length."),
            .init(id: "m1", symbol: "m₁", label: "Mass 1", unit: "kg", value: 1.0, range: 0.1...5, stepSize: 0.1, physicalMeaning: "First bob mass.")
        ], curriculumTags: ["Chaos", "Dynamics"]
    )
    
    static let planetaryOrbit = PhysicsScenario(
        id: "planetaryOrbit", title: "Planetary Orbit", subtitle: "Keplerian motion.", 
        description: "Visualizes gravity-bound orbital paths and Kepler's laws.", icon: "orbit",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "G", symbol: "G", label: "Grav Const", unit: "", value: 1.0, range: 0.1...5, stepSize: 0.1, physicalMeaning: "Gravitational scaling."),
            .init(id: "e", symbol: "e", label: "Eccentricity", unit: "", value: 0.5, range: 0...0.9, stepSize: 0.05, physicalMeaning: "Orbit shape.")
        ], curriculumTags: ["Gravity", "Astronomy"]
    )
    
    static let collisions = PhysicsScenario(
        id: "collisions", title: "Collisions", subtitle: "Elastic vs Inelastic.", 
        description: "Interaction between two bodies with momentum conservation.", icon: "hand.raised.slash",
        moduleId: "mechanics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "e", symbol: "e", label: "Restitution", unit: "", value: 1.0, range: 0...1, stepSize: 0.1, physicalMeaning: "Energy loss factor.")
        ], curriculumTags: ["Momentum", "Energy"]
    )

    // MARK: - Waves
    static let standingWave = PhysicsScenario(
        id: "standingWave", title: "Standing Wave", subtitle: "Harmonics.", 
        description: "Visualizes the vibration modes of a tensioned string.", icon: "waveform.path",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "L", symbol: "L", label: "Length", unit: "m", value: 1.0, range: 0.1...5, stepSize: 0.1, physicalMeaning: "String length."),
            .init(id: "n", symbol: "n", label: "Harmonic", unit: "", value: 1, range: 1...8, stepSize: 1, physicalMeaning: "Mode number.")
        ], curriculumTags: ["Waves"]
    )
    
    static let doppler = PhysicsScenario(
        id: "doppler", title: "Doppler Effect", subtitle: "Frequency shift.", 
        description: "Demonstrates how relative motion compresses wave peaks.", icon: "antenna.radiowaves.left.and.right",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "v_s", symbol: "vₛ", label: "Source Speed", unit: "m/s", value: 50, range: 0...300, stepSize: 5, physicalMeaning: "Speed of emitter.")
        ], curriculumTags: ["Acoustics"]
    )
    
    static let interference = PhysicsScenario(
        id: "interference", title: "Interference", subtitle: "Superposition.", 
        description: "Constructive and destructive interference patterns.", icon: "waveform.and.person",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Superposition"]
    )
    
    static let soundBeats = PhysicsScenario(
        id: "soundBeats", title: "Sound Beats", subtitle: "Freq modulation.", 
        description: "Interaction of two slightly different frequencies.", icon: "speaker.wave.3",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Acoustics"]
    )
    
    static let shockWave = PhysicsScenario(
        id: "shockWave", title: "Shock Wave", subtitle: "Supersonic boom.", 
        description: "V-shaped wave pattern produced by source speed > v_wave.", icon: "wind",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Acoustics", "Fluid Dynamics"]
    )
    
    static let huygensPrinciple = PhysicsScenario(
        id: "huygensPrinciple", title: "Huygens Principle", subtitle: "Wave propagation.", 
        description: "Visualizes wavefronts as sums of wavelets.", icon: "circle.circle",
        moduleId: "waves", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Wave Optics"]
    )

    // MARK: - Thermodynamics
    static let idealGas = PhysicsScenario(
        id: "idealGas", title: "Ideal Gas", subtitle: "Kinetic Theory.", 
        description: "Particle-level simulation showing pressure and temp.", icon: "bubbles.and.sparkles",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "N", symbol: "N", label: "Particles", unit: "", value: 50, range: 10...200, stepSize: 5, physicalMeaning: "Count."),
            .init(id: "temp", symbol: "T", label: "Temp", unit: "K", value: 300, range: 100...1000, stepSize: 10, physicalMeaning: "Avg kinetic energy.")
        ], curriculumTags: ["Stat Mech"]
    )
    
    static let carnot = PhysicsScenario(
        id: "carnot", title: "Carnot Cycle", subtitle: "Engine efficiency.", 
        description: "P-V diagram for the ideal heat engine.", icon: "engine.combustion",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Thermodynamics", "Heat Engines"]
    )
    
    static let entropyIncrease = PhysicsScenario(
        id: "entropyIncrease", title: "Entropy", subtitle: "Disorder scale.", 
        description: "Gas mixing demonstration of the 2nd law.", icon: "circle.grid.3x3",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Thermodynamics", "2nd Law"]
    )
    
    static let blackbodyRadiation = PhysicsScenario(
        id: "blackbodyRadiation", title: "Blackbody", subtitle: "Planck Spectrum.", 
        description: "Spectral intensity distribution vs temperature.", icon: "sun.max",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Quantum", "Radiation"]
    )
    
    static let stirlingEngine = PhysicsScenario(
        id: "stirlingEngine", title: "Stirling Engine", subtitle: "Heat conversion.", 
        description: "Visualizes the regenerative heat engine cycle.", icon: "gearshape.2",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Heat Engines"]
    )
    
    static let refrigerator = PhysicsScenario(
        id: "refrigerator", title: "Refrigerator", subtitle: "Cooling cycle.", 
        description: "Work-driven heat extraction from a cold reservoir.", icon: "thermometer.snowflake",
        moduleId: "thermodynamics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Thermodynamics", "Cooling"]
    )

    // MARK: - Electromagnetism
    static let electricField = PhysicsScenario(
        id: "electricField", title: "Electric Field", subtitle: "Point charges.", 
        description: "Visualize field lines between charges.", icon: "bolt.ring.closed",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Electrostatics"]
    )
    
    static let rcCircuit = PhysicsScenario(
        id: "rcCircuit", title: "RC Circuit", subtitle: "Time constants.", 
        description: "Capacitor charging through a resistor.", icon: "battery.100.bolt",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Circuits"]
    )
    
    static let lcrCircuit = PhysicsScenario(
        id: "lcrCircuit", title: "LCR Resonance", subtitle: "AC response.", 
        description: "Inductor-Capacitor-Resistor oscillation.", icon: "waveform.path.ecg",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["AC Circuits", "Resonance"]
    )
    
    static let cyclotron = PhysicsScenario(
        id: "cyclotron", title: "Cyclotron", subtitle: "Acceleration.", 
        description: "Charging particle trajectory in a B-field.", icon: "hurricane",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Magnetism", "Particle Physics"]
    )
    
    static let magneticTorque = PhysicsScenario(
        id: "magneticTorque", title: "Magnetic Torque", subtitle: "Electric motors.", 
        description: "Torque on a current loop in a field.", icon: "fanblades",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Magnetism"]
    )
    
    static let faradayLaw = PhysicsScenario(
        id: "faradayLaw", title: "Faraday's Law", subtitle: "Induction.", 
        description: "EMF generated by magnetic flux changes.", icon: "magnet",
        moduleId: "electromagnetism", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Induction", "EMF"]
    )

    // MARK: - Optics
    static let snellLaw = PhysicsScenario(
        id: "snellLaw", title: "Snell's Law", subtitle: "Refraction.", 
        description: "Light refraction across medium boundaries.", icon: "eyeglasses",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Refraction"]
    )
    
    static let lens = PhysicsScenario(
        id: "lens", title: "Thin Lens", subtitle: "Ray diagrams.", 
        description: "Focal properties of converging/diverging lenses.", icon: "camera.aperture",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Geometric Optics"]
    )
    
    static let rainbowRefraction = PhysicsScenario(
        id: "rainbowRefraction", title: "Rainbow", subtitle: "Dispersion.", 
        description: "Internal reflection and dispersion in drops.", icon: "rainbow",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Dispersion"]
    )
    
    static let diffractionGrating = PhysicsScenario(
        id: "diffractionGrating", title: "Diffraction", subtitle: "Multi-slit.", 
        description: "Spectral patterns through thin slits.", icon: "grid",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Wave Optics"]
    )
    
    static let polarization = PhysicsScenario(
        id: "polarization", title: "Polarization", subtitle: "Field filters.", 
        description: "E-field transmission based on orientation.", icon: "line.3.horizontal.circle",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Wave Optics", "Polarization"]
    )
    
    static let telescope = PhysicsScenario(
        id: "telescope", title: "Telescope", subtitle: "Magnification.", 
        description: "Visualizes the Keplerian optical system.", icon: "scope",
        moduleId: "optics", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Geometric Optics", "Instruments"]
    )

    // MARK: - Modern Physics
    static let radioactiveDecay = PhysicsScenario(
        id: "radioactiveDecay", title: "Atomic Decay", subtitle: "Half-life.", 
        description: "Statistical decay of isotope populations.", icon: "hazard.sign",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Nuclear"]
    )
    
    static let bohrModel = PhysicsScenario(
        id: "bohrModel", title: "Bohr Atom", subtitle: "Quantum levels.", 
        description: "Electron transitions and orbital radii.", icon: "orbit",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Atomic Physics", "Quantum"]
    )
    
    static let photoelectricEffect = PhysicsScenario(
        id: "photoelectricEffect", title: "Photoelectric", subtitle: "Einstein's Quanta.", 
        description: "Electron emission by specific light frequencies.", icon: "bolt.horizontal",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Quantum", "Photons"]
    )
    
    static let comptonScattering = PhysicsScenario(
        id: "comptonScattering", title: "Compton Shift", subtitle: "Photon momentum.", 
        description: "Photon wavelength shift after scattering.", icon: "sparkles",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Quantum", "Scattering"]
    )
    
    static let specialRelativityTime = PhysicsScenario(
        id: "specialRelativityTime", title: "Time Dilation", subtitle: "Near-light speed.", 
        description: "Lorentz contraction and time expansion.", icon: "clock.arrow.circlepath",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Relativity"]
    )
    
    static let schrodingerCat = PhysicsScenario(
        id: "schrodingerCat", title: "Quantum State", subtitle: "Superposition.", 
        description: "Wavefunction probability and collapse.", icon: "questionmark.circle",
        moduleId: "modern", rendererType: .canvas2D,
        defaultParameters: [], curriculumTags: ["Quantum Mechanics"]
    )

    // MARK: - Fluids (New Scenarios)
    static let archimedes = PhysicsScenario(
        id: "archimedes", title: "Archimedes' Lab", subtitle: "Buoyancy & Sink.",
        description: "Analyze upward force on submerged bodies.", icon: "drop.fill",
        moduleId: "fluids", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "mass", symbol: "m", label: "Object Mass", unit: "kg", value: 1.0, range: 0.1...10, stepSize: 0.1, physicalMeaning: "Weight of object."),
            .init(id: "radius", symbol: "r", label: "Object Radius", unit: "m", value: 0.05, range: 0.01...0.2, stepSize: 0.005, physicalMeaning: "Volume displacement."),
            .init(id: "rho_f", symbol: "ρ_f", label: "Fluid Density", unit: "kg/m³", value: 1000, range: 500...2000, stepSize: 10, physicalMeaning: "Density of the medium.")
        ], curriculumTags: ["Statics", "Fluids"]
    )

    static let terminalVelocity = PhysicsScenario(
        id: "terminalVelocity", title: "Terminal Velocity", subtitle: "Viscous Drag.",
        description: "The equilibrium between gravity and drag.", icon: "leaf.fill",
        moduleId: "fluids", rendererType: .canvas2D,
        defaultParameters: [
            .init(id: "mass", symbol: "m", label: "Mass", unit: "kg", value: 0.5, range: 0.1...5, stepSize: 0.1, physicalMeaning: "Falling mass."),
            .init(id: "rho_f", symbol: "ρ_air", label: "Air Density", unit: "kg/m³", value: 1.225, range: 0.1...5, stepSize: 0.1, physicalMeaning: "Medium density.")
        ], curriculumTags: ["Dynamics", "Aero"]
    )
}
