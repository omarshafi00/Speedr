//
//  WordDisplayView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "WORD DISPLAY", "Word Positioning"
//  Reference: RESOURCES.md - Section 1 (AttributedString)
//

import SwiftUI

/// Displays a single word with the ORP character highlighted and positioned at center
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

#Preview("Word Display") {
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
            WordDisplayView(word: "reading", highlightColor: ThemeColors.highlightRed)
                .frame(height: 60)

            WordDisplayView(word: "reading", highlightColor: .blue)
                .frame(height: 60)

            WordDisplayView(word: "reading", highlightColor: .green)
                .frame(height: 60)

            WordDisplayView(word: "reading", highlightColor: .orange)
                .frame(height: 60)
        }
    }
    .speedrTheme()
}

#Preview("ORP Alignment Test") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 0) {
            // Vertical center line for reference
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .overlay(
            VStack(spacing: 20) {
                ForEach(["I", "am", "fast", "reader", "comprehension"], id: \.self) { word in
                    WordDisplayView(word: word)
                        .frame(height: 50)
                }
            }
        )
    }
    .speedrTheme()
}
