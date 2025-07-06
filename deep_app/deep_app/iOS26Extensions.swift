//
//  iOS26Extensions.swift
//  deep_app
//
//  iOS 26 Liquid Glass UI Extensions
//

import SwiftUI

// MARK: - iOS 26 Liquid Glass UI Extensions
extension View {
    /// Conditionally applies iOS 26 tab bar styling
    @ViewBuilder
    func conditionalTabBarStyle() -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Liquid Glass tab bar with glass effect
            self.background(.clear)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarColorScheme(.none, for: .tabBar) // Let glass adapt to content
                .onAppear {
                    // Apply glass effect to tab bar if possible
                    let appearance = UITabBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                    
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
        } else {
            // Pre-iOS 26: Ultra thin material
            self.background(.ultraThinMaterial)
        }
    }
    
    /// iOS 26 glass card style for content cards
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .background(Color.white.opacity(0.01), in: RoundedRectangle(cornerRadius: cornerRadius))
                )
                .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
    
    /// iOS 26 glass input field style
    @ViewBuilder
    func glassInputStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12)) // More transparent
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        } else {
            self
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)) // More transparent fallback
        }
    }
    
    /// iOS 26 glass button style
    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if prominent {
                            RoundedRectangle(cornerRadius: 12).fill(.tint)
                        } else {
                            RoundedRectangle(cornerRadius: 12).fill(.thinMaterial)
                        }
                    }
                )
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(prominent ? .white : .primary)
        } else {
            self
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if prominent {
                            RoundedRectangle(cornerRadius: 12).fill(.tint)
                        } else {
                            RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
                        }
                    }
                )
                .foregroundStyle(prominent ? .white : .primary)
        }
    }
    
    /// iOS 26 glass form style
    @ViewBuilder
    func conditionalFormStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
        } else {
            self
        }
    }
    
    /// Conditionally applies glass effect for iOS 26+, falls back to ultra thin material for older versions
    @ViewBuilder
    func conditionalGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
    
    /// Conditionally applies glass background with color and opacity
    @ViewBuilder
    func conditionalGlassBackground<S: Shape>(_ color: Color, opacity: Double, in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Much more transparent for stronger glass effect
            self.background(shape.fill(color.opacity(opacity * 0.3))) // Even more transparent
        } else {
            // Pre-iOS 26: More opaque for better visibility without glass effect  
            self.background(shape.fill(color.opacity(opacity * 2)))
        }
    }
    
    /// Ultra-transparent glass effect for maximum see-through
    @ViewBuilder
    func ultraGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(.ultraThinMaterial, in: shape)
                .background(Color.white.opacity(0.02), in: shape) // Tiny white tint
                .glassEffect(in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Safe Glass Effect Modifier
@available(iOS 26.0, *)
struct SafeGlassEffectModifier<S: Shape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        content.glassEffect(in: shape)
    }
}

extension View {
    @ViewBuilder
    func safeGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(SafeGlassEffectModifier(shape: shape))
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}