//
//  UserPreferences.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Data Models" section
//

import Foundation
import SwiftUI

/// User preferences stored with @AppStorage
struct UserPreferences {
    // MARK: - Storage Keys

    private enum Keys {
        static let highlightColor = "highlightColor"
        static let fontSize = "fontSize"
        static let theme = "theme"
        static let defaultWPM = "defaultWPM"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let hasSeenSpeedHint = "hasSeenSpeedHint"
        static let totalWordsRead = "totalWordsRead"
        static let totalReadingTime = "totalReadingTime"
        static let sessionsCompleted = "sessionsCompleted"
    }

    // MARK: - Default Values

    static let defaultHighlightColor = "#FF3B3B"
    static let defaultFontSize: Double = 1.0
    static let defaultTheme = AppTheme.dark
    static let defaultWPMValue = Constants.Reader.defaultWPM
}

// MARK: - AppStorage Property Wrapper Helper

/// Observable object for managing user preferences
@Observable
final class PreferencesManager {
    // MARK: - Singleton

    static let shared = PreferencesManager()

    private init() {
        loadPreferences()
    }

    // MARK: - Stored Properties

    /// Hex color string for highlight
    var highlightColorHex: String = UserPreferences.defaultHighlightColor {
        didSet { savePreferences() }
    }

    /// Font size multiplier (1.0 = default)
    var fontSize: Double = UserPreferences.defaultFontSize {
        didSet { savePreferences() }
    }

    /// App theme setting
    var theme: AppTheme = UserPreferences.defaultTheme {
        didSet { savePreferences() }
    }

    /// Default reading speed
    var defaultWPM: Int = UserPreferences.defaultWPMValue {
        didSet { savePreferences() }
    }

    /// Whether onboarding has been shown
    var hasSeenOnboarding: Bool = false {
        didSet { savePreferences() }
    }

    /// Whether speed hint popup has been shown
    var hasSeenSpeedHint: Bool = false {
        didSet { savePreferences() }
    }

    /// Total words read across all sessions
    var totalWordsRead: Int = 0 {
        didSet { savePreferences() }
    }

    /// Total reading time in seconds
    var totalReadingTime: TimeInterval = 0 {
        didSet { savePreferences() }
    }

    /// Number of reading sessions completed
    var sessionsCompleted: Int = 0 {
        didSet { savePreferences() }
    }

    // MARK: - Computed Properties

    /// Highlight color as SwiftUI Color
    var highlightColor: Color {
        Color(hex: highlightColorHex)
    }

    /// Actual font size based on multiplier
    var actualFontSize: CGFloat {
        Constants.Reader.defaultFontSize * fontSize
    }

    /// Color scheme based on theme setting
    var colorScheme: ColorScheme? {
        switch theme {
        case .dark: return .dark
        case .light: return .light
        case .auto: return nil
        }
    }

    /// Formatted total reading time
    var totalReadingTimeFormatted: String {
        let hours = Int(totalReadingTime) / 3600
        let minutes = (Int(totalReadingTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Average WPM across sessions (estimated)
    var averageWPM: Int {
        guard totalReadingTime > 0 else { return defaultWPM }
        let minutes = totalReadingTime / 60
        guard minutes > 0 else { return defaultWPM }
        return Int(Double(totalWordsRead) / minutes)
    }

    // MARK: - Methods

    /// Set highlight color from Color
    func setHighlightColor(_ color: Color) {
        highlightColorHex = color.toHex() ?? UserPreferences.defaultHighlightColor
    }

    /// Record a completed reading session
    func recordSession(wordsRead: Int, duration: TimeInterval) {
        totalWordsRead += wordsRead
        totalReadingTime += duration
        sessionsCompleted += 1
    }

    /// Reset all statistics
    func resetStatistics() {
        totalWordsRead = 0
        totalReadingTime = 0
        sessionsCompleted = 0
    }

    /// Reset all preferences to defaults
    func resetToDefaults() {
        highlightColorHex = UserPreferences.defaultHighlightColor
        fontSize = UserPreferences.defaultFontSize
        theme = UserPreferences.defaultTheme
        defaultWPM = UserPreferences.defaultWPMValue
    }

    // MARK: - Persistence

    private func loadPreferences() {
        let defaults = UserDefaults.standard

        if let hex = defaults.string(forKey: "highlightColor") {
            highlightColorHex = hex
        }

        if defaults.object(forKey: "fontSize") != nil {
            fontSize = defaults.double(forKey: "fontSize")
        }

        if let themeString = defaults.string(forKey: "theme"),
           let savedTheme = AppTheme(rawValue: themeString) {
            theme = savedTheme
        }

        if defaults.object(forKey: "defaultWPM") != nil {
            defaultWPM = defaults.integer(forKey: "defaultWPM")
        }

        hasSeenOnboarding = defaults.bool(forKey: "hasSeenOnboarding")
        hasSeenSpeedHint = defaults.bool(forKey: "hasSeenSpeedHint")
        totalWordsRead = defaults.integer(forKey: "totalWordsRead")
        totalReadingTime = defaults.double(forKey: "totalReadingTime")
        sessionsCompleted = defaults.integer(forKey: "sessionsCompleted")
    }

    private func savePreferences() {
        let defaults = UserDefaults.standard

        defaults.set(highlightColorHex, forKey: "highlightColor")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(defaultWPM, forKey: "defaultWPM")
        defaults.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        defaults.set(hasSeenSpeedHint, forKey: "hasSeenSpeedHint")
        defaults.set(totalWordsRead, forKey: "totalWordsRead")
        defaults.set(totalReadingTime, forKey: "totalReadingTime")
        defaults.set(sessionsCompleted, forKey: "sessionsCompleted")
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    /// Convert Color to hex string
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}

// MARK: - Preset Highlight Colors

enum PresetHighlightColor: String, CaseIterable, Identifiable {
    case red = "#FF3B3B"
    case orange = "#FF9500"
    case yellow = "#FFCC00"
    case green = "#34C759"
    case blue = "#007AFF"
    case purple = "#AF52DE"
    case pink = "#FF2D55"

    var id: String { rawValue }

    var color: Color {
        Color(hex: rawValue)
    }

    var name: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        }
    }
}
