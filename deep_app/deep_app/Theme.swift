import SwiftUI

// MARK: - Color System

// Define theme colors
extension Color {
    static let theme = ColorTheme()
    
    // Design System Colors - Xcode automatically generates these from Assets.xcassets
    // Access them as: Color.indigo500, Color.gray50, etc.
}

struct ColorTheme {
    let background = Color("BackgroundColor") // Will be beige/parchment
    let text = Color("TextColor")           // Will be dark brown/black
    let titleText = Color("TitleTextColor")     // Title text (intended to be white/light)
    let accent = Color("AccentColor")         // Will be gold/orange
    let secondaryText = Color("SecondaryTextColor") // Muted gray/brown
    let done = Color("DoneColor")             // Muted green
    let delete = Color("DeleteColor")           // Muted red
}

// MARK: - Typography System

extension Font {
    // Primary font scales - only 2 as per design spec
    static let appTitle = Font.system(.title3, design: .rounded).bold()
    static let appBody = Font.system(.body, design: .rounded)
    
    // Additional utility scales
    static let appCaption = Font.system(.caption, design: .rounded)
    static let appCaption2 = Font.system(.caption2, design: .rounded)
    
    // Legacy support
    static let sciFiTitle = Font.custom("Orbitron", size: 22).weight(.bold)
    static let sciFiBody = Font.custom("Orbitron", size: 16)
}

// MARK: - Spacing System

enum AppSpacing {
    static let xxSmall: CGFloat = 4   // 0.5x base
    static let xSmall: CGFloat = 6    // 0.75x base
    static let small: CGFloat = 8     // 1x base unit
    static let medium: CGFloat = 16   // 2x base
    static let large: CGFloat = 24    // 3x base
    static let xLarge: CGFloat = 32   // 4x base
    static let xxLarge: CGFloat = 48  // 6x base - min gap for roadmap nodes
}

// MARK: - Animation System

extension Animation {
    // Standard animations as per design spec
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeOut(duration: 0.15)
}

// MARK: - Visual Effects

struct AppEffects {
    // Standard shadows
    static let smallShadow = Color.black.opacity(0.1)
    static let mediumShadow = Color.black.opacity(0.15)
    
    // Corner radii
    static let smallRadius: CGFloat = 6
    static let mediumRadius: CGFloat = 8
    static let largeRadius: CGFloat = 12
}

// MARK: - Layout Constants

struct AppLayout {
    // Minimum tap targets for ADHD-friendly interaction
    static let minTapTarget: CGFloat = 44
    static let checkboxSize: CGFloat = 28
    
    // List item spacing
    static let listItemSpacing: CGFloat = 12
    static let listItemInset: CGFloat = 39
}

// Legacy font name for compatibility
let sciFiFont = "Orbitron" // Use this name 