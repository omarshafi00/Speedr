//
//  Theme.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Design System" section
//

import SwiftUI

// MARK: - App Theme

/// Defines the app's theme mode
enum AppTheme: String, Codable, CaseIterable {
    case dark
    case light
    case auto

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .auto: return "Auto"
        }
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Colors

/// App color palette following PROJECT_SPEC.md
struct ThemeColors {

    // MARK: - Accent Colors

    /// Default middle letter highlight color - #FF3B3B
    static let highlightRed = Color(hex: "FF3B3B")

    /// Buttons and links accent color - #007AFF
    static let accentBlue = Color(hex: "007AFF")

    // MARK: - Dark Theme Colors

    struct Dark {
        /// Background: #000000
        static let background = Color.black

        /// Surface: #1C1C1E
        static let surface = Color(hex: "1C1C1E")

        /// Text Primary: #FFFFFF
        static let textPrimary = Color.white

        /// Text Secondary: #8E8E93
        static let textSecondary = Color(hex: "8E8E93")

        /// Focal Lines: #48484A
        static let focalLines = Color(hex: "48484A")
    }

    // MARK: - Light Theme Colors

    struct Light {
        /// Background: #FFFFFF
        static let background = Color.white

        /// Surface: #F2F2F7
        static let surface = Color(hex: "F2F2F7")

        /// Text Primary: #000000
        static let textPrimary = Color.black

        /// Text Secondary: #6C6C70
        static let textSecondary = Color(hex: "6C6C70")

        /// Focal Lines: #C6C6C8
        static let focalLines = Color(hex: "C6C6C8")
    }
}

// MARK: - Environment-Aware Theme

/// Provides theme colors based on the current color scheme
struct Theme {
    let colorScheme: ColorScheme

    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    // MARK: - Dynamic Colors

    var background: Color {
        colorScheme == .dark ? ThemeColors.Dark.background : ThemeColors.Light.background
    }

    var surface: Color {
        colorScheme == .dark ? ThemeColors.Dark.surface : ThemeColors.Light.surface
    }

    var textPrimary: Color {
        colorScheme == .dark ? ThemeColors.Dark.textPrimary : ThemeColors.Light.textPrimary
    }

    var textSecondary: Color {
        colorScheme == .dark ? ThemeColors.Dark.textSecondary : ThemeColors.Light.textSecondary
    }

    var focalLines: Color {
        colorScheme == .dark ? ThemeColors.Dark.focalLines : ThemeColors.Light.focalLines
    }

    // MARK: - Static Accent Colors

    var highlightRed: Color { ThemeColors.highlightRed }
    var accentBlue: Color { ThemeColors.accentBlue }
}

// MARK: - Typography

/// App typography following PROJECT_SPEC.md
struct Typography {

    // MARK: - Reader View

    /// Word Display: New York (serif), 48pt, medium weight
    static func readerWord(size: CGFloat = 48) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// WPM Display: SF Pro, 16pt, regular
    static let wpmDisplay: Font = .system(size: 16, weight: .regular)

    // MARK: - App UI

    /// Headlines: SF Pro Display, 34pt, bold
    static let headline: Font = .system(size: 34, weight: .bold)

    /// Body: SF Pro Text, 17pt, regular
    static let body: Font = .system(size: 17, weight: .regular)

    /// Caption: SF Pro Text, 13pt, regular
    static let caption: Font = .system(size: 13, weight: .regular)
}

// MARK: - Environment Key for Theme

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme(colorScheme: .dark)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier for Theme

struct ThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.theme, Theme(colorScheme: colorScheme))
    }
}

extension View {
    /// Apply the Speedr theme to this view hierarchy
    func speedrTheme() -> some View {
        modifier(ThemeModifier())
    }
}
