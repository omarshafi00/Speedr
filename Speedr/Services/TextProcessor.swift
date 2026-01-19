//
//  TextProcessor.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "WORD DISPLAY", "Word Positioning"
//  Reference: RESOURCES.md - Section 1 (AttributedString)
//

import SwiftUI

/// Processes text for RSVP reading display
struct TextProcessor {

    // MARK: - Word Splitting

    /// Split text into individual words, removing empty entries
    /// - Parameter text: The full text content
    /// - Returns: Array of words
    static func splitIntoWords(_ text: String) -> [String] {
        // Split by whitespace and newlines, filter empty strings
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    // MARK: - ORP (Optimal Recognition Point) Calculation

    /// Calculate the Optimal Recognition Point index for a word
    /// The ORP is approximately 35% from the start of the word
    /// - Parameter word: The word to analyze
    /// - Returns: The index of the ORP character (0-based)
    static func findORPIndex(word: String) -> Int {
        let length = word.count
        if length <= 1 { return 0 }
        if length <= 3 { return 0 }  // First letter for short words

        // ORP is approximately 35% from the start
        return Int(Double(length - 1) * 0.35)
    }

    /// Get the character at the ORP position
    /// - Parameter word: The word to analyze
    /// - Returns: The ORP character, or nil if word is empty
    static func getORPCharacter(word: String) -> Character? {
        guard !word.isEmpty else { return nil }
        let index = findORPIndex(word: word)
        let stringIndex = word.index(word.startIndex, offsetBy: index)
        return word[stringIndex]
    }

    // MARK: - Styled Word Creation

    /// Create an AttributedString with the ORP character highlighted
    /// - Parameters:
    ///   - word: The word to style
    ///   - highlightColor: Color for the ORP character
    ///   - baseColor: Color for the rest of the word
    /// - Returns: Styled AttributedString
    static func createStyledWord(
        _ word: String,
        highlightColor: Color,
        baseColor: Color
    ) -> AttributedString {
        guard !word.isEmpty else {
            return AttributedString("")
        }

        var attributedString = AttributedString(word)

        // Set base color for entire word
        attributedString.foregroundColor = baseColor

        // Find and highlight the ORP character
        let orpIndex = findORPIndex(word: word)

        // Get the range of the ORP character
        let startIndex = attributedString.index(
            attributedString.startIndex,
            offsetByCharacters: orpIndex
        )
        let endIndex = attributedString.index(
            startIndex,
            offsetByCharacters: 1
        )
        let orpRange = startIndex..<endIndex

        // Apply highlight color to ORP character
        attributedString[orpRange].foregroundColor = highlightColor

        return attributedString
    }

    // MARK: - Word Positioning

    /// Calculate horizontal offset to align ORP with screen center
    /// - Parameters:
    ///   - word: The word to position
    ///   - fontSize: The font size being used
    ///   - characterWidthFactor: Factor to estimate character width (default 0.6)
    /// - Returns: Horizontal offset to apply (negative shifts left)
    static func calculateWordOffset(
        word: String,
        fontSize: CGFloat,
        characterWidthFactor: CGFloat = Constants.Reader.characterWidthFactor
    ) -> CGFloat {
        guard !word.isEmpty else { return 0 }

        let orpIndex = findORPIndex(word: word)
        let characterWidth = fontSize * characterWidthFactor
        let wordWidth = CGFloat(word.count) * characterWidth
        let orpPosition = CGFloat(orpIndex) * characterWidth + (characterWidth / 2)
        let wordCenter = wordWidth / 2

        // Offset needed to move ORP to center
        return wordCenter - orpPosition
    }

    // MARK: - Timing Calculation

    /// Calculate milliseconds per word from WPM
    /// - Parameter wpm: Words per minute
    /// - Returns: Milliseconds to display each word
    static func millisecondsPerWord(wpm: Int) -> Int {
        guard wpm > 0 else { return 1000 }
        return Int(60000.0 / Double(wpm))
    }

    /// Calculate time interval per word from WPM
    /// - Parameter wpm: Words per minute
    /// - Returns: TimeInterval (seconds) to display each word
    static func timeIntervalPerWord(wpm: Int) -> TimeInterval {
        guard wpm > 0 else { return 1.0 }
        return 60.0 / Double(wpm)
    }

    // MARK: - Text Statistics

    /// Calculate estimated reading time
    /// - Parameters:
    ///   - wordCount: Number of words
    ///   - wpm: Reading speed in words per minute
    /// - Returns: Estimated time in seconds
    static func estimatedReadingTime(wordCount: Int, wpm: Int) -> TimeInterval {
        guard wpm > 0 else { return 0 }
        return Double(wordCount) / Double(wpm) * 60.0
    }

    /// Format reading time as human-readable string
    /// - Parameter seconds: Time in seconds
    /// - Returns: Formatted string (e.g., "2 min", "1 hr 30 min")
    static func formatReadingTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours) hr \(remainingMinutes) min"
            }
            return "\(hours) hr"
        }

        if minutes > 0 {
            return "\(minutes) min"
        }

        return "< 1 min"
    }

    /// Calculate words remaining from current position
    /// - Parameters:
    ///   - currentIndex: Current word index (0-based)
    ///   - totalWords: Total number of words
    /// - Returns: Number of words remaining
    static func wordsRemaining(currentIndex: Int, totalWords: Int) -> Int {
        max(0, totalWords - currentIndex - 1)
    }

    /// Calculate progress percentage
    /// - Parameters:
    ///   - currentIndex: Current word index (0-based)
    ///   - totalWords: Total number of words
    /// - Returns: Progress as percentage (0.0 to 1.0)
    static func progress(currentIndex: Int, totalWords: Int) -> Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalWords)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TextProcessor {
    /// Sample words for testing ORP calculation
    static let sampleWords = [
        "a", "the", "read", "people", "reading", "understanding", "comprehension"
    ]

    /// Print ORP analysis for debugging
    static func debugORPAnalysis() {
        for word in sampleWords {
            let orpIndex = findORPIndex(word: word)
            let orpChar = getORPCharacter(word: word) ?? Character(" ")
            print("\"\(word)\" (length: \(word.count)) → ORP index: \(orpIndex), char: '\(orpChar)'")
        }
    }
}
#endif
