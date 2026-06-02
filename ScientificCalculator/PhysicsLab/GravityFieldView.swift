// ScientificCalculator/UI/Components/GravityFieldView.swift
// Interactive Gravity Field: Dynamic Mass Placement and Particle Release

import SwiftUI

struct GravityFieldView: View {
    @ObservedObject var viewModel: PhysicsViewModel
    let frame: SimulationFrame
    let cs: CoordinateSystem
    let theme: ColorPalette
    
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    
    var body: some View {
        ZStack {
            // Field Visualization
            Canvas { context, size in
                let grid = frame.state["grid"] as? [WorldPoint] ?? []
                let field = frame.state["field"] as? [WorldPoint] ?? []
                
                for (i, p) in grid.enumerated() {
                    guard i < field.count else { break }
                    let sStart = cs.toScreen(p)
                    let vec = field[i]
                    let mag = sqrt(vec.x*vec.x + vec.y*vec.y)
                    let scale: CGFloat = min(25, CGFloat(mag * 5e11))
                    let sEnd = CGPoint(x: sStart.x + CGFloat(vec.x) * scale,
                                     y: sStart.y - CGFloat(vec.y) * scale)
                    
                    let opacity = min(0.7, Double(mag * 2e11))
                    let color = theme.accent.opacity(opacity)
                    
                    var path = Path()
                    path.move(to: sStart)
                    path.addLine(to: sEnd)
                    context.stroke(path, with: .color(color), lineWidth: 1)
                }
                
                // Draw attractor bodies
                let masses = frame.state["masses"] as? [(pos: WorldPoint, m: Double)] ?? []
                for body in masses {
                    drawAttractor(context: &context, at: cs.toScreen(body.pos), color: .white)
                }
                
                // Draw test particles
                let particles = frame.state["testParticles"] as? [WorldPoint] ?? []
                for p in particles {
                    context.fill(Path(ellipseIn: CGRect(origin: cs.toScreen(p), size: CGSize(width: 4, height: 4)).offsetBy(dx: -2, dy: -2)), with: .color(theme.accent))
                }
            }
            
            // Interaction Layer
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let worldPos = cs.toWorld(location)
                    viewModel.addGravityMass(at: worldPos, mass: 1e11) // Default heavy mass
                }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if dragStart == nil { dragStart = value.startLocation }
                            dragCurrent = value.location
                        }
                        .onEnded { value in
                            if let start = dragStart {
                                let startPos = cs.toWorld(start)
                                let endPos = cs.toWorld(value.location)
                                let velocity = WorldPoint(endPos.x - startPos.x, endPos.y - startPos.y)
                                viewModel.releaseTestParticle(at: startPos, velocity: velocity)
                            }
                            dragStart = nil
                            dragCurrent = nil
                        }
                )
            
            // Drag Visualizer (Arrow for particle release)
            if let start = dragStart, let current = dragCurrent {
                Path { path in
                    path.move(to: start)
                    path.addLine(to: current)
                }
                .stroke(theme.accent, lineWidth: 2)
                .overlay(
                    Circle().fill(theme.accent).frame(width: 6, height: 6).position(start)
                )
            }
        }
    }
    
    private func drawAttractor(context: inout GraphicsContext, at pos: CGPoint, color: Color) {
        let rect = CGRect(x: pos.x - 8, y: pos.y - 8, width: 16, height: 16)
        context.addFilter(.blur(radius: 4))
        context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(color.opacity(0.4)))
        context.addFilter(.blur(radius: 0))
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }
}
