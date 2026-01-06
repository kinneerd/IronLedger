//
//  Theme.swift
//  GymTracker
//
//  Dark mode first, high contrast gym-friendly colors
//

import SwiftUI

extension Color {
    // Primary background - deep black
    static let gymBackground = Color(red: 0.06, green: 0.06, blue: 0.08)
    
    // Card/surface background - slightly lighter
    static let gymSurface = Color(red: 0.11, green: 0.11, blue: 0.14)
    
    // Elevated surface
    static let gymElevated = Color(red: 0.16, green: 0.16, blue: 0.19)
    
    // Accent - vibrant orange for CTAs and highlights
    static let gymAccent = Color(red: 1.0, green: 0.45, blue: 0.15)
    
    // Secondary accent - cooler tone
    static let gymSecondary = Color(red: 0.35, green: 0.55, blue: 0.95)
    
    // Success/PR color
    static let gymSuccess = Color(red: 0.3, green: 0.85, blue: 0.45)
    
    // Warning
    static let gymWarning = Color(red: 1.0, green: 0.75, blue: 0.25)
    
    // Text colors
    static let gymTextPrimary = Color.white
    static let gymTextSecondary = Color(white: 0.6)
    static let gymTextTertiary = Color(white: 0.4)
    
    // Set type colors
    static let warmupColor = Color(red: 0.5, green: 0.5, blue: 0.55)
    static let workingColor = Color.gymAccent
    
    // Category colors
    static let mainLiftColor = Color.gymAccent
    static let compoundColor = Color.gymSecondary
    static let accessoryColor = Color(red: 0.6, green: 0.4, blue: 0.8)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gymSurface)
            .cornerRadius(16)
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gymElevated)
            .cornerRadius(12)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func elevatedCardStyle() -> some View {
        modifier(ElevatedCardStyle())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.gymAccent : Color.gymTextTertiary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.gymAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gymAccent.opacity(0.15))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactButtonStyle: ButtonStyle {
    var color: Color = .gymAccent
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.opacity(0.15))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Typography

extension Font {
    static let gymTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let gymHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let gymSubheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    static let gymBody = Font.system(size: 15, weight: .regular, design: .default)
    static let gymCaption = Font.system(size: 13, weight: .medium, design: .default)
    static let gymLargeNumber = Font.system(size: 48, weight: .bold, design: .rounded)
    static let gymMediumNumber = Font.system(size: 32, weight: .bold, design: .rounded)
}
