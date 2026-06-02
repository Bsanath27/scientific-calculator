// UI/Components/CircuitLabView.swift
// Scientific Calculator - Interactive Schematic Editor (Luxe UI)

import SwiftUI

struct CircuitLabView: View {
    @State private var components: [CircuitComponent] = []
    @State private var selectedNode: Int? = nil
    @State private var simulationResult: CircuitSimulationResult? = nil
    @EnvironmentObject var theme: ThemeManager
    
    private let engine = CircuitEngine()
    
    var body: some View {
        VStack(spacing: 0) {
            // Schematic Canvas
            ZStack {
                theme.current.background
                    .ignoresSafeArea()
                
                // Grid Background
                Canvas { context, size in
                    drawGrid(context: context, size: size)
                }
                
                // Components and Connections
                Canvas { context, size in
                    for comp in components {
                        drawComponent(context: context, comp: comp)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleCanvasTap(at: value.location)
                        }
                )
                
                // Result Overlays
                if let results = simulationResult {
                    NodeVoltageOverlay(results: results)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.current.divider, lineWidth: 1)
            )
            .padding()
            
            // Toolbar / Component Picker
            HStack(spacing: 16) {
                ComponentButton(type: .resistor, label: "Resistor", icon: "square.dashed") {
                    addComponent(.resistor, value: 1000)
                }
                ComponentButton(type: .voltageSource, label: "V-Source", icon: "plus.circle") {
                    addComponent(.voltageSource, value: 5)
                }
                ComponentButton(type: .currentSource, label: "I-Source", icon: "arrow.up.circle") {
                    addComponent(.currentSource, value: 0.01)
                }
                
                Spacer()
                
                Button(action: solve) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Simulate")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.current.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: { components.removeAll(); simulationResult = nil }) {
                    Image(systemName: "trash")
                        .foregroundColor(theme.current.modernRed)
                }
            }
            .padding()
            .background(theme.current.displayBackground)
        }
    }
    
    private func addComponent(_ type: CircuitComponentType, value: Double) {
        // Simple placement logic for demo
        let node1 = components.isEmpty ? 0 : components.count
        let node2 = node1 + 1
        let newComp = CircuitComponent(type: type, value: value, node1: node1, node2: node2)
        components.append(newComp)
    }
    
    private func solve() {
        simulationResult = engine.solveDC(components: components)
    }
    
    private func handleCanvasTap(at point: CGPoint) {
        // Placeholder for node selection/connection logic
    }
    
    // MARK: - Drawing Helpers
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 20
        var p = Path()
        for x in stride(from: 0, to: size.width, by: spacing) {
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
        }
        for y in stride(from: 0, to: size.height, by: spacing) {
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(p, with: .color(theme.current.divider.opacity(0.3)), lineWidth: 0.5)
    }
    
    private func drawComponent(context: GraphicsContext, comp: CircuitComponent) {
        // Simple illustrative drawing
        let start = CGPoint(x: 100, y: CGFloat(comp.node1 * 60 + 50))
        let end = CGPoint(x: 200, y: CGFloat(comp.node1 * 60 + 50))
        
        var p = Path()
        p.move(to: start)
        p.addLine(to: end)
        context.stroke(p, with: .color(theme.current.textPrimary), lineWidth: 2)
        
        // Add label and value
        context.draw(Text(comp.label).font(.caption).foregroundColor(theme.current.accent), at: CGPoint(x: 150, y: start.y - 15))
    }
}

struct ComponentButton: View {
    let type: CircuitComponentType
    let label: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 60)
            .padding(8)
            .background(theme.current.background)
            .foregroundColor(theme.current.textPrimary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.current.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct NodeVoltageOverlay: View {
    let results: CircuitSimulationResult
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Canvas { context, size in
            for (node, voltage) in results.nodeVoltages {
                let pos = CGPoint(x: 80, y: CGFloat(node * 60 + 50))
                context.draw(Text(String(format: "%.2fV", voltage)).font(.caption2.bold()).foregroundColor(theme.current.opticsGreen), at: pos)
            }
        }
        .allowsHitTesting(false)
    }
}
