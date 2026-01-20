//
//  Constants.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Spacing & Layout", "Business Logic", "Technical Specifications"
//

import Foundation
import SwiftUI

// MARK: - App Constants

/// Central location for all app-wide constants
enum Constants {

    // MARK: - Layout & Spacing

    enum Layout {
        /// Standard margin: 16pt
        static let standardMargin: CGFloat = 16

        /// Card padding: 20pt
        static let cardPadding: CGFloat = 20

        /// Button height: 50pt
        static let buttonHeight: CGFloat = 50

        /// Corner radius for cards: 12pt
        static let cardCornerRadius: CGFloat = 12

        /// Corner radius for buttons: 25pt
        static let buttonCornerRadius: CGFloat = 25
    }

    // MARK: - Focal Point Configuration

    enum FocalPoint {
        /// Line thickness: 1pt
        static let lineWidth: CGFloat = 1.0

        /// Each horizontal line length: 120pt
        static let lineLength: CGFloat = 120

        /// Vertical notch height: 8pt
        static let notchHeight: CGFloat = 8

        /// Notch thickness: 1pt
        static let notchWidth: CGFloat = 1.0

        /// Space between line and word: 24pt
        static let gapFromWord: CGFloat = 24

        /// Opacity of focal lines
        static let lineOpacity: Double = 0.5
    }

    // MARK: - Reader Settings

    enum Reader {
        /// Default font size for word display: 48pt
        static let defaultFontSize: CGFloat = 48

        /// Minimum reading speed: 100 WPM
        static let minWPM: Int = 100

        /// Maximum reading speed (Pro): 1500 WPM
        static let maxWPM: Int = 1500

        /// Default starting speed: 300 WPM
        static let defaultWPM: Int = 300

        /// Speed adjustment step: 10 WPM
        static let speedStep: Int = 10

        /// Character width approximation factor (for positioning)
        static let characterWidthFactor: CGFloat = 0.6
    }

    // MARK: - Business Logic / Limits

    enum Limits {
        /// Free tier: Maximum documents allowed (excluding built-in)
        static let freeMaxDocuments: Int = 1

        /// Free tier: Maximum WPM allowed
        static let freeMaxWPM: Int = 400

        /// Pro tier: Maximum WPM allowed
        static let proMaxWPM: Int = 1500
    }

    // MARK: - Animation

    enum Animation {
        /// Default animation duration
        static let defaultDuration: Double = 0.3

        /// Word transition animation duration
        static let wordTransitionDuration: Double = 0.1
    }

    // MARK: - Timing

    enum Timing {
        /// Delay before showing speed hint popup (seconds)
        static let speedHintDelay: Double = 3.0

        /// Long press interval for continuous speed adjustment (seconds)
        static let longPressInterval: Double = 0.1
    }

    // MARK: - Product Identifiers

    enum Products {
        /// Monthly subscription product ID
        static let monthlySubscription = "com.speedr.monthly"

        /// Yearly subscription product ID
        static let yearlySubscription = "com.speedr.yearly"
    }
}

// MARK: - Helper Functions

extension Constants.Reader {
    /// Calculate milliseconds per word from WPM
    /// - Parameter wpm: Words per minute
    /// - Returns: Milliseconds per word
    static func millisecondsPerWord(wpm: Int) -> Int {
        guard wpm > 0 else { return 1000 }
        return Int(60000.0 / Double(wpm))
    }

    /// Calculate the Optimal Recognition Point (ORP) index for a word
    /// The ORP is approximately 35% from the start of the word
    /// - Parameter word: The word to analyze
    /// - Returns: The index of the ORP character
    static func findORPIndex(word: String) -> Int {
        let length = word.count
        if length <= 1 { return 0 }
        if length <= 3 { return 0 }  // First letter for short words

        // ORP is approximately 35% from the start
        return Int(Double(length - 1) * 0.35)
    }

    /// Calculate word offset to align ORP with screen center
    /// - Parameters:
    ///   - word: The word to position
    ///   - fontSize: The font size being used
    /// - Returns: Horizontal offset to apply
    static func calculateWordOffset(word: String, fontSize: CGFloat) -> CGFloat {
        let orpIndex = findORPIndex(word: word)
        let characterWidth = fontSize * characterWidthFactor
        let wordWidth = CGFloat(word.count) * characterWidth
        let orpPosition = CGFloat(orpIndex) * characterWidth
        let centerOffset = wordWidth / 2 - orpPosition
        return -centerOffset
    }
}

// MARK: - Limits Helper Functions

extension Constants.Limits {
    /// Check if user can upload another document
    /// - Parameters:
    ///   - currentCount: Current number of user documents
    ///   - isPro: Whether user has Pro subscription
    /// - Returns: True if upload is allowed
    static func canUploadDocument(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeMaxDocuments
    }

    /// Check if user can increase speed
    /// - Parameters:
    ///   - currentWPM: Current reading speed
    ///   - isPro: Whether user has Pro subscription
    /// - Returns: True if speed increase is allowed
    static func canIncreaseSpeed(currentWPM: Int, isPro: Bool) -> Bool {
        if isPro { return currentWPM < proMaxWPM }
        return currentWPM < freeMaxWPM
    }

    /// Get maximum allowed WPM for subscription status
    /// - Parameter isPro: Whether user has Pro subscription
    /// - Returns: Maximum WPM allowed
    static func maxAllowedWPM(isPro: Bool) -> Int {
        isPro ? proMaxWPM : freeMaxWPM
    }
}
