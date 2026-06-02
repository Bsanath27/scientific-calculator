// ScientificCalculator/PhysicsEngine/PhysicsCoordinateSystem.swift
// The "Anti-Gravity Root Fix": Single source of truth for all transformations.

import SwiftUI

/// A point in the physical world (physics units).
struct WorldPoint: Hashable, Codable {
    let x: Double
    let y: Double
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
    
    static var zero: WorldPoint { WorldPoint(0, 0) }
}

/// Defines the coordinate system for a physics simulation.
/// Maps World Coordinates (physics units) to Screen Coordinates (points).
struct CoordinateSystem: Hashable {
    let worldBounds: CGRect
    let canvasSize: CGSize
    let userZoom: Double
    let userOffset: CGSize
    let yAxisInverted: Bool
    
    /// Converts a point from World Coordinates to Screen Coordinates.
    func toScreen(_ worldPoint: WorldPoint) -> CGPoint {
        // 1. Normalize world point to [0, 1] within worldBounds
        let normX = (worldPoint.x - worldBounds.minX) / worldBounds.width
        let normY = (worldPoint.y - worldBounds.minY) / worldBounds.height
        
        // 2. Map to Canvas space with base scaling
        let baseX = CGFloat(normX) * canvasSize.width
        let baseY = CGFloat(normY) * canvasSize.height
        
        // 3. Apply User Zoom relative to canvas center
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        
        var screenX = (baseX - centerX) * CGFloat(userZoom) + centerX
        var screenY = (baseY - centerY) * CGFloat(userZoom) + centerY
        
        // 4. Apply User Offset
        screenX += userOffset.width
        screenY += userOffset.height
        
        // 5. Apply Y-Axis Inversion
        if yAxisInverted {
            screenY = canvasSize.height - screenY
        }
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    /// Converts a point from Screen Coordinates to World Coordinates.
    func toWorld(_ screenPoint: CGPoint) -> WorldPoint {
        var sy = screenPoint.y
        if yAxisInverted {
            sy = canvasSize.height - sy
        }
        
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        
        let unpannedX = Double(screenPoint.x - userOffset.width)
        let unpannedY = Double(sy - userOffset.height)
        
        let unzoomedX = (unpannedX - Double(centerX)) / userZoom + Double(centerX)
        let unzoomedY = (unpannedY - Double(centerY)) / userZoom + Double(centerY)
        
        let worldX = (unzoomedX / Double(canvasSize.width)) * Double(worldBounds.width) + Double(worldBounds.minX)
        let worldY = (unzoomedY / Double(canvasSize.height)) * Double(worldBounds.height) + Double(worldBounds.minY)
        
        return WorldPoint(worldX, worldY)
    }
    
    /// Scales a distance from World space to Screen space (ignoring offset).
    func scale(_ distance: Double) -> Double {
        return distance * (Double(canvasSize.width) / Double(worldBounds.width)) * userZoom
    }
}

extension CoordinateSystem {
    /// Factory method to create an appropriate coordinate system based on scenario.
    static func make(for scenarioId: String, canvasSize: CGSize, userZoom: Double = 1.0, userOffset: CGSize = .zero) -> CoordinateSystem {
        var worldBounds: CGRect
        var yAxisInverted = true
        
        switch scenarioId {
        case "projectile":
            worldBounds = CGRect(x: -5, y: -5, width: 110, height: 110)
        case "pendulum":
            worldBounds = CGRect(x: -2.5, y: -4, width: 5, height: 5)
        case "springMass":
            worldBounds = CGRect(x: -2, y: -2, width: 4, height: 4)
        case "standingWave":
            worldBounds = CGRect(x: -0.1, y: -0.5, width: 1.2, height: 1.0)
        case "idealGas":
            worldBounds = CGRect(x: -16, y: -16, width: 32, height: 32)
        case "electricField":
            worldBounds = CGRect(x: -25, y: -25, width: 50, height: 50)
        case "rcCircuit":
            worldBounds = CGRect(x: -1, y: -1, width: 12, height: 12)
        case "snellLaw", "lens":
            worldBounds = CGRect(x: -25, y: -25, width: 50, height: 50)
        case "radioactiveDecay":
            worldBounds = CGRect(x: -20, y: -20, width: 40, height: 40)
        case "bohrModel":
            worldBounds = CGRect(x: -30, y: -30, width: 60, height: 60)
        case "archimedes":
            worldBounds = CGRect(x: -2, y: -5, width: 4, height: 8)
        default:
            worldBounds = CGRect(x: -10, y: -10, width: 20, height: 20)
        }
        
        return CoordinateSystem(
            worldBounds: worldBounds,
            canvasSize: canvasSize,
            userZoom: userZoom,
            userOffset: userOffset,
            yAxisInverted: yAxisInverted
        )
    }
}
