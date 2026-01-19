//
//  ReaderControlsView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SPEED CONTROLS"
//  Reference: RESOURCES.md - Section 2 (Liquid Glass)
//
//  Controls layout:
//  ┌──────┐ ┌────────────────┐ ┌──────┐
//  │  ⏪  │ │       ⏸        │ │  ⏩  │
//  │      │ │                │ │      │
//  └──────┘ └────────────────┘ └──────┘
//

import SwiftUI

/// Reader control buttons (speed down, play/pause, speed up)
struct ReaderControlsView: View {
    @Bindable var viewModel: ReaderViewModel

    /// Called when speed limit is hit (for showing paywall)
    var onSpeedLimitReached: (() -> Void)?

    @Environment(\.theme) private var theme

    /// Timer for continuous speed adjustment on long press
    @State private var longPressTimer: Timer?

    var body: some View {
        HStack(spacing: 16) {
            // Speed Down Button
            SpeedButton(
                systemImage: "backward.fill",
                isEnabled: viewModel.canDecreaseSpeed
            ) {
                viewModel.decreaseSpeed()
            } onLongPressStart: {
                startContinuousDecrease()
            } onLongPressEnd: {
                stopContinuousAdjustment()
            }

            // Play/Pause Button (larger, central)
            PlayPauseButton(
                isPlaying: viewModel.isPlaying
            ) {
                viewModel.togglePlayPause()
            }

            // Speed Up Button
            SpeedButton(
                systemImage: "forward.fill",
                isEnabled: viewModel.canIncreaseSpeed
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

// MARK: - Speed Button

/// Button for speed up/down with long press support
struct SpeedButton: View {
    let systemImage: String
    let isEnabled: Bool
    let onTap: () -> Void
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    private let buttonSize: CGFloat = 60

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isEnabled ? theme.textPrimary : theme.textSecondary)
                .frame(width: buttonSize, height: buttonSize)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    guard isEnabled else { return }
                    isPressed = true
                    onLongPressStart()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        onLongPressEnd()
                    }
                }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
    }
}

// MARK: - Play/Pause Button

/// Central play/pause toggle button
struct PlayPauseButton: View {
    let isPlaying: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    private let buttonWidth: CGFloat = 120
    private let buttonHeight: CGFloat = 60

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(theme.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPlaying)
    }
}

// MARK: - WPM Display

/// Displays current reading speed
struct WPMDisplayView: View {
    let wpm: Int

    @Environment(\.theme) private var theme

    var body: some View {
        Text("\(wpm) wpm")
            .font(Typography.wpmDisplay)
            .foregroundColor(theme.textSecondary)
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

#Preview("Reader Controls") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ReaderControlsView(viewModel: ReaderViewModel.preview)

            WPMDisplayView(wpm: 300)

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

#Preview("Play/Pause States") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            PlayPauseButton(isPlaying: false) { }
            PlayPauseButton(isPlaying: true) { }
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
