// ScientificCalculator/UI/Components/PhysicsViewModel.swift
// Physics Lab ViewModel: Simulation Control, State, and Comparisons

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Combine

@MainActor
final class PhysicsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var selectedModule: PhysicsModule = .mechanics
    @Published var selectedScenario: PhysicsScenario = .projectile {
        didSet { loadScenario() }
    }
    
    @Published var parameters: [String: Double] = [:]
    @Published var frames: [SimulationFrame] = []
    @Published var currentFrameIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var playbackSpeed: Double = 1.0
    @Published var autoExportToVariableStore: Bool = false
    
    @Published var showEnergyPanel: Bool = false
    @Published var showEquationPanel: Bool = false
    @Published var showFBD: Bool = false
    @Published var showDerivationPanel: Bool = false
    
    // Viewport Control
    @Published var viewportZoom: Double = 1.0
    @Published var viewportOffset: CGSize = .zero
    @Published var lastZoom: Double = 1.0
    @Published var lastDragOffset: CGSize = .zero
    
    @Published var comparisonMode: Bool = false
    @Published var comparisonParameters: [String: Double] = [:]
    @Published var comparisonFrames: [SimulationFrame] = []
    
    @Published var annotations: [FrameAnnotation] = []
    @Published var derivedResults: [String: String] = [:]
    
    // Gravity Field Interaction State
    @Published var gravityMasses: [(pos: WorldPoint, m: Double)] = []
    @Published var testParticles: [TestParticle] = []
    @Published var showModelImporter: Bool = false
    
    struct TestParticle: Identifiable {
        let id = UUID()
        var pos: WorldPoint
        var vel: WorldPoint
    }
    
    // MARK: - Private
    
    private let simulator = PhysicsSimulator()
    private var playbackTimer: AnyCancellable?
    private var parameterUpdateSubject = PassthroughSubject<(String, Double), Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        setupParameterDebounce()
        loadScenario()
    }
    
    private func setupParameterDebounce() {
        parameterUpdateSubject
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] id, value in
                self?.parameters[id] = value
                if self?.comparisonMode == true {
                    self?.runComparisonSimulation()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    func loadScenario() {
        stopPlayback()
        currentFrame = nil
        
        // Reset parameters to defaults
        var pDict: [String: Double] = [:]
        for p in selectedScenario.defaultParameters {
            pDict[p.id] = p.value
        }
        parameters = pDict
        
        // Initial frame
        currentFrame = simulator.nextFrame(scenario: selectedScenario, parameters: parameters, previousFrame: nil, dt: 0)
        
        startPlayback() // Always run in real-time mode
    }
    
    func resetViewport() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            viewportZoom = 1.0
            lastZoom = 1.0
            viewportOffset = .zero
            lastDragOffset = .zero
        }
    }
    
    func updateParameter(_ id: String, value: Double) {
        parameters[id] = value
        parameterUpdateSubject.send((id, value))
    }
    
    func selectScenario(byId id: String) {
        if let scenario = PhysicsScenario.allCases.first(where: { $0.id == id }) {
            if let module = PhysicsModule.allModules.first(where: { $0.id == scenario.moduleId }) {
                selectedModule = module
            }
            selectedScenario = scenario
        }
    }

    
    // MARK: - Gravity Field Interactivity
    
    func addGravityMass(at worldPos: WorldPoint, mass: Double) {
        gravityMasses.append((pos: worldPos, m: mass))
        if isPlaying == false { startPlayback() }
    }
    
    func releaseTestParticle(at worldPos: WorldPoint, velocity: WorldPoint) {
        testParticles.append(TestParticle(pos: worldPos, vel: velocity))
        if isPlaying == false { startPlayback() }
    }
    
    func clearGravityField() {
        gravityMasses.removeAll()
        testParticles.removeAll()
    }
    
    // MARK: - USDZ Import
    
    func importUSDZModel(url: URL, scenarioId: String) {
        // Technical placeholder: In a full app, this would use RealityKit to load Entity
        // and switch to the target scenario.
        selectScenario(byId: scenarioId)
        print("Importing model from \(url) into \(scenarioId)")
    }
    
    func placeAnnotationPin(at worldPos: WorldPoint, label: String) {
        let annotation = FrameAnnotation(position: worldPos, label: label, type: .peak)
        annotations.append(annotation)
    }
    
    func loadPreset(_ presetName: String) {
        // In a real app, this would load from a JSON or plist
        // For now, we'll reset to defaults as a "Base" preset
        loadScenario()
    }
    
    func activateComparisonMode() {
        comparisonMode = true
        comparisonParameters = parameters
        runComparisonSimulation()
    }
    
    private func runComparisonSimulation() {
        // Batch simulate for comparison overlay
        comparisonFrames = simulator.simulate(scenario: selectedScenario, parameters: comparisonParameters)
    }
    
    #if canImport(UIKit)
    func exportCanvasAsImage() -> UIImage? {
        // Technical placeholder: This would involve Snapshotting the Canvas
        return nil
    }
    #elseif canImport(AppKit)
    func exportCanvasAsImage() -> NSImage? {
        // Technical placeholder: This would involve Snapshotting the Canvas
        return nil
    }
    #endif
    
    @Published var currentFrame: SimulationFrame?
    
    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    func startPlayback() {
        isPlaying = true
        playbackTimer = Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.stepSimulation()
            }
    }
    
    private func stepSimulation() {
        let dt = (1.0/60.0) * playbackSpeed
        
        if selectedScenario.id == "gravityField" {
            stepGravityInteraction(dt: dt)
        } else {
            currentFrame = simulator.nextFrame(scenario: self.selectedScenario, parameters: self.parameters, previousFrame: self.currentFrame, dt: dt)
        }
        updateDerivedResults()
    }
    
    private func stepGravityInteraction(dt: Double) {
        // Integrate test particles in the field setup by gravityMasses
        for i in 0..<testParticles.count {
            let field = PhysicsSimulator.GravityFieldSampler.sample(masses: gravityMasses, at: testParticles[i].pos)
            // F = ma -> a = F/m (unit mass for test particle)
            testParticles[i].vel = WorldPoint(testParticles[i].vel.x + field.x * dt * 1e11, // Scaling for visual speed
                                               testParticles[i].vel.y + field.y * dt * 1e11)
            testParticles[i].pos = WorldPoint(testParticles[i].pos.x + testParticles[i].vel.x * dt,
                                               testParticles[i].pos.y + testParticles[i].vel.y * dt)
        }
        
        // Sampling points for field visualization
        var gridPoints: [WorldPoint] = []
        var fieldVectors: [WorldPoint] = []
        for x in stride(from: -30.0, to: 30.0, by: 4.0) {
            for y in stride(from: -20.0, to: 20.0, by: 4.0) {
                let p = WorldPoint(x, y)
                gridPoints.append(p)
                fieldVectors.append(PhysicsSimulator.GravityFieldSampler.sample(masses: gravityMasses, at: p))
            }
        }
        
        currentFrame = SimulationFrame(
            time: (currentFrame?.time ?? 0) + dt,
            state: [
                "masses": gravityMasses,
                "grid": gridPoints,
                "field": fieldVectors,
                "testParticles": testParticles.map { $0.pos }
            ],
            energy: .zero,
            annotations: [],
            fbd: nil
        )
    }
    
    func pausePlayback() {
        isPlaying = false
        playbackTimer?.cancel()
        playbackTimer = nil
    }
    
    func stopPlayback() {
        pausePlayback()
        currentFrame = nil
    }
    
    func resetToDefaults() {
        loadScenario()
    }
    
    // MARK: - Derived Results
    
    private func updateDerivedResults() {
        // Logic to extract final/peak values from frames and format them
        guard let current = currentFrame else { return }
        
        var results: [String: String] = [:]
        
        switch selectedScenario.id {
        case "projectile":
            if let x = current.state["x"] as? Double { results["Range"] = String(format: "%.2f m", x) }
            if let y = current.state["y"] as? Double { results["Height"] = String(format: "%.2f m", y) }
            results["Total Energy"] = String(format: "%.2f J", current.energy.total)
            
        case "pendulum":
            let period = 2 * .pi * sqrt((parameters["L"] ?? 1.0) / (parameters["g"] ?? 9.81))
            results["Period (approx)"] = String(format: "%.3f s", period)
            
        case "springMass":
            let omega = sqrt((parameters["k"] ?? 50.0) / (parameters["m"] ?? 1.0))
            results["Frequency"] = String(format: "%.3f Hz", omega / (2 * .pi))

        case "standingWave":
            let T = parameters["T"] ?? 100.0
            let mu = 0.01
            let v = sqrt(T / mu)
            results["Wave Speed"] = String(format: "%.1f m/s", v)
            results["Fundamental"] = String(format: "%.1f Hz", v / (2 * (parameters["L"] ?? 1.0)))

        case "idealGas":
            results["Avg Kinetic Energy"] = String(format: "%.2f eV", (parameters["temp"] ?? 300.0) * 8.617e-5)
            results["Pressure (rel)"] = String(format: "%.1f kPa", (parameters["temp"] ?? 300.0) * (parameters["N"] ?? 50.0) / 1000.0)

        case "electricField":
            let q1 = parameters["q1"] ?? 5.0
            let q2 = parameters["q2"] ?? -5.0
            results["Dipole Moment"] = String(format: "%.1f μC·m", abs(q1 - q2) * 20.0)

        case "rcCircuit":
            let R = parameters["R"] ?? 1000.0
            let C = (parameters["C"] ?? 100.0) * 1e-6
            results["Time Constant (τ)"] = String(format: "%.3f s", R * C)

        case "snellLaw":
            let n1 = parameters["n1"] ?? 1.0
            let n2 = parameters["n2"] ?? 1.5
            let theta1 = 30.0 * .pi / 180
            let theta2 = asin(n1 * sin(theta1) / n2) * 180 / .pi
            results["Refraction Angle"] = String(format: "%.1f°", theta2)

        case "lens":
            if let di = current.state["d_i"] as? Double { results["Image Distance"] = String(format: "%.1f cm", di) }
            if let hi = current.state["h_i"] as? Double { results["Magnification"] = String(format: "%.2f x", abs(hi / 10.0)) }

        case "radioactiveDecay":
            let lambda = log(2) / (parameters["t_half"] ?? 5.0)
            results["Decay Constant"] = String(format: "%.3f s⁻¹", lambda)

        case "bohrModel":
            let Z = parameters["Z"] ?? 1.0
            let n = parameters["n_init"] ?? 2.0
            let Energy = -13.6 * (Z * Z) / (n * n)
            results["Energy Level"] = String(format: "%.2f eV", Energy)
            
        default:
            break
        }
        
        self.derivedResults = results
    }
    
    // MARK: - Integration
    
    func exportToVariableStore(_ store: VariableStore) {
        for (key, val) in parameters {
            store.addVariable(name: "phys_\(key)", value: val)
        }
        // Export derived results numeric values
        for (key, valStr) in derivedResults {
            let numeric = valStr.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
            if let num = Double(numeric) {
                let safeKey = key.lowercased().replacingOccurrences(of: " ", with: "_")
                store.addVariable(name: "phys_res_\(safeKey)", value: num)
            }
        }
    }
}
