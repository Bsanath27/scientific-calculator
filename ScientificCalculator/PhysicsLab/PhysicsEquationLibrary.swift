// ScientificCalculator/PhysicsEngine/PhysicsEquationLibrary.swift
// Physics Equation Bridge: Theoretical Formulas & Simulation Links

import Foundation

struct PhysicsEquation: Identifiable {
    let id: String
    let name: String
    let latex: String
    let plainText: String
    let variables: [String]
    let solveFor: [String]
    let derivation: [DerivationStep]
    let scenarioLinks: [String]
    let moduleId: String
    let curriculumLevel: String

    func insertIntoCalculator() -> String {
        return plainText
    }
}

struct DerivationStep: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let expression: String              // LaTeX
    let explanation: String              // Plain English
    let physicalPrinciple: String        // e.g. "Newton's Second Law"
}

extension PhysicsEquation {
    // MARK: - Mechanics Equations
    
    static let rangeEquation = PhysicsEquation(
        id: "range_eq", name: "Horizontal Range",
        latex: "R = \\frac{v_0^2 \\sin(2\\theta)}{g}", plainText: "R = (v0^2 * sin(2*theta)) / g",
        variables: ["R", "v0", "theta", "g"], solveFor: ["R", "v0", "theta"],
        derivation: [.init(stepNumber: 1, expression: "R = v_x t", explanation: "Range is horizontal velocity times time.", physicalPrinciple: "Kinematics")],
        scenarioLinks: ["projectile"], moduleId: "mechanics", curriculumLevel: "AP"
    )

    static let orbitalPeriod = PhysicsEquation(
        id: "orbit_period", name: "Kepler's Third Law",
        latex: "T^2 = \\frac{4\\pi^2 r^3}{GM}", plainText: "T = sqrt(4 * pi^2 * r^3 / (G * M))",
        variables: ["T", "r", "G", "M"], solveFor: ["T", "r"],
        derivation: [], scenarioLinks: ["planetaryOrbit"],
        moduleId: "mechanics", curriculumLevel: "University"
    )

    // MARK: - Waves
    static let dopplerShift = PhysicsEquation(
        id: "doppler_shift", name: "Doppler Effect",
        latex: "f' = f \\left( \\frac{v}{v \\mp v_s} \\right)", plainText: "f_prime = f * (v / (v - v_s))",
        variables: ["f_prime", "f", "v", "v_s"], solveFor: ["f_prime"],
        derivation: [], scenarioLinks: ["doppler"],
        moduleId: "waves", curriculumLevel: "IB"
    )

    // MARK: - Thermo
    static let idealGasLaw = PhysicsEquation(
        id: "ideal_gas_law", name: "Ideal Gas Law",
        latex: "PV = nRT", plainText: "P * V = n * R * T",
        variables: ["P", "V", "n", "R", "T"], solveFor: ["P", "V", "T"],
        derivation: [], scenarioLinks: ["idealGas"],
        moduleId: "thermodynamics", curriculumLevel: "General"
    )

    static let carnotEfficiency = PhysicsEquation(
        id: "carnot_eff", name: "Carnot Efficiency",
        latex: "\\eta = 1 - \\frac{T_c}{T_h}", plainText: "eta = 1 - (Tc / Th)",
        variables: ["eta", "Tc", "Th"], solveFor: ["eta"],
        derivation: [], scenarioLinks: ["carnot"],
        moduleId: "thermodynamics", curriculumLevel: "Intermediate"
    )

    // MARK: - EM
    static let coulombsLaw = PhysicsEquation(
        id: "coulomb_law", name: "Coulomb's Law",
        latex: "F = k \\frac{q_1 q_2}{r^2}", plainText: "F = k * q1 * q2 / r^2",
        variables: ["F", "k", "q1", "q2", "r"], solveFor: ["F", "r"],
        derivation: [], scenarioLinks: ["electricField"],
        moduleId: "electromagnetism", curriculumLevel: "AP"
    )

    static let faradayInduction = PhysicsEquation(
        id: "faraday_induction", name: "Faraday's Law",
        latex: "\\mathcal{E} = -N \\frac{d\\Phi_B}{dt}", plainText: "emf = -N * delta_phi / delta_t",
        variables: ["emf", "N", "delta_phi", "delta_t"], solveFor: ["emf"],
        derivation: [], scenarioLinks: ["faradayLaw"],
        moduleId: "electromagnetism", curriculumLevel: "Advanced"
    )

    // MARK: - Optics
    static let snellsLaw = PhysicsEquation(
        id: "snell_law", name: "Snell's Law",
        latex: "n_1 \\sin\\theta_1 = n_2 \\sin\\theta_2", plainText: "n1 * sin(theta1) = n2 * sin(theta2)",
        variables: ["n1", "theta1", "n2", "theta2"], solveFor: ["theta1", "theta2", "n2"],
        derivation: [], scenarioLinks: ["snellLaw"],
        moduleId: "optics", curriculumLevel: "General"
    )

    // MARK: - Modern
    static let photoelectricEq = PhysicsEquation(
        id: "photoelectric_eq", name: "Photoelectric Effect",
        latex: "K_{max} = hf - \\Phi", plainText: "K_max = h * f - phi",
        variables: ["K_max", "h", "f", "phi"], solveFor: ["K_max", "f"],
        derivation: [], scenarioLinks: ["photoelectricEffect"],
        moduleId: "modern", curriculumLevel: "Advanced"
    )

    static let massEnergy = PhysicsEquation(
        id: "mass_energy", name: "Mass-Energy Equivalence",
        latex: "E = mc^2", plainText: "E = m * c^2",
        variables: ["E", "m", "c"], solveFor: ["E", "m"],
        derivation: [], scenarioLinks: ["specialRelativityTime"],
        moduleId: "modern", curriculumLevel: "Modern General"
    )

    static let allEquations: [PhysicsEquation] = [
        .rangeEquation, .orbitalPeriod, .dopplerShift, .idealGasLaw, 
        .carnotEfficiency, .coulombsLaw, .faradayInduction, 
        .snellsLaw, .photoelectricEq, .massEnergy
    ]
}
