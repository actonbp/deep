//
//  iOS26TrueGlassExtensions.swift
//  deep_app
//
//  Experimental "True Glass" effects for iOS 26
//

import SwiftUI

@available(iOS 26.0, *)
extension View {
    /// Experimental true glass effect with maximum transparency
    func trueGlass(in shape: some Shape = Rectangle()) -> some View {
        self
            .background(
                ZStack {
                    // Base layer - almost invisible
                    shape
                        .fill(.ultraThinMaterial)
                        .opacity(0.3) // Aggressive opacity reduction
                    
                    // Glass refraction effect
                    shape
                        .fill(.clear)
                        .glassEffect(in: shape)
                    
                    // Remove any default backgrounds
                    shape
                        .fill(Color.clear)
                }
            )
            .background(Color.clear) // Ensure no hidden backgrounds
    }
    
    /// Ultra-minimal glass for floating elements
    func floatingGlass() -> some View {
        self
            .background(.clear)
            .overlay(
                // Only the glass effect, no material
                Rectangle()
                    .fill(.clear)
                    .glassEffect(in: Rectangle())
            )
    }
    
    /// Remove all system backgrounds
    func clearSystemBackgrounds() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listRowBackground(Color.clear)
    }
}

// Custom material that's more transparent than system materials
@available(iOS 26.0, *)
struct UltraTransparentMaterial: View {
    var body: some View {
        ZStack {
            // Base blur effect
            Color.clear
                .background(
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                        .opacity(0.2) // Very low opacity
                )
            
            // Glass overlay
            Rectangle()
                .fill(.clear)
                .glassEffect(in: Rectangle())
        }
    }
}

// Visual effect blur wrapper for more control
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}