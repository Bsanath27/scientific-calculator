// UI/Extensions/DeviceLayout.swift
// Scientific Calculator - Device Layout Helpers

import SwiftUI

/// Centralized layout helper for consistent device-adaptive UI
struct DeviceLayout {
    
    // MARK: - Breakpoints
    
    /// All iPhones in portrait (< 600pt)
    static func isCompact(width: CGFloat) -> Bool {
        width < 600
    }
    
    /// iPad Mini, iPad Air, iPad Pro 11" (600–1023pt)
    static func isRegular(width: CGFloat) -> Bool {
        width >= 600 && width < 1024
    }
    
    /// iPad Pro 12.9" and larger (≥ 1024pt)
    static func isWide(width: CGFloat) -> Bool {
        width >= 1024
    }
    
    // MARK: - Font Scaling
    
    /// Dynamic expression font size based on screen width
    static func expressionFontSize(for width: CGFloat) -> CGFloat {
        if isCompact(width: width) {
            return max(24, min(32, width * 0.075))
        } else if isRegular(width: width) {
            return 38
        } else {
            return 48
        }
    }
    
    /// Dynamic placeholder font size
    static func placeholderFontSize(for width: CGFloat) -> CGFloat {
        expressionFontSize(for: width)
    }
    
    // MARK: - Button Sizing
    
    /// Calculate optimal button height for keypad given available height and row count
    static func keypadButtonHeight(availableHeight: CGFloat, rows: Int, spacing: CGFloat = 12) -> CGFloat {
        let totalSpacing = spacing * CGFloat(rows - 1)
        let paddingAllowance: CGFloat = 32 // top + bottom padding
        let available = availableHeight - totalSpacing - paddingAllowance
        return max(36, available / CGFloat(rows))
    }
    
    // MARK: - Scientific Keypad
    
    /// Width for the scientific keypad side panel on iPad
    static func scientificKeypadWidth(for screenWidth: CGFloat) -> CGFloat {
        if isWide(width: screenWidth) {
            return min(360, screenWidth * 0.35)
        } else if isRegular(width: screenWidth) {
            return min(300, screenWidth * 0.4)
        } else {
            return min(320, screenWidth * 0.85)
        }
    }
    
    // MARK: - Toolbar
    
    /// Max width for the toolbar scroll area
    static func toolbarWidth(for screenWidth: CGFloat) -> CGFloat {
        if isCompact(width: screenWidth) {
            return max(180, screenWidth - 200)
        } else {
            return .infinity
        }
    }
    
    // MARK: - Dashboard
    
    /// Whether dashboard cards should stack vertically
    static func dashboardShouldStack(width: CGFloat) -> Bool {
        isCompact(width: width)
    }
    
    /// Sidebar card width on iPad dashboard
    static func dashboardSidebarWidth(for screenWidth: CGFloat) -> CGFloat {
        if isWide(width: screenWidth) {
            return 300
        } else {
            return min(250, screenWidth * 0.35)
        }
    }
    
    // MARK: - iOS 18+ Floating Tab Bar Fixes
    
    /// Systemic bottom padding to clear the floating tab bar on iPhone
    static func tabBarPadding(width: CGFloat) -> CGFloat {
        return isCompact(width: width) ? 80 : 0
    }
    
    /// Offset for floating action buttons (like drawer toggle or playback controls)
    static func floatingButtonOffset(width: CGFloat) -> CGFloat {
        return isCompact(width: width) ? 90 : 8
    }
}
