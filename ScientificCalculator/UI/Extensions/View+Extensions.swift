// UI/Extensions/View+Extensions.swift
// Scientific Calculator - View Extensions

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension View {
    /// Applies a corner radius to specific corners of a view
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// A shape that applies corner radius to specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        #if canImport(UIKit)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners.uiRectCorner, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
        #else
        // Fallback for non-UIKit platforms (macOS)
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height
        let r = radius
        
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        
        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: w, y: 0))
        }
        
        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: w, y: h - r))
            path.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: w, y: h))
        }
        
        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: r, y: h))
            path.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: h))
        }
        
        if corners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        return path
        #endif
    }
}

/// Set of corners to apply radius to
struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
    #if canImport(UIKit)
    var uiRectCorner: UIRectCorner {
        var corners = UIRectCorner()
        if contains(.topLeft) { corners.insert(.topLeft) }
        if contains(.topRight) { corners.insert(.topRight) }
        if contains(.bottomLeft) { corners.insert(.bottomLeft) }
        if contains(.bottomRight) { corners.insert(.bottomRight) }
        return corners
    }
    #endif
}
