// ScientificCalculator/UI/Components/PhysicsFBDView.swift
// Physics Free Body Diagram: Vector Overlays and Force Analytics

import SwiftUI

struct PhysicsFBDView: View {
    let frame: SimulationFrame
    let cs: CoordinateSystem
    let theme: ColorPalette
    
    var body: some View {
        Canvas { context, size in
            guard let fbd = frame.fbd else { return }
            
            // Determine origin for FBD vectors
            // Most scenarios use 'x', 'y' for position. Some use 'theta', etc.
            let origin = getObjectPosition()
            let sOrigin = cs.toScreen(origin)
            
            for component in fbd.components {
                drawVector(context: context, from: sOrigin, component: component)
            }
        }
    }
    
    private func getObjectPosition() -> WorldPoint {
        if let x = frame.state["x"] as? Double, let y = frame.state["y"] as? Double {
            return WorldPoint(x, y)
        }
        // Fallback for rotation-based scenarios (e.g. pendulum bob)
        if let theta = frame.state["theta"] as? Double, let L = frame.state["L"] as? Double {
            return WorldPoint(L * sin(theta), -L * cos(theta))
        }
        return WorldPoint(0, 0)
    }
    
    private func drawVector(context: GraphicsContext, from origin: CGPoint, component: FBDState.ForceComponent) {
        let scale: CGFloat = 5.0 // 1 Newton = 5 Screen Points
        let vector = component.vector
        let end = CGPoint(x: origin.x + CGFloat(vector.x) * scale,
                          y: origin.y - CGFloat(vector.y) * scale) // Screen Y is inverted
        
        let color = colorForForce(component.type)
        
        var path = Path()
        path.move(to: origin)
        path.addLine(to: end)
        
        context.stroke(path, with: .color(color), lineWidth: 2)
        
        // Draw Arrowhead
        drawArrowhead(context: context, from: origin, to: end, color: color)
        
        // Label
        let mid = CGPoint(x: (origin.x + end.x) / 2 + 10, y: (origin.y + end.y) / 2 - 10)
        context.draw(Text(component.label).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(color), at: mid)
    }
    
    private func drawArrowhead(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let headLength: CGFloat = 8
        let angle: CGFloat = .pi / 6
        
        let dX = to.x - from.x
        let dY = to.y - from.y
        let dir = atan2(dY, dX)
        
        var head = Path()
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(dir - angle), y: to.y - headLength * sin(dir - angle)))
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(dir + angle), y: to.y - headLength * sin(dir + angle)))
        
        context.stroke(head, with: .color(color), lineWidth: 2)
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
