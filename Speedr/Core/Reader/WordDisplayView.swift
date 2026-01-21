//
//  WordDisplayView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "WORD DISPLAY", "Word Positioning"
//  Reference: RESOURCES.md - Section 1 (AttributedString)
//

import SwiftUI

// MARK: - Aligned Word View (Primary - Used in Reader)

/// Displays a word with the highlighted letter (2nd letter) precisely aligned with the focal point notches.
/// This view splits the word into three parts and uses SwiftUI's layout system for pixel-perfect alignment.
/// The middle of the highlighted letter is centered on the notch position.
struct AlignedWordView: View {
    /// The word to display
    let word: String

    /// Color for the highlighted character
    var highlightColor: Color = ThemeColors.highlightRed

    /// Font size for the word
    var fontSize: CGFloat = Constants.Reader.defaultFontSize

    @Environment(\.theme) private var theme

    /// The focal point width (240pt)
    private var focalPointWidth: CGFloat {
        Constants.FocalPoint.lineLength * 2
    }

    /// Notch position from left edge (24pt = 10% of 240pt)
    private var notchPositionFromLeft: CGFloat {
        focalPointWidth * 0.10
    }

    /// Approximate width of highlighted letter
    private var highlightedLetterWidth: CGFloat {
        fontSize * 0.6
    }

    /// Half the width of the highlighted letter (for centering)
    private var halfHighlightedLetterWidth: CGFloat {
        highlightedLetterWidth / 2
    }

    var body: some View {
        // Use the focal point width as the container
        HStack(spacing: 0) {
            // Left section: contains letters BEFORE the highlighted letter
            // This section ends at (notch position - half letter width) so the letter's center is at the notch
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(beforeHighlight)
                    .font(Typography.readerWord(size: fontSize))
                    .foregroundColor(theme.textPrimary)
            }
            .frame(width: max(0, notchPositionFromLeft - halfHighlightedLetterWidth))

            // Center: the highlighted letter - its CENTER is positioned at the notch
            Text(highlightedLetter)
                .font(Typography.readerWord(size: fontSize))
                .foregroundColor(highlightColor)

            // Right section: contains letters AFTER the highlighted letter
            // Uses remaining space after notch + half letter width
            HStack(spacing: 0) {
                Text(afterHighlight)
                    .font(Typography.readerWord(size: fontSize))
                    .foregroundColor(theme.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(width: focalPointWidth - notchPositionFromLeft - halfHighlightedLetterWidth)
        }
        .frame(width: focalPointWidth)
    }

    // MARK: - Word Parts

    /// Letters before the highlighted letter
    private var beforeHighlight: String {
        guard word.count > 1 else { return "" }
        let highlightIndex = TextProcessor.findHighlightIndex(word: word)
        guard highlightIndex > 0 else { return "" }
        let endIndex = word.index(word.startIndex, offsetBy: highlightIndex)
        return String(word[..<endIndex])
    }

    /// The highlighted letter (2nd letter, index 1)
    private var highlightedLetter: String {
        guard !word.isEmpty else { return "" }
        let highlightIndex = TextProcessor.findHighlightIndex(word: word)
        guard highlightIndex < word.count else { return "" }
        let index = word.index(word.startIndex, offsetBy: highlightIndex)
        return String(word[index])
    }

    /// Letters after the highlighted letter
    private var afterHighlight: String {
        guard word.count > 1 else { return "" }
        let highlightIndex = TextProcessor.findHighlightIndex(word: word)
        guard highlightIndex + 1 < word.count else { return "" }
        let startIndex = word.index(word.startIndex, offsetBy: highlightIndex + 1)
        return String(word[startIndex...])
    }

}

// MARK: - Legacy Word Display View

/// Displays a single word with the ORP character highlighted and positioned at center
/// Note: For precise alignment with notches, use AlignedWordView instead
struct WordDisplayView: View {
    /// The word to display
    let word: String

    /// Color for the ORP (focal) character
    var highlightColor: Color = ThemeColors.highlightRed

    /// Font size for the word
    var fontSize: CGFloat = Constants.Reader.defaultFontSize

    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()

                Text(styledWord)
                    .font(Typography.readerWord(size: fontSize))
                    .offset(x: wordOffset)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// The word styled with highlighted ORP character
    private var styledWord: AttributedString {
        TextProcessor.createStyledWord(
            word,
            highlightColor: highlightColor,
            baseColor: theme.textPrimary
        )
    }

    /// Horizontal offset to align ORP with center
    private var wordOffset: CGFloat {
        TextProcessor.calculateWordOffset(word: word, fontSize: fontSize)
    }
}

// MARK: - Word Display with Focal Point

/// Complete word display with focal point lines
struct WordDisplayWithFocalPoint: View {
    /// The word to display
    let word: String

    /// Color for the ORP (focal) character
    var highlightColor: Color = ThemeColors.highlightRed

    /// Font size for the word
    var fontSize: CGFloat = Constants.Reader.defaultFontSize

    @Environment(\.theme) private var theme

    private let config = FocalPointConfig()

    var body: some View {
        ZStack {
            // Focal point overlay
            FocalPointOverlay()

            // Word centered in the focal area
            Text(styledWord)
                .font(Typography.readerWord(size: fontSize))
                .offset(x: wordOffset)
        }
        .frame(height: config.totalHeight)
    }

    private var styledWord: AttributedString {
        TextProcessor.createStyledWord(
            word,
            highlightColor: highlightColor,
            baseColor: theme.textPrimary
        )
    }

    private var wordOffset: CGFloat {
        TextProcessor.calculateWordOffset(word: word, fontSize: fontSize)
    }
}

// MARK: - Animated Word Display

/// Word display with transition animation between words
struct AnimatedWordDisplay: View {
    /// The word to display
    let word: String

    /// Unique identifier for animation
    let wordId: Int

    /// Color for the ORP (focal) character
    var highlightColor: Color = ThemeColors.highlightRed

    /// Font size for the word
    var fontSize: CGFloat = Constants.Reader.defaultFontSize

    @Environment(\.theme) private var theme

    var body: some View {
        Text(styledWord)
            .font(Typography.readerWord(size: fontSize))
            .offset(x: wordOffset)
            .id(wordId)
            .transition(.opacity)
    }

    private var styledWord: AttributedString {
        TextProcessor.createStyledWord(
            word,
            highlightColor: highlightColor,
            baseColor: theme.textPrimary
        )
    }

    private var wordOffset: CGFloat {
        TextProcessor.calculateWordOffset(word: word, fontSize: fontSize)
    }
}

// MARK: - Static Centered Word (No Offset)

/// Simple centered word display without ORP positioning
/// Use this for UI elements where centering isn't based on ORP
struct CenteredWordDisplay: View {
    let word: String
    var highlightColor: Color = ThemeColors.highlightRed
    var fontSize: CGFloat = Constants.Reader.defaultFontSize

    @Environment(\.theme) private var theme

    var body: some View {
        Text(styledWord)
            .font(Typography.readerWord(size: fontSize))
    }

    private var styledWord: AttributedString {
        TextProcessor.createStyledWord(
            word,
            highlightColor: highlightColor,
            baseColor: theme.textPrimary
        )
    }
}

// MARK: - Previews

#Preview("Aligned Word - Notch Alignment Test") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            // Test various words to verify the 2nd letter aligns with notches
            ForEach(["I", "To", "The", "Read", "Hello", "People", "Reading", "Wonderful"], id: \.self) { word in
                ZStack {
                    // Focal point overlay for reference
                    FocalPointOverlay()

                    // The aligned word
                    AlignedWordView(word: word)
                }
                .frame(height: 80)
            }
        }
        .padding()
    }
    .speedrTheme()
}

#Preview("Aligned Word - Capital Letters Test") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            // Test capital vs lowercase to verify alignment is consistent
            ForEach(["HELLO", "Hello", "hello", "HeLLo", "Million", "MILLION"], id: \.self) { word in
                ZStack {
                    FocalPointOverlay()
                    AlignedWordView(word: word)
                }
                .frame(height: 80)
            }
        }
        .padding()
    }
    .speedrTheme()
}

#Preview("Word Display - Legacy") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Show different words with their ORP highlighted
            ForEach(["a", "the", "read", "people", "reading"], id: \.self) { word in
                VStack(spacing: 8) {
                    WordDisplayView(word: word)
                        .frame(height: 60)

                    Text("ORP index: \(TextProcessor.findORPIndex(word: word))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    .speedrTheme()
}

#Preview("Word with Focal Point") {
    ZStack {
        Color.black.ignoresSafeArea()

        WordDisplayWithFocalPoint(word: "people")
    }
    .speedrTheme()
}

#Preview("Different Highlight Colors") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            AlignedWordView(word: "reading", highlightColor: ThemeColors.highlightRed)

            AlignedWordView(word: "reading", highlightColor: .blue)

            AlignedWordView(word: "reading", highlightColor: .green)

            AlignedWordView(word: "reading", highlightColor: .orange)
        }
    }
    .speedrTheme()
}
