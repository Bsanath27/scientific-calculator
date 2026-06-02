// ScientificCalculator/UI/Components/PhysicsLabView.swift
// Physics Lab Main UI: Responsive Multi-Column Lab Interface

import SwiftUI

struct PhysicsLabView: View {
    let scenarioId: String?
    @StateObject private var viewModel = PhysicsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) var sizeClass
    
    init(scenarioId: String? = nil) {
        self.scenarioId = scenarioId
    }
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
        .sheet(isPresented: $viewModel.showEnergyPanel) {
            EnergyPanel()
                .presentationDetents([.height(200), .medium])
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $viewModel.showModelImporter) {
            PhysicsModelImportView()
                .environmentObject(viewModel)
        }
        .background(themeManager.current.background)
        .environmentObject(viewModel)
        .onAppear {
            if let scenarioId = scenarioId {
                viewModel.selectScenario(byId: scenarioId)
            }
        }
    }
    
    // MARK: - Layouts
    
    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left Column: Module & Scenario Picker
            ModulePickerColumn()
                .frame(width: 280)
                .background(themeManager.current.surface.opacity(0.5))
            
            Divider()
            
            // Center Column: Simulation Canvas
            SimulationCanvasColumn()
            
            Divider()
            
            // Right Column: Controls & Equations
            ControlsColumn()
                .frame(width: 320)
                .background(themeManager.current.surface.opacity(0.5))
        }
    }
    
    @State private var activeiPhoneSection: iPhoneSection = .lab

    enum iPhoneSection: String, CaseIterable {
        case lab = "Lab"
        case controls = "Controls"
        case explore = "Explore"
    }

    private var iPhoneLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Picker("Section", selection: $activeiPhoneSection) {
                    ForEach(iPhoneSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(themeManager.current.surface.opacity(0.8))

                switch activeiPhoneSection {
                case .lab:
                    SimulationCanvasColumn()
                case .controls:
                    ControlsColumn()
                case .explore:
                    ModulePickerColumn()
                }
                
                // Add bottom padding to clear the floating tab bar
                Spacer()
                    .frame(height: DeviceLayout.tabBarPadding(width: geo.size.width))
            }
        }
    }
}

// MARK: - Components

struct ModulePickerColumn: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            ForEach(PhysicsModule.allModules) { module in
                Section(header: Text(module.name).font(.system(.caption, design: .monospaced)).foregroundColor(module.color).opacity(0.8)) {
                    ForEach(module.scenarios) { scenario in
                        ScenarioRow(scenario: scenario)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.background)
    }
}

struct ScenarioRow: View {
    let scenario: PhysicsScenario
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                viewModel.selectedScenario = scenario 
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(viewModel.selectedScenario.id == scenario.id ? themeManager.current.accent.opacity(0.2) : Color.clear)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: scenario.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.selectedScenario.id == scenario.id ? themeManager.current.accent : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.title)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(viewModel.selectedScenario.id == scenario.id ? .bold : .medium)
                        .foregroundColor(viewModel.selectedScenario.id == scenario.id ? themeManager.current.textPrimary : .secondary)
                    
                    Text(scenario.subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.selectedScenario.id == scenario.id {
                    Circle()
                        .fill(themeManager.current.accent)
                        .frame(width: 4, height: 4)
                        .shadow(color: themeManager.current.accent, radius: 2)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(viewModel.selectedScenario.id == scenario.id ? themeManager.current.surface.opacity(0.5) : Color.clear)
            .cornerRadius(8)
            .scaleEffect(isHovering ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct SimulationCanvasColumn: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var hubOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    let cs = CoordinateSystem.make(
                        for: viewModel.selectedScenario.id,
                        canvasSize: geo.size,
                        userZoom: viewModel.viewportZoom,
                        userOffset: viewModel.viewportOffset
                    )
                    
                    Canvas { context, size in
                        guard let frame = viewModel.currentFrame else { return }
                        
                        // Apply Scenario Renderer
                        switch viewModel.selectedScenario.id {
                        case "projectile":
                            PhysicsCanvasRenderer.renderProjectile(context: &context, frame: frame, fullHistory: [], cs: cs, theme: themeManager.current)
                        case "pendulum":
                            PhysicsCanvasRenderer.renderPendulum(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "springMass":
                            PhysicsCanvasRenderer.renderSpringMass(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "standingWave":
                            PhysicsCanvasRenderer.renderStandingWave(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "doppler":
                            PhysicsCanvasRenderer.renderDoppler(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "idealGas":
                            PhysicsCanvasRenderer.renderIdealGas(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "carnot":
                            PhysicsCanvasRenderer.renderCarnot(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "electricField":
                            PhysicsCanvasRenderer.renderElectricField(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "rcCircuit":
                            PhysicsCanvasRenderer.renderRCCircuit(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "snellLaw":
                            PhysicsCanvasRenderer.renderSnellLaw(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "lens":
                            PhysicsCanvasRenderer.renderLens(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "radioactiveDecay":
                            PhysicsCanvasRenderer.renderRadioactiveDecay(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "bohrModel":
                            PhysicsCanvasRenderer.renderBohrModel(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        case "gravityField":
                            PhysicsCanvasRenderer.renderGravityField(context: &context, frame: frame, cs: cs, theme: themeManager.current)
                        default:
                            break
                        }
                    }
                    .background(Color.black)
                    .overlay {
                        if viewModel.selectedScenario.rendererType == .realityKit3D {
                            // Technical integration for RealityKit: RealityView (iOS 17+)
                            ZStack {
                                Color.black
                                Text("REALITY ENGINE ACTIVE").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(themeManager.current.accent)
                                Image(systemName: "arkit").font(.largeTitle).foregroundColor(themeManager.current.accent).padding()
                            }
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                viewModel.viewportZoom = viewModel.lastZoom * value.magnitude
                            }
                            .onEnded { _ in
                                viewModel.lastZoom = viewModel.viewportZoom
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.viewportOffset = CGSize(
                                    width: viewModel.lastDragOffset.width + value.translation.width,
                                    height: viewModel.lastDragOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                viewModel.lastDragOffset = viewModel.viewportOffset
                            }
                    )
                    
                    if viewModel.selectedScenario.id == "gravityField", let frame = viewModel.currentFrame {
                        GravityFieldView(viewModel: viewModel, frame: frame, cs: cs, theme: themeManager.current)
                    }
                    
                    if viewModel.showFBD, let frame = viewModel.currentFrame {
                        PhysicsFBDOverlayView(frame: frame, cs: cs, theme: themeManager.current)
                    }
                }
                
                // HUD Overlays
                ObservatoryHUDOverlay()
                    .padding()
                    .opacity(hubOpacity)
            }
            .onAppear { withAnimation(.easeIn(duration: 1.0)) { hubOpacity = 1.0 } }
            
            // Modern Timeline Bar
            TimelineControlView()
                .padding()
                .background(themeManager.current.surface.opacity(0.8))
        }
    }
}

struct HUDControlButton: View {
    let icon: String
    let action: () -> Void
    var isActive: Bool = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isActive ? .white : themeManager.current.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? themeManager.current.accent : themeManager.current.surface.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.current.accent.opacity(isActive ? 0.5 : 0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ObservatoryHUDOverlay: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Circle().fill(Color.red).frame(width: 6, height: 6)
                Text(viewModel.selectedScenario.rendererType == .realityKit3D ? "SPATIAL LAB" : "LIVE SIMULATION").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.8))
            
            Text(viewModel.selectedScenario.id.uppercased())
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(themeManager.current.accent)
            
            // Minimal Energy Bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("ENERGY FLUX").font(.system(size: 8, design: .monospaced)).foregroundColor(.secondary)
                Capsule().fill(Color.white.opacity(0.1)).frame(width: 100, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule().fill(themeManager.current.accent).frame(width: 70, height: 4)
                            .shadow(color: themeManager.current.accent, radius: 4)
                    }
            }
            
            // Viewport & FBD Controls
            HStack(spacing: 8) {
                HUDControlButton(icon: "plus.app.fill", action: { viewModel.showModelImporter.toggle() })
                HUDControlButton(icon: "arrow.up.left.and.arrow.down.right.circle", action: { viewModel.showFBD.toggle() }, isActive: viewModel.showFBD)
                HUDControlButton(icon: "scope", action: { viewModel.resetViewport() })
                
                Text(String(format: "%.1fx", viewModel.viewportZoom))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(themeManager.current.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(themeManager.current.surface.opacity(0.8)))
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.current.accent.opacity(0.2), lineWidth: 1))
    }
}

struct TimelineControlView: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.loadScenario() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
            }
            
            Button(action: { viewModel.togglePlayback() }) {
                ZStack {
                    Circle()
                        .fill(themeManager.current.accent)
                        .frame(width: 44, height: 44)
                        .shadow(color: themeManager.current.accent.opacity(0.5), radius: 8)
                    
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TIME ELAPSED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Text(String(format: "%.3f s", viewModel.currentFrame?.time ?? 0.0))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeManager.current.accent)
            }
            
            Spacer()
            
            // Playback Speed Toggle
            Menu {
                Button("0.5x") { viewModel.playbackSpeed = 0.5 }
                Button("1.0x") { viewModel.playbackSpeed = 1.0 }
                Button("2.0x") { viewModel.playbackSpeed = 2.0 }
            } label: {
                Text(String(format: "%.1fx", viewModel.playbackSpeed))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().stroke(themeManager.current.accent.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8) // Small default padding
        .buttonStyle(.plain)
    }
}

struct EnergyPanel: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("ENERGY DISTRIBUTION")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            
            if let energy = viewModel.currentFrame?.energy {
                EnergyBar(label: "KINETIC", value: energy.kinetic, total: energy.total, color: .blue)
                EnergyBar(label: "POTENTIAL", value: energy.potential, total: energy.total, color: .green)
                
                Divider()
                
                HStack {
                    Text("TOTAL MECHANICAL")
                    Spacer()
                    Text(String(format: "%.3f J", energy.total))
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(themeManager.current.accent)
            }
        }
        .padding()
    }
}

struct EnergyBar: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 9, weight: .bold))
                Spacer()
                Text(String(format: "%.2f J", value)).font(.system(size: 9, design: .monospaced))
            }
            GeometryReader { geo in
                let ratio = total > 0 ? CGFloat(value / total) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(color).frame(width: geo.size.width * max(0, min(1, ratio)))
                }
            }
            .frame(height: 6)
        }
    }
}

struct ControlsColumn: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("LAB PARAMETERS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                ForEach(viewModel.selectedScenario.defaultParameters) { param in
                    ObservatoryParamDial(param: param)
                }
                
                Divider().background(themeManager.current.accent.opacity(0.2))
                
                ObservatoryAnalyticsSection()
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct ObservatoryAnalyticsSection: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ANALYTICS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.showEnergyPanel.toggle() }) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(viewModel.showEnergyPanel ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.derivedResults.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key.uppercased())
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.derivedResults[key] ?? "")
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .foregroundColor(themeManager.current.accent)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(themeManager.current.surface.opacity(0.8)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(themeManager.current.accent.opacity(0.1), lineWidth: 1))
                }
            }
            
            // Comparison Toggle
            Button(action: { viewModel.comparisonMode.toggle() }) {
                HStack {
                    Image(systemName: "square.2.layers.3d.bottom.filled")
                    Text("COMPARISON MODE")
                    Spacer()
                    Toggle("", isOn: $viewModel.comparisonMode).labelsHidden().scaleEffect(0.8)
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.comparisonMode ? themeManager.current.accent.opacity(0.2) : themeManager.current.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.comparisonMode ? themeManager.current.accent : Color.clear, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

struct ObservatoryParamDial: View {
    let param: PhysicsParameter
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(param.label)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Spacer()
                Text(String(format: "%.2f %@", viewModel.parameters[param.id] ?? param.value, param.unit))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(themeManager.current.accent)
            }
            
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.05)).frame(height: 6)
                
                Slider(value: Binding(get: { viewModel.parameters[param.id] ?? param.value }, set: { viewModel.updateParameter(param.id, value: $0) }), in: param.range)
                    .accentColor(themeManager.current.accent)
            }
            
            Text(param.physicalMeaning)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
}


// MARK: - Helpers
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
