//
//  GlassComponents.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Design System"
//  Reference: RESOURCES.md - Section 2 (Liquid Glass Design iOS 26)
//
//  IMPORTANT: Glass effects should ONLY be applied to:
//  - Navigation elements
//  - Control elements (buttons, toggles)
//  - Toolbars and tab bars
//
//  NEVER apply glass effects to:
//  - Content areas (lists, text, media)
//  - Backgrounds
//

import SwiftUI

// MARK: - Glass Button Style

/// A button style that applies Liquid Glass effect on iOS 26+
/// Falls back to a standard style on older versions
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    /// Whether this is a primary (prominent) button
    var isPrimary: Bool = false

    /// Optional tint color for the glass effect
    var tintColor: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(isPrimary ? .white : theme.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundView(isPressed: configuration.isPressed))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        if #available(iOS 26.0, *) {
            // Liquid Glass effect for iOS 26+
            glassBackground(isPressed: isPressed)
        } else {
            // Fallback for older iOS versions
            fallbackBackground(isPressed: isPressed)
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassBackground(isPressed: Bool) -> some View {
        if isPrimary {
            RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius)
                .fill(tintColor ?? theme.accentBlue)
                .glassEffect(.regular.interactive())
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius)
                .fill(.clear)
                .glassEffect(.regular.interactive())
        }
    }

    @ViewBuilder
    private func fallbackBackground(isPressed: Bool) -> some View {
        if isPrimary {
            RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius)
                .fill(tintColor ?? theme.accentBlue)
                .opacity(isPressed ? 0.8 : 1.0)
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius)
                .fill(theme.surface)
                .opacity(isPressed ? 0.8 : 1.0)
        }
    }
}

// MARK: - Glass Card Modifier

/// A view modifier that applies a glass card effect
struct GlassCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    /// Corner radius for the card
    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius

    /// Optional tint color
    var tintColor: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.clear)
                        .glassEffect(glassStyle)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.surface)
                )
        }
    }

    @available(iOS 26.0, *)
    private var glassStyle: some GlassEffectStyle {
        if let tint = tintColor {
            return .regular.tint(tint)
        }
        return .regular
    }
}

// MARK: - Glass Control Modifier

/// A view modifier for interactive glass controls (buttons, toggles)
struct GlassControlModifier: ViewModifier {
    @Environment(\.theme) private var theme

    /// Size of the control
    var size: CGSize = CGSize(width: 44, height: 44)

    /// Corner radius (defaults to circular for square sizes)
    var cornerRadius: CGFloat?

    /// Whether the control is currently active/selected
    var isActive: Bool = false

    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? (size.width == size.height ? size.width / 2 : 12)
    }

    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .background(backgroundView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: effectiveCornerRadius)
                .fill(.clear)
                .glassEffect(.regular.interactive())
        } else {
            RoundedRectangle(cornerRadius: effectiveCornerRadius)
                .fill(isActive ? theme.accentBlue.opacity(0.3) : theme.surface)
        }
    }
}

// MARK: - Glass Navigation Bar Modifier

/// Applies glass effect to navigation bar style elements
struct GlassNavigationModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
                .glassEffect(.regular)
        } else {
            content
                .toolbarBackground(theme.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies glass card styling to the view
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the card
    ///   - tintColor: Optional tint color for the glass
    /// - Returns: View with glass card effect
    func glassCard(cornerRadius: CGFloat = Constants.Layout.cardCornerRadius, tintColor: Color? = nil) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tintColor: tintColor))
    }

    /// Applies glass control styling for interactive elements
    /// - Parameters:
    ///   - size: Size of the control
    ///   - cornerRadius: Optional corner radius (defaults to circular for square)
    ///   - isActive: Whether the control is active/selected
    /// - Returns: View with glass control effect
    func glassControl(size: CGSize = CGSize(width: 44, height: 44), cornerRadius: CGFloat? = nil, isActive: Bool = false) -> some View {
        modifier(GlassControlModifier(size: size, cornerRadius: cornerRadius, isActive: isActive))
    }

    /// Applies glass navigation styling
    /// - Returns: View with glass navigation effect
    func glassNavigation() -> some View {
        modifier(GlassNavigationModifier())
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == GlassButtonStyle {
    /// Glass button style for secondary buttons
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }

    /// Glass button style for primary buttons
    static var glassPrimary: GlassButtonStyle {
        GlassButtonStyle(isPrimary: true)
    }

    /// Glass button style with custom tint
    static func glass(tint: Color) -> GlassButtonStyle {
        GlassButtonStyle(tintColor: tint)
    }
}

// MARK: - Previews

#Preview("Glass Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") { }
            .buttonStyle(.glassPrimary)

        Button("Secondary Button") { }
            .buttonStyle(.glass)

        Button("Tinted Button") { }
            .buttonStyle(.glass(tint: .orange))

        Button("Disabled Button") { }
            .buttonStyle(.glassPrimary)
            .disabled(true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .speedrTheme()
}

#Preview("Glass Cards") {
    VStack(spacing: 20) {
        Text("Glass Card Content")
            .padding()
            .glassCard()

        Text("Tinted Glass Card")
            .padding()
            .glassCard(tintColor: .blue)

        HStack {
            Image(systemName: "play.fill")
            Text("Glass Control")
        }
        .padding()
        .glassCard(cornerRadius: 25)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .speedrTheme()
}

#Preview("Glass Controls") {
    HStack(spacing: 16) {
        Button { } label: {
            Image(systemName: "backward.fill")
                .foregroundColor(.white)
        }
        .glassControl()

        Button { } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .glassControl(size: CGSize(width: 64, height: 64))

        Button { } label: {
            Image(systemName: "forward.fill")
                .foregroundColor(.white)
        }
        .glassControl(isActive: true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .speedrTheme()
}
