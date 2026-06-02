// ScientificCalculator/UI/Components/FBDOverlayView.swift
// Interactive FBD Overlay: Tappable Force Vectors and Magnitude Popovers

import SwiftUI

struct PhysicsFBDOverlayView: View {
    let frame: SimulationFrame
    let cs: CoordinateSystem
    let theme: ColorPalette
    
    @State private var selectedForce: FBDState.ForceComponent?
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                guard let fbd = frame.fbd else { return }
                let origin = getObjectPosition()
                let sOrigin = cs.toScreen(origin)
                
                for component in fbd.components {
                    drawVector(context: context, from: sOrigin, component: component)
                }
            }
            .allowsHitTesting(false) // Canvas itself shouldn't block, we use transparent buttons for hits
            
            // Hit areas for force vectors
            if let fbd = frame.fbd {
                let origin = getObjectPosition()
                let sOrigin = cs.toScreen(origin)
                
                ForEach(fbd.components) { component in
                    ForceHitArea(origin: sOrigin, component: component, cs: cs) {
                        selectedForce = component
                    }
                }
            }
        }
        .popover(item: $selectedForce) { force in
            ForceDetailView(force: force, theme: theme)
                .presentationCompactAdaptation(.popover)
        }
    }
    
    private func getObjectPosition() -> WorldPoint {
        if let x = frame.state["x"] as? Double, let y = frame.state["y"] as? Double {
            return WorldPoint(x, y)
        }
        if let theta = frame.state["theta"] as? Double {
            let L = (frame.state["L"] as? Double) ?? 1.0
            return WorldPoint(L * sin(theta), -L * cos(theta))
        }
        return WorldPoint(0, 0)
    }
    
    private func drawVector(context: GraphicsContext, from origin: CGPoint, component: FBDState.ForceComponent) {
        let scale: CGFloat = 8.0
        let vector = component.vector
        let end = CGPoint(x: origin.x + CGFloat(vector.x) * scale,
                          y: origin.y - CGFloat(vector.y) * scale)
        
        let color = colorForForce(component.type)
        
        var path = Path()
        path.move(to: origin)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), lineWidth: 3)
        
        drawArrowhead(context: context, from: origin, to: end, color: color)
    }
    
    private func drawArrowhead(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let headLength: CGFloat = 10
        let angle: CGFloat = .pi / 6
        let dX = to.x - from.x
        let dY = to.y - from.y
        let dir = atan2(dY, dX)
        
        var head = Path()
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(dir - angle), y: to.y - headLength * sin(dir - angle)))
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(dir + angle), y: to.y - headLength * sin(dir + angle)))
        context.stroke(head, with: .color(color), lineWidth: 3)
    }
    
    private func colorForForce(_ type: FBDState.ForceComponent.ForceType) -> Color {
        switch type {
        case .gravity: return .red
        case .normal: return .blue
        case .tension: return .green
        case .friction: return .orange
        case .drag: return .purple
        case .spring: return .pink
        case .applied: return .yellow
        case .net: return .white
        }
    }
}

struct ForceHitArea: View {
    let origin: CGPoint
    let component: FBDState.ForceComponent
    let cs: CoordinateSystem
    let action: () -> Void
    
    var body: some View {
        let scale: CGFloat = 8.0
        let end = CGPoint(x: origin.x + CGFloat(component.vector.x) * scale,
                          y: origin.y - CGFloat(component.vector.y) * scale)
        
        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 30, height: 30)
            .position(end)
            .onTapGesture(perform: action)
    }
}

struct ForceDetailView: View {
    let force: FBDState.ForceComponent
    let theme: ColorPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(force.label)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(theme.accent)
            
            Divider()
            
            let mag = sqrt(force.vector.x*force.vector.x + force.vector.y*force.vector.y)
            Text("Magnitude: \(String(format: "%.2f N", mag))")
                .font(.system(.subheadline, design: .monospaced))
            
            Text("Components: (\(String(format: "%.1f", force.vector.x)), \(String(format: "%.1f", force.vector.y))) N")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 180)
        .background(.ultraThinMaterial)
    }
}
