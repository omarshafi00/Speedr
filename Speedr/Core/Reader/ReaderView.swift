//
//  ReaderView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "READER VIEW (Core Experience)"
//
//  Layout:
//  ┌─────────────────────────────────────────┐
//  │                                    ✕    │  ← Close button
//  │                                         │
//  │    ──────────────┬──────────────        │  ← Focal line (top)
//  │                  │                      │
//  │              pe[o]ple.                  │  ← Word display
//  │                  │                      │
//  │    ──────────────┴──────────────        │  ← Focal line (bottom)
//  │                                         │
//  │                           300 wpm       │  ← Speed indicator
//  │                                         │
//  │  ┌──────┐ ┌────────────────┐ ┌──────┐   │
//  │  │  ⏪  │ │       ⏸        │ │  ⏩  │   │  ← Controls
//  │  └──────┘ └────────────────┘ └──────┘   │
//  │                                         │
//  │  ════════════════════════════════════   │  ← Progress bar
//  │  Location: 45%              2 min left  │
//  └─────────────────────────────────────────┘
//

import SwiftUI

/// Full-screen RSVP reader view
struct ReaderView: View {
    /// The text content to read
    let text: String

    /// Optional document title
    var title: String?

    /// Optional document ID for tracking reading sessions
    var documentId: UUID?

    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// Reader state
    @State private var viewModel: ReaderViewModel

    /// StoreKit manager for subscription status
    @State private var storeKit = StoreKitManager.shared

    /// Preferences manager for user settings
    @State private var preferences = PreferencesManager.shared

    /// Paywall state
    @State private var showPaywall = false

    /// Paywall trigger reason
    @State private var paywallTrigger: PaywallTrigger = .speedLimit

    /// Completed state
    @State private var showCompletedOverlay = false

    /// Session tracking
    @State private var sessionStartTime: Date?
    @State private var sessionWordsRead: Int = 0
    @State private var sessionMaxWPM: Int = 0

    // MARK: - Initialization

    init(text: String, title: String? = nil, documentId: UUID? = nil) {
        self.text = text
        self.title = title
        self.documentId = documentId
        self._viewModel = State(initialValue: ReaderViewModel(text: text))
    }

    var body: some View {
        ZStack {
            // Background
            theme.background
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Top bar with close button
                topBar

                Spacer()

                // Focal point and word display area
                wordDisplayArea

                // WPM indicator
                wpmIndicator
                    .padding(.top, 24)

                Spacer()

                // Controls
                controlsSection

                // Progress bar
                progressSection
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, Constants.Layout.standardMargin)

            // Completed overlay
            if showCompletedOverlay {
                completedOverlay
            }
        }
        .onAppear {
            syncWithPreferences()
            startSession()
        }
        .onDisappear {
            endSession()
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCompletedOverlay = true
                }
                endSession()
            }
        }
        .onChange(of: storeKit.isPro) { _, isPro in
            viewModel.isPro = isPro
        }
        .onChange(of: preferences.highlightColor) { _, newColor in
            viewModel.highlightColor = newColor
        }
        .onChange(of: preferences.fontSize) { _, newSize in
            viewModel.fontSizeMultiplier = newSize
        }
        .onChange(of: viewModel.wpm) { _, newWPM in
            // Track max WPM during session
            if newWPM > sessionMaxWPM {
                sessionMaxWPM = newWPM
            }
        }
        .onChange(of: viewModel.currentIndex) { oldIndex, newIndex in
            // Track words read during session
            if newIndex > oldIndex {
                sessionWordsRead += (newIndex - oldIndex)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: paywallTrigger)
        }
    }

    // MARK: - Preferences Sync

    private func syncWithPreferences() {
        viewModel.isPro = storeKit.isPro
        viewModel.highlightColor = preferences.highlightColor
        viewModel.fontSizeMultiplier = preferences.fontSize
    }

    // MARK: - Session Tracking

    private func startSession() {
        sessionStartTime = Date()
        sessionWordsRead = 0
        sessionMaxWPM = viewModel.wpm
    }

    private func endSession() {
        guard let startTime = sessionStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)

        // Only save session if user read for more than 5 seconds
        guard duration > 5, sessionWordsRead > 0 else { return }

        // Update statistics in preferences
        preferences.totalWordsRead += sessionWordsRead
        preferences.totalReadingTime += duration
        preferences.totalSessions += 1

        // Reset session tracking
        sessionStartTime = nil
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Title (optional)
            if let title = title {
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Close button
            Button {
                viewModel.pause()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(theme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Word Display Area

    private var wordDisplayArea: some View {
        ZStack {
            // Focal point lines
            FocalPointOverlay()

            // Current word
            Text(styledCurrentWord)
                .font(Typography.readerWord(size: viewModel.fontSize))
                .offset(x: currentWordOffset)
                .id(viewModel.currentIndex) // For animation
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.05), value: viewModel.currentIndex)
        }
        .frame(height: FocalPointConfig().totalHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.togglePlayPause()
        }
    }

    private var styledCurrentWord: AttributedString {
        TextProcessor.createStyledWord(
            viewModel.currentWord,
            highlightColor: viewModel.highlightColor,
            baseColor: theme.textPrimary
        )
    }

    private var currentWordOffset: CGFloat {
        TextProcessor.calculateWordOffset(
            word: viewModel.currentWord,
            fontSize: viewModel.fontSize
        )
    }

    // MARK: - WPM Indicator

    private var wpmIndicator: some View {
        HStack {
            Spacer()
            WPMDisplayView(wpm: viewModel.wpm)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        ReaderControlsView(viewModel: viewModel) {
            // Speed limit reached - show paywall
            paywallTrigger = .speedLimit
            showPaywall = true
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        ReaderProgressBar(
            progress: viewModel.progress,
            progressText: viewModel.progressPercentage,
            timeRemaining: viewModel.timeRemainingFormatted
        )
    }

    // MARK: - Completed Overlay

    private var completedOverlay: some View {
        ZStack {
            // Dimmed background
            theme.background.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Checkmark icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                // Completed text
                Text("Reading Complete!")
                    .font(Typography.headline)
                    .foregroundColor(theme.textPrimary)

                // Stats
                VStack(spacing: 8) {
                    Text("\(viewModel.totalWords) words")
                        .font(Typography.body)
                        .foregroundColor(theme.textSecondary)

                    Text("at \(viewModel.wpm) WPM")
                        .font(Typography.body)
                        .foregroundColor(theme.textSecondary)
                }

                // Buttons
                VStack(spacing: 12) {
                    // Read Again
                    Button {
                        withAnimation {
                            showCompletedOverlay = false
                        }
                        viewModel.restart()
                    } label: {
                        Text("Read Again")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.Layout.buttonHeight)
                            .background(theme.accentBlue)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }

                    // Done
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.Layout.buttonHeight)
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Previews

#Preview("Reader View") {
    ReaderView(
        text: "Welcome to Speedr. Right now, you are reading faster than most people. This is called RSVP. Rapid Serial Visual Presentation. Instead of moving your eyes across a page, words come to you.",
        title: "Demo"
    )
    .speedrTheme()
}

#Preview("Reader - Playing") {
    ReaderView(text: "The quick brown fox jumps over the lazy dog.")
        .speedrTheme()
}

#Preview("Reader - Dark Mode") {
    ReaderView(
        text: "Focus on the red letter. It helps your brain find the center of each word instantly."
    )
    .speedrTheme()
    .preferredColorScheme(.dark)
}
