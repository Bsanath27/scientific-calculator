// UI/CircuitView.swift
// Scientific Calculator - Interactive Circuit Canvas

import SwiftUI

struct CircuitToolView: View {
    @StateObject var viewModel = CircuitViewModel()
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. Component Palette (Sidebar)
            VStack(spacing: 16) {
                Text("Palette")
                    .font(.caption.bold())
                    .foregroundColor(theme.current.textSecondary)
                
                ForEach(CircuitComponent.ComponentType.allCases, id: \.self) { type in
                    PaletteButton(type: type) {
                        viewModel.addComponent(type, at: CGPoint(x: 200, y: 200))
                    }
                }
                
                Spacer()
                
                Button("Reset") { viewModel.resetToDefault() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(width: 100)
            .background(theme.current.surface.opacity(0.8))
            
            // 2. Main Canvas
            ZStack {
                CircuitGrid()
                    .stroke(theme.current.divider.opacity(0.3), lineWidth: 1)
                
                // Animated Wires (Current Flow)
                ForEach(viewModel.components) { comp in
                    CircuitComponentView(component: comp, solution: viewModel.solution)
                }
                
                // Bridge to Physics Lab Prompt
                if viewModel.showBridgePrompt {
                    BridgePrompt(onAccept: {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToRoute"),
                            object: AppRoute.physicsLab(scenarioId: "rcCircuit")
                        )
                        viewModel.showBridgePrompt = false
                    }, onDismiss: {
                        viewModel.showBridgePrompt = false
                    })
                }
            }
            .background(theme.current.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }
}

struct CircuitGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct PaletteButton: View {
    let type: CircuitComponent.ComponentType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName(for: type))
                    .font(.title2)
                Text(type.rawValue)
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(width: 70, height: 70)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func iconName(for type: CircuitComponent.ComponentType) -> String {
        switch type {
        case .resistor: return "square.grid.2x2"
        case .capacitor: return "pause"
        case .inductor: return "water.waves"
        case .voltageSource: return "bolt.circle"
        case .currentSource: return "arrow.up.circle"
        case .sw: return "switch.2"
        }
    }
}

struct CircuitComponentView: View {
    let component: CircuitComponent
    let solution: CircuitSolution?
    @State private var phase: CGFloat = 0
    
    var body: some View {
        autoreleasepool {
            let p1 = nodeToPoint(component.nodes[0])
            let p2 = nodeToPoint(component.nodes.count > 1 ? component.nodes[1] : component.nodes[0])
            let current = solution?.branchCurrents[component.id] ?? 0
            
            ZStack {
                // Connection Line
                Path { path in
                    path.move(to: p1)
                    path.addLine(to: p2)
                }
                .stroke(Color.gray, lineWidth: 2)
                
                // Current Animation (Dots)
                if abs(current) > 1e-9 {
                    CurrentDots(p1: p1, p2: p2, current: current)
                }
                
                // Component Label
                VStack {
                    Text(component.type.rawValue)
                        .font(.caption2.bold())
                    Text(formatValue(component.value, type: component.type))
                        .font(.system(size: 10, design: .monospaced))
                }
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
                .position(x: (p1.x + p2.x)/2, y: (p1.y + p2.y)/2 - 20)
            }
        }
    }
    
    private func nodeToPoint(_ node: Int) -> CGPoint {
        let x = CGFloat(node % 10) * 40 + 20
        let y = CGFloat(node / 10) * 40 + 20
        return CGPoint(x: x, y: y)
    }
    
    private func formatValue(_ v: Double, type: CircuitComponent.ComponentType) -> String {
        switch type {
        case .resistor: return "\(Int(v))Ω"
        case .voltageSource: return "\(Int(v))V"
        case .currentSource: return "\(v*1000)mA"
        default: return "\(v)"
        }
    }
}

struct CurrentDots: View {
    let p1: CGPoint
    let p2: CGPoint
    let current: Double
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: 4, height: 4)
            .modifier(AnimateOnPath(p1: p1, p2: p2, phase: phase))
            .onAppear {
                withAnimation(.linear(duration: max(0.2, 2.0 / abs(current))).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

struct AnimateOnPath: GeometryEffect {
    var p1: CGPoint
    var p2: CGPoint
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = p1.x + (p2.x - p1.x) * phase
        let y = p1.y + (p2.y - p1.y) * phase
        return ProjectionTransform(CGAffineTransform(translationX: x - p1.x, y: y - p1.y))
    }
}

struct BridgePrompt: View {
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flask.fill")
                .font(.title)
                .foregroundColor(.accentColor)
            Text("Transient Detected")
                .font(.headline)
            Text("This RC/RL/LC circuit has time-domain characteristics. Open in Physics Lab for scope analysis?")
                .font(.caption)
                .multilineTextAlignment(.center)
            
            HStack {
                Button("Later", action: onDismiss)
                    .buttonStyle(.bordered)
                Button("Open Lab", action: onAccept)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(width: 250)
    }
}
