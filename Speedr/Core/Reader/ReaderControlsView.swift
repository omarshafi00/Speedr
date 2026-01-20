//
//  ReaderControlsView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SPEED CONTROLS"
//  Reference: RESOURCES.md - Section 2 (Liquid Glass)
//
//  Controls layout (5 circular glass buttons):
//  ┌────┐ ┌────┐ ┌──────┐ ┌────┐ ┌────┐
//  │ ⏪ │ │ ◀◀ │ │  ⏸   │ │ ▶▶ │ │ ⏩ │
//  └────┘ └────┘ └──────┘ └────┘ └────┘
//  speed  prev    play    next  speed
//  down   word   /pause   word   up
//

import SwiftUI

/// Reader control buttons (5 circular glass buttons)
/// Speed down | Prev word | Play/Pause | Next word | Speed up
struct ReaderControlsView: View {
    @Bindable var viewModel: ReaderViewModel

    /// Called when speed limit is hit (for showing paywall)
    var onSpeedLimitReached: (() -> Void)?

    /// Called when music button is tapped (for showing paywall for free users)
    var onMusicTapped: (() -> Void)?

    @Environment(\.theme) private var theme

    /// Timer for continuous speed adjustment on long press
    @State private var longPressTimer: Timer?

    /// Small button size
    private let smallButtonSize: CGFloat = 50

    /// Large (play/pause) button size
    private let largeButtonSize: CGFloat = 70

    var body: some View {
        HStack(spacing: 12) {
            // Speed Down Button (leftmost)
            GlassCircleButton(
                systemImage: "minus",
                size: smallButtonSize,
                isEnabled: viewModel.canDecreaseSpeed
            ) {
                viewModel.decreaseSpeed()
            } onLongPressStart: {
                startContinuousDecrease()
            } onLongPressEnd: {
                stopContinuousAdjustment()
            }

            // Previous Word Button
            GlassCircleButton(
                systemImage: "backward.fill",
                size: smallButtonSize,
                isEnabled: viewModel.currentIndex > 0
            ) {
                viewModel.previousWord()
            }

            // Play/Pause Button (center, larger)
            GlassCircleButton(
                systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: largeButtonSize,
                isPrimary: true,
                isEnabled: true
            ) {
                viewModel.togglePlayPause()
            }

            // Next Word Button
            GlassCircleButton(
                systemImage: "forward.fill",
                size: smallButtonSize,
                isEnabled: viewModel.currentIndex < viewModel.totalWords - 1
            ) {
                viewModel.nextWord()
            }

            // Speed Up Button (rightmost)
            GlassCircleButton(
                systemImage: "plus",
                size: smallButtonSize,
                isEnabled: true // Always enabled - will show paywall if at limit
            ) {
                handleSpeedIncrease()
            } onLongPressStart: {
                startContinuousIncrease()
            } onLongPressEnd: {
                stopContinuousAdjustment()
            }
        }
    }

    // MARK: - Speed Control Helpers

    private func handleSpeedIncrease() {
        if viewModel.canIncreaseSpeed {
            viewModel.increaseSpeed()
        } else {
            // At speed limit - trigger paywall
            onSpeedLimitReached?()
        }
    }

    private func startContinuousIncrease() {
        stopContinuousAdjustment()
        longPressTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Timing.longPressInterval,
            repeats: true
        ) { _ in
            if viewModel.canIncreaseSpeed {
                viewModel.increaseSpeed()
            } else {
                stopContinuousAdjustment()
                onSpeedLimitReached?()
            }
        }
    }

    private func startContinuousDecrease() {
        stopContinuousAdjustment()
        longPressTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Timing.longPressInterval,
            repeats: true
        ) { _ in
            if viewModel.canDecreaseSpeed {
                viewModel.decreaseSpeed()
            } else {
                stopContinuousAdjustment()
            }
        }
    }

    private func stopContinuousAdjustment() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
}

// MARK: - Glass Circle Button

/// Circular button with glass effect for reader controls
struct GlassCircleButton: View {
    let systemImage: String
    let size: CGFloat
    var isPrimary: Bool = false
    let isEnabled: Bool
    let onTap: () -> Void
    var onLongPressStart: (() -> Void)? = nil
    var onLongPressEnd: (() -> Void)? = nil

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                // Glass background
                Circle()
                    .fill(isPrimary ? theme.accentBlue : theme.surface.opacity(0.8))

                // Icon
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(isPrimary ? .white : (isEnabled ? theme.textPrimary : theme.textSecondary.opacity(0.5)))
            }
            .frame(width: size, height: size)
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && !isPrimary)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    guard isEnabled, onLongPressStart != nil else { return }
                    isPressed = true
                    onLongPressStart?()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        onLongPressEnd?()
                    }
                }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
    }
}

// MARK: - WPM Display

/// Displays current reading speed with highlight color
struct WPMDisplayView: View {
    let wpm: Int
    var highlightColor: Color = ThemeColors.highlightRed

    @Environment(\.theme) private var theme

    var body: some View {
        Text("\(wpm) wpm")
            .font(Typography.wpmDisplay)
            .foregroundColor(highlightColor)
    }
}

// MARK: - Music Button

/// Music button for reader view - shows paywall for free users
struct MusicButton: View {
    let isPro: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.surface.opacity(0.8))
                    .frame(width: 44, height: 44)

                Image(systemName: isPro ? "music.note" : "music.note")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                // Lock badge for free users
                if !isPro {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(theme.accentBlue)
                        .clipShape(Circle())
                        .offset(x: 14, y: -14)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar

/// Reading progress bar
struct ReaderProgressBar: View {
    let progress: Double
    let progressText: String
    let timeRemaining: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.surface)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accentBlue)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            // Labels
            HStack {
                Text("Location: \(progressText)")
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)

                Spacer()

                Text("\(timeRemaining) left")
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - Compact Controls (Alternative Layout)

/// Compact horizontal control strip
struct CompactReaderControls: View {
    @Bindable var viewModel: ReaderViewModel
    var onSpeedLimitReached: (() -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 24) {
            // Speed down
            Button {
                viewModel.decreaseSpeed()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.canDecreaseSpeed ? theme.textSecondary : theme.textSecondary.opacity(0.3))
            }
            .disabled(!viewModel.canDecreaseSpeed)

            // WPM display
            Text(viewModel.wpmDisplay)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(theme.textPrimary)
                .frame(width: 80)

            // Speed up
            Button {
                if viewModel.canIncreaseSpeed {
                    viewModel.increaseSpeed()
                } else {
                    onSpeedLimitReached?()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.canIncreaseSpeed ? theme.textSecondary : theme.textSecondary.opacity(0.3))
            }
        }
    }
}

// MARK: - Previews

#Preview("Reader Controls - 5 Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ReaderControlsView(viewModel: ReaderViewModel.preview)

            WPMDisplayView(wpm: 300, highlightColor: ThemeColors.highlightRed)

            ReaderProgressBar(
                progress: 0.45,
                progressText: "45%",
                timeRemaining: "2 min"
            )
            .padding(.horizontal)
        }
    }
    .speedrTheme()
}

#Preview("Glass Circle Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 16) {
            GlassCircleButton(systemImage: "minus", size: 50, isEnabled: true) { }
            GlassCircleButton(systemImage: "backward.fill", size: 50, isEnabled: true) { }
            GlassCircleButton(systemImage: "play.fill", size: 70, isPrimary: true, isEnabled: true) { }
            GlassCircleButton(systemImage: "forward.fill", size: 50, isEnabled: true) { }
            GlassCircleButton(systemImage: "plus", size: 50, isEnabled: true) { }
        }
    }
    .speedrTheme()
}

#Preview("Music Button") {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 20) {
            MusicButton(isPro: false) { }
            MusicButton(isPro: true) { }
        }
    }
    .speedrTheme()
}

#Preview("Compact Controls") {
    ZStack {
        Color.black.ignoresSafeArea()

        CompactReaderControls(viewModel: ReaderViewModel.preview)
    }
    .speedrTheme()
}
