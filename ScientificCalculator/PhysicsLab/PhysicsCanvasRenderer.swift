// ScientificCalculator/UI/Components/PhysicsCanvasRenderer.swift
// Physics Canvas Rendering: Coordinate-Aware Drawing & Visualization

import SwiftUI

struct PhysicsCanvasRenderer {
    
    // MARK: - Drawing Utilities
    
    static func drawDotGrid(context: inout GraphicsContext, size: CGSize, theme: ColorPalette) {
        let dotSize: CGFloat = 1.0
        let spacing: CGFloat = 30.0
        let dotColor = theme.accent.opacity(0.15)
        
        for x in stride(from: 0, to: size.width, by: spacing) {
            for y in stride(from: 0, to: size.height, by: spacing) {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)), with: .color(dotColor))
            }
        }
    }

    static func drawAxes(context: inout GraphicsContext, cs: CoordinateSystem, theme: ColorPalette) {
        let axisColor = theme.accent.opacity(0.25)
        var path = Path()
        
        // Y-Axis
        path.move(to: cs.toScreen(WorldPoint(0, -1000)))
        path.addLine(to: cs.toScreen(WorldPoint(0, 1000)))
        
        // X-Axis
        path.move(to: cs.toScreen(WorldPoint(-1000, 0)))
        path.addLine(to: cs.toScreen(WorldPoint(1000, 0)))
        
        context.stroke(path, with: .color(axisColor), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
    }
    
    static func drawNeonTrail(context: inout GraphicsContext, points: [WorldPoint], cs: CoordinateSystem, color: Color) {
        guard points.count >= 2 else { return }
        var path = Path()
        path.move(to: cs.toScreen(points[0]))
        for i in 1..<points.count {
            path.addLine(to: cs.toScreen(points[i]))
        }
        
        // Outer glow
        context.addFilter(.blur(radius: 4))
        context.stroke(path, with: .color(color.opacity(0.4)), lineWidth: 4)
        
        // Inner core
        context.addFilter(.blur(radius: 0))
        context.stroke(path, with: .color(color), lineWidth: 1.5)
    }
    
    static func drawGlowingBody(context: inout GraphicsContext, at worldPos: WorldPoint, radius: CGFloat, color: Color, cs: CoordinateSystem, pulse: CGFloat = 1.0) {
        let screenPos = cs.toScreen(worldPos)
        let rect = CGRect(x: screenPos.x - radius, y: screenPos.y - radius, width: radius * 2, height: radius * 2)
        
        // Glow layer
        context.addFilter(.blur(radius: 4 * pulse))
        context.fill(Path(ellipseIn: rect.insetBy(dx: -2 * pulse, dy: -2 * pulse)), with: .color(color.opacity(0.3)))
        
        // Core
        context.addFilter(.blur(radius: 0))
        context.fill(Path(ellipseIn: rect), with: .color(color))
        
        // Highlights
        context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.6)), lineWidth: 1)
    }
    
    // MARK: - Scenario Renderers
    
    static func renderProjectile(context: inout GraphicsContext, frame: SimulationFrame, fullHistory: [SimulationFrame], cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        drawAxes(context: &context, cs: cs, theme: theme)
        
        let trailPoints = fullHistory.map { WorldPoint($0.state["x"] as? Double ?? 0, $0.state["y"] as? Double ?? 0) }
        drawNeonTrail(context: &context, points: trailPoints, cs: cs, color: theme.accent)
        
        let currentPos = WorldPoint(frame.state["x"] as? Double ?? 0, frame.state["y"] as? Double ?? 0)
        let pulse = 1.0 + (CGFloat(currentPos.y) / 50.0)
        drawGlowingBody(context: &context, at: currentPos, radius: 10, color: theme.accent, cs: cs, pulse: pulse)
        
        let gLeft = cs.toScreen(WorldPoint(-10, 0))
        let gRight = cs.toScreen(WorldPoint(1000, 0))
        var ground = Path(); ground.move(to: gLeft); ground.addLine(to: gRight)
        context.addFilter(.blur(radius: 3)); context.stroke(ground, with: .color(Color.cyan.opacity(0.3)), lineWidth: 3)
        context.addFilter(.blur(radius: 0)); context.stroke(ground, with: .color(Color.cyan), lineWidth: 1)
        
        for anno in frame.annotations {
            let sPos = cs.toScreen(anno.position)
            context.draw(Text(anno.label.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(theme.accent), at: CGPoint(x: sPos.x, y: sPos.y - 30))
        }
    }
    
    static func renderPendulum(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let pivot = WorldPoint(0, 0)
        let bob = WorldPoint(frame.state["x"] as? Double ?? 0, frame.state["y"] as? Double ?? 0)
        let sPivot = cs.toScreen(pivot); let sBob = cs.toScreen(bob)
        
        var stringPath = Path(); stringPath.move(to: sPivot); stringPath.addLine(to: sBob)
        context.stroke(stringPath, with: .color(theme.accent.opacity(0.5)), lineWidth: 1)
        context.fill(Path(ellipseIn: CGRect(x: sPivot.x - 3, y: sPivot.y - 3, width: 6, height: 6)), with: .color(.white))
        drawGlowingBody(context: &context, at: bob, radius: 12, color: theme.accent, cs: cs)
    }
    
    static func renderSpringMass(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let wall = WorldPoint(-3, 0); let mass = WorldPoint(frame.state["x"] as? Double ?? 0, 0)
        let sWall = cs.toScreen(wall); let sMass = cs.toScreen(mass)
        
        var spring = Path(); spring.move(to: sWall); let coils = 12; let seg = (sMass.x - sWall.x) / CGFloat(coils)
        for i in 0..<coils {
            let px = sWall.x + CGFloat(i) * seg + seg/2
            let py = sWall.y + (i % 2 == 0 ? -12 : 12)
            spring.addLine(to: CGPoint(x: px, y: py))
        }
        spring.addLine(to: sMass)
        context.stroke(spring, with: .color(theme.accent.opacity(0.8)), lineWidth: 2)
        
        let rect = CGRect(x: sMass.x - 18, y: sMass.y - 18, width: 36, height: 36)
        context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(theme.accent))
        context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(.white.opacity(0.4)), lineWidth: 1)
    }
    
    // MARK: - Waves
    
    static func renderStandingWave(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let points = frame.state["points"] as? [WorldPoint] ?? []
        guard !points.isEmpty else { return }
        
        var path = Path(); path.move(to: cs.toScreen(points[0]))
        for i in 1..<points.count { path.addLine(to: cs.toScreen(points[i])) }
        
        context.addFilter(.blur(radius: 2)); context.stroke(path, with: .color(theme.accent), lineWidth: 2)
        context.addFilter(.blur(radius: 0)); context.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 0.5)
    }
    
    static func renderWaveSuperposition(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let wave1 = frame.state["wave1"] as? [WorldPoint] ?? []
        let wave2 = frame.state["wave2"] as? [WorldPoint] ?? []
        let sum = frame.state["sum"] as? [WorldPoint] ?? []
        
        func drawWave(_ points: [WorldPoint], color: Color, width: CGFloat, dash: [CGFloat] = []) {
            guard !points.isEmpty else { return }
            var p = Path(); p.move(to: cs.toScreen(points[0]))
            for i in 1..<points.count { p.addLine(to: cs.toScreen(points[i])) }
            context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, dash: dash))
        }
        
        drawWave(wave1, color: .blue.opacity(0.4), width: 1, dash: [5, 5])
        drawWave(wave2, color: .red.opacity(0.4), width: 1, dash: [5, 5])
        drawWave(sum, color: theme.accent, width: 3)
    }

    // MARK: - Thermodynamics
    
    static func renderIdealGas(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let particles = frame.state["particles"] as? [WorldPoint] ?? []
        let velocities = frame.state["velocities"] as? [WorldPoint] ?? []
        
        let side: Double = 30.0
        let sRect = CGRect(x: cs.toScreen(WorldPoint(-side/2, side/2)).x,
                           y: cs.toScreen(WorldPoint(-side/2, side/2)).y,
                           width: cs.scale(side), height: cs.scale(side))
        context.stroke(Path(sRect), with: .color(.white.opacity(0.3)), lineWidth: 2)
        
        for (i, p) in particles.enumerated() {
            let sPos = cs.toScreen(p)
            let v = velocities[safe: i] ?? WorldPoint.zero
            let speed = sqrt(v.x*v.x + v.y*v.y)
            let color = Color(hue: 0.6 - min(speed/500, 0.6), saturation: 0.8, brightness: 1.0)
            context.fill(Path(ellipseIn: CGRect(x: sPos.x - 3, y: sPos.y - 3, width: 6, height: 6)), with: .color(color))
        }
    }

    static func renderDoppler(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let sourcePos = WorldPoint(frame.state["x"] as? Double ?? 0, 0)
        let waves = frame.state["waves"] as? [CGFloat] ?? []
        drawGlowingBody(context: &context, at: sourcePos, radius: 8, color: theme.accent, cs: cs)
        for radius in waves {
            let sPos = cs.toScreen(sourcePos); let r = cs.scale(Double(radius))
            context.stroke(Path(ellipseIn: CGRect(x: sPos.x - r, y: sPos.y - r, width: r * 2, height: r * 2)), with: .color(theme.accent.opacity(0.3)), lineWidth: 1)
        }
    }

    static func renderCarnot(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let p = frame.state["p"] as? Double ?? 0; let v = frame.state["v"] as? Double ?? 0
        let history = frame.state["history"] as? [WorldPoint] ?? []
        if history.count > 1 {
            var path = Path(); path.move(to: cs.toScreen(history[0])); for i in 1..<history.count { path.addLine(to: cs.toScreen(history[i])) }
            context.stroke(path, with: .color(theme.accent.opacity(0.5)), lineWidth: 2)
        }
        drawGlowingBody(context: &context, at: WorldPoint(v, p), radius: 6, color: .orange, cs: cs)
    }

    // MARK: - E&M
    
    static func renderElectricField(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let charges = frame.state["charges"] as? [WorldPoint] ?? []
        let fieldLines = frame.state["fieldLines"] as? [[WorldPoint]] ?? []
        for line in fieldLines {
            var path = Path(); guard !line.isEmpty else { continue }
            path.move(to: cs.toScreen(line[0])); for i in 1..<line.count { path.addLine(to: cs.toScreen(line[i])) }
            context.stroke(path, with: .color(theme.accent.opacity(0.3)), lineWidth: 1)
        }
        for (i, c) in charges.enumerated() {
            let val = frame.state["q\(i+1)"] as? Double ?? 0
            drawGlowingBody(context: &context, at: c, radius: 10, color: val > 0 ? .red : .blue, cs: cs)
        }
    }

    static func renderRCCircuit(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let v_c = frame.state["v_c"] as? Double ?? 0; let history = frame.state["history"] as? [WorldPoint] ?? []
        drawAxes(context: &context, cs: cs, theme: theme)
        if history.count > 1 {
            var path = Path(); path.move(to: cs.toScreen(history[0])); for i in 1..<history.count { path.addLine(to: cs.toScreen(history[i])) }
            context.stroke(path, with: .color(theme.accent), lineWidth: 2)
        }
        drawGlowingBody(context: &context, at: WorldPoint(frame.time, v_c), radius: 5, color: theme.accent, cs: cs)
    }

    // MARK: - Optics
    
    static func renderSnellLaw(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let ray1 = frame.state["incident"] as? [WorldPoint] ?? []
        let ray2 = frame.state["refracted"] as? [WorldPoint] ?? []
        let nTop = cs.toScreen(WorldPoint(0, 30)); let nBottom = cs.toScreen(WorldPoint(0, -30))
        context.stroke(Path { p in p.move(to: nTop); p.addLine(to: nBottom) }, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        let iLeft = cs.toScreen(WorldPoint(-50, 0)); let iRight = cs.toScreen(WorldPoint(50, 0))
        context.stroke(Path { p in p.move(to: iLeft); p.addLine(to: iRight) }, with: .color(.blue.opacity(0.3)), lineWidth: 2)
        if ray1.count == 2 {
            var p = Path(); p.move(to: cs.toScreen(ray1[0])); p.addLine(to: cs.toScreen(ray1[1]))
            context.stroke(p, with: .color(.red), lineWidth: 2)
        }
        if ray2.count == 2 {
            var p = Path(); p.move(to: cs.toScreen(ray2[0])); p.addLine(to: cs.toScreen(ray2[1]))
            context.stroke(p, with: .color(.cyan), lineWidth: 2)
        }
    }

    static func renderLens(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let rays = frame.state["rays"] as? [[WorldPoint]] ?? []
        let objPos = WorldPoint(frame.state["obj_x"] as? Double ?? -10, frame.state["obj_y"] as? Double ?? 5)
        let imgPos = WorldPoint(frame.state["img_x"] as? Double ?? 10, frame.state["img_y"] as? Double ?? -5)
        drawAxes(context: &context, cs: cs, theme: theme)
        let top = cs.toScreen(WorldPoint(0, 20)); let bottom = cs.toScreen(WorldPoint(0, -20))
        context.stroke(Path { p in p.move(to: top); p.addLine(to: bottom) }, with: .color(.cyan.opacity(0.4)), lineWidth: 4)
        for ray in rays {
            guard ray.count >= 2 else { continue }
            var p = Path(); p.move(to: cs.toScreen(ray[0])); for i in 1..<ray.count { p.addLine(to: cs.toScreen(ray[i])) }
            context.stroke(p, with: .color(.yellow.opacity(0.6)), lineWidth: 1)
        }
        drawGlowingBody(context: &context, at: objPos, radius: 4, color: .green, cs: cs)
        drawGlowingBody(context: &context, at: imgPos, radius: 4, color: .red, cs: cs)
    }

    // MARK: - Modern & Fluids
    
    static func renderRadioactiveDecay(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let atoms = frame.state["atoms"] as? [WorldPoint] ?? []
        let decayed = frame.state["decayed"] as? [Bool] ?? []
        for (i, a) in atoms.enumerated() {
            let isDecayed = decayed[safe: i] ?? false; let sPos = cs.toScreen(a)
            context.fill(Path(ellipseIn: CGRect(x: sPos.x - 2, y: sPos.y - 2, width: 4, height: 4)), with: .color(isDecayed ? .gray.opacity(0.3) : theme.accent))
        }
    }

    static func renderBohrModel(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        let center = WorldPoint(0, 0); let sCenter = cs.toScreen(center)
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        drawGlowingBody(context: &context, at: center, radius: 10, color: .red, cs: cs)
        let orbits = [5.0, 10.0, 15.0, 20.0]; for r in orbits {
            let sr = cs.scale(r); context.stroke(Path(ellipseIn: CGRect(x: sCenter.x - sr, y: sCenter.y - sr, width: sr * 2, height: sr * 2)), with: .color(.white.opacity(0.1)), lineWidth: 1)
        }
        if let electron = frame.state["electron"] as? WorldPoint { drawGlowingBody(context: &context, at: electron, radius: 4, color: .blue, cs: cs) }
    }
    
    static func renderBuoyancy(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let sWaterY = cs.toScreen(WorldPoint(0, 0.0)).y
        context.fill(Path(CGRect(x: 0, y: sWaterY, width: cs.canvasSize.width, height: cs.canvasSize.height - sWaterY)), with: .color(.blue.opacity(0.2)))
        let body = WorldPoint(0, frame.state["y"] as? Double ?? 0)
        drawGlowingBody(context: &context, at: body, radius: 20, color: theme.accent, cs: cs)
    }
    
    static func renderTerminalVelocity(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let body = WorldPoint(0, frame.state["y"] as? Double ?? 100)
        if let v = frame.state["v"] as? Double, abs(v) > 5 {
            let sPos = cs.toScreen(body); for _ in 0..<5 {
                let offX = CGFloat.random(in: -20...20); let offY = CGFloat.random(in: 10...40)
                context.stroke(Path { p in p.move(to: sPos); p.addLine(to: CGPoint(x: sPos.x + offX, y: sPos.y - offY)) }, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }
        }
        drawGlowingBody(context: &context, at: body, radius: 15, color: theme.accent, cs: cs)
    }
    
    static func renderGravityField(context: inout GraphicsContext, frame: SimulationFrame, cs: CoordinateSystem, theme: ColorPalette) {
        drawDotGrid(context: &context, size: cs.canvasSize, theme: theme)
        let masses = frame.state["masses"] as? [WorldPoint] ?? []
        for m in masses { drawGlowingBody(context: &context, at: m, radius: 12, color: .white, cs: cs) }
        let gridPoints = frame.state["grid"] as? [WorldPoint] ?? []; let field = frame.state["field"] as? [WorldPoint] ?? []
        for (i, p) in gridPoints.enumerated() {
            let sStart = cs.toScreen(p); let vec = field[safe: i] ?? WorldPoint.zero
            let sEnd = CGPoint(x: sStart.x + CGFloat(vec.x * 2), y: sStart.y - CGFloat(vec.y * 2))
            context.stroke(Path { path in path.move(to: sStart); path.addLine(to: sEnd) }, with: .color(theme.accent.opacity(0.3)), lineWidth: 1)
        }
    }
}
