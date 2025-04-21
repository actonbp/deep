import SwiftUI

// Define theme colors
extension Color {
    static let theme = ColorTheme()
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

// Define the structure for a To-Do item
// ... rest of ContentView.swift ... 

let sciFiFont = "Orbitron" // Use this name 