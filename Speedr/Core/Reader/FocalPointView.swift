//
//  FocalPointView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "FOCAL POINT STRUCTURE"
//
//  Structure:
//      ─────────────────┬─────────────────
//                       │  (8pt notch)
//
//                word here
//
//                       │  (8pt notch)
//      ─────────────────┴─────────────────
//

import SwiftUI

/// Displays the focal point lines and notches for the RSVP reader
struct FocalPointView: View {
    @Environment(\.theme) private var theme

    /// Configuration for the focal point structure
    private let config = FocalPointConfig()

    var body: some View {
        VStack(spacing: 0) {
            // Top focal line with notch
            FocalLineView(position: .top, config: config)

            // Space for the word (this is where WordDisplayView will be placed)
            Spacer()
                .frame(height: config.gapFromWord * 2 + config.wordAreaHeight)

            // Bottom focal line with notch
            FocalLineView(position: .bottom, config: config)
        }
        .frame(height: config.totalHeight)
    }
}

// MARK: - Focal Line View

/// Individual focal line (top or bottom) with center notch
struct FocalLineView: View {
    enum Position {
        case top
        case bottom
    }

    let position: Position
    let config: FocalPointConfig

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            if position == .bottom {
                // Notch above line for bottom position
                notch
            }

            // Horizontal line with gap in center
            HStack(spacing: 0) {
                // Left line
                Rectangle()
                    .fill(theme.focalLines.opacity(config.lineOpacity))
                    .frame(width: config.lineLength, height: config.lineWidth)

                // Center gap (for notch)
                Spacer()
                    .frame(width: config.notchWidth)

                // Right line
                Rectangle()
                    .fill(theme.focalLines.opacity(config.lineOpacity))
                    .frame(width: config.lineLength, height: config.lineWidth)
            }

            if position == .top {
                // Notch below line for top position
                notch
            }
        }
    }

    private var notch: some View {
        Rectangle()
            .fill(theme.focalLines.opacity(config.lineOpacity))
            .frame(width: config.notchWidth, height: config.notchHeight)
    }
}

// MARK: - Configuration

/// Configuration values for the focal point structure
struct FocalPointConfig {
    /// Line thickness: 1pt
    let lineWidth: CGFloat = Constants.FocalPoint.lineWidth

    /// Each horizontal line length: 120pt
    let lineLength: CGFloat = Constants.FocalPoint.lineLength

    /// Vertical notch height: 8pt
    let notchHeight: CGFloat = Constants.FocalPoint.notchHeight

    /// Notch thickness: 1pt
    let notchWidth: CGFloat = Constants.FocalPoint.notchWidth

    /// Space between line and word: 24pt
    let gapFromWord: CGFloat = Constants.FocalPoint.gapFromWord

    /// Opacity of focal lines: 50%
    let lineOpacity: Double = Constants.FocalPoint.lineOpacity

    /// Estimated height for word area
    let wordAreaHeight: CGFloat = 60

    /// Total height of the focal point structure
    var totalHeight: CGFloat {
        // Top line + notch + gap + word area + gap + notch + bottom line
        lineWidth + notchHeight + gapFromWord + wordAreaHeight + gapFromWord + notchHeight + lineWidth
    }

    /// Width needed for the focal lines
    var totalWidth: CGFloat {
        lineLength + notchWidth + lineLength
    }
}

// MARK: - Overlay Version

/// Focal point that can be used as an overlay around content
struct FocalPointOverlay: View {
    @Environment(\.theme) private var theme

    private let config = FocalPointConfig()

    var body: some View {
        VStack(spacing: 0) {
            // Top focal line with notch pointing down
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.focalLines.opacity(config.lineOpacity))
                        .frame(width: config.lineLength, height: config.lineWidth)

                    Spacer()
                        .frame(width: config.notchWidth)

                    Rectangle()
                        .fill(theme.focalLines.opacity(config.lineOpacity))
                        .frame(width: config.lineLength, height: config.lineWidth)
                }

                Rectangle()
                    .fill(theme.focalLines.opacity(config.lineOpacity))
                    .frame(width: config.notchWidth, height: config.notchHeight)
            }

            Spacer()

            // Bottom focal line with notch pointing up
            VStack(spacing: 0) {
                Rectangle()
                    .fill(theme.focalLines.opacity(config.lineOpacity))
                    .frame(width: config.notchWidth, height: config.notchHeight)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.focalLines.opacity(config.lineOpacity))
                        .frame(width: config.lineLength, height: config.lineWidth)

                    Spacer()
                        .frame(width: config.notchWidth)

                    Rectangle()
                        .fill(theme.focalLines.opacity(config.lineOpacity))
                        .frame(width: config.lineLength, height: config.lineWidth)
                }
            }
        }
    }
}

// MARK: - View Modifier

/// View modifier to add focal point lines around content
struct FocalPointModifier: ViewModifier {
    let verticalPadding: CGFloat

    init(verticalPadding: CGFloat = Constants.FocalPoint.gapFromWord) {
        self.verticalPadding = verticalPadding
    }

    func body(content: Content) -> some View {
        content
            .padding(.vertical, verticalPadding)
            .overlay(
                FocalPointOverlay()
            )
    }
}

extension View {
    /// Add focal point lines around this view
    func focalPoint(verticalPadding: CGFloat = Constants.FocalPoint.gapFromWord) -> some View {
        modifier(FocalPointModifier(verticalPadding: verticalPadding))
    }
}

// MARK: - Previews

#Preview("Focal Point View") {
    ZStack {
        Color.black.ignoresSafeArea()

        FocalPointView()
    }
    .speedrTheme()
}

#Preview("Focal Point Overlay") {
    ZStack {
        Color.black.ignoresSafeArea()

        Text("people")
            .font(.system(size: 48, weight: .medium, design: .serif))
            .foregroundColor(.white)
            .focalPoint()
    }
    .speedrTheme()
}

#Preview("Focal Lines Only") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            FocalLineView(position: .top, config: FocalPointConfig())
            FocalLineView(position: .bottom, config: FocalPointConfig())
        }
    }
    .speedrTheme()
}
