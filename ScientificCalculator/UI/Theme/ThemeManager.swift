// UI/Theme/ThemeManager.swift
// Scientific Calculator - Theme Management (Nord Palette)

import SwiftUI

/// Semantic color palette for the application
struct ColorPalette {
    let background: Color
    let displayBackground: Color
    let surface: Color
    let buttonNumber: Color
    let buttonOperator: Color
    let buttonScientific: Color
    let buttonAction: Color
    let buttonDestructive: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    
    // Additional UI elements
    let divider: Color
    let shadow: Color
}

/// Nord Color System Definitions
private struct Nord {
    // Polar Night (Dark)
    static let nord0 = Color(hex: 0x2E3440)
    static let nord1 = Color(hex: 0x3B4252)
    static let nord2 = Color(hex: 0x434C5E)
    static let nord3 = Color(hex: 0x4C566A)
    
    // Snow Storm (Light)
    static let nord4 = Color(hex: 0xD8DEE9)
    static let nord5 = Color(hex: 0xE5E9F0)
    static let nord6 = Color(hex: 0xECEFF4)
    
    // Frost (Accents)
    static let nord7 = Color(hex: 0x8FBCBB)
    static let nord8 = Color(hex: 0x88C0D0)
    static let nord9 = Color(hex: 0x81A1C1)
    static let nord10 = Color(hex: 0x5E81AC)
    
    // Aurora (Semantic)
    static let nord11 = Color(hex: 0xBF616A) // Red (Destructive)
    static let nord12 = Color(hex: 0xD08770) // Orange
    static let nord13 = Color(hex: 0xEBCB8B) // Yellow
    static let nord14 = Color(hex: 0xA3BE8C) // Green (Success/Action)
    static let nord15 = Color(hex: 0xB48EAD) // Purple
}

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true
    
    var current: ColorPalette {
        isDarkMode ? darkPalette : lightPalette
    }
    
    private let darkPalette = ColorPalette(
        background: Nord.nord0,
        displayBackground: Nord.nord1,
        surface: Nord.nord1,
        buttonNumber: Nord.nord3,
        buttonOperator: Nord.nord9,
        buttonScientific: Nord.nord2,
        buttonAction: Nord.nord14,
        buttonDestructive: Nord.nord11,
        textPrimary: Nord.nord6,
        textSecondary: Nord.nord4,
        accent: Nord.nord8,
        divider: Nord.nord2,
        shadow: Color.black.opacity(0.3)
    )
    
    private let lightPalette = ColorPalette(
        background: Nord.nord6,
        displayBackground: Nord.nord5,
        surface: Nord.nord6,
        buttonNumber: Nord.nord4,     // Slightly darker than bg for contrast
        buttonOperator: Nord.nord9,
        buttonScientific: Nord.nord5, // Subtle variation
        buttonAction: Nord.nord14,
        buttonDestructive: Nord.nord11,
        textPrimary: Nord.nord0,
        textSecondary: Nord.nord2,
        accent: Nord.nord10,
        divider: Nord.nord4,
        shadow: Color.black.opacity(0.1)
    )
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
