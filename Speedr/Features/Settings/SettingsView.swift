//
//  SettingsView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SETTINGS TAB" section
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.theme) private var theme

    /// StoreKit manager for subscription status
    @State private var storeKit = StoreKitManager.shared

    /// Preferences manager
    @State private var preferences = PreferencesManager.shared

    /// Show paywall
    @State private var showPaywall = false

    /// Show paywall trigger
    @State private var paywallTrigger: PaywallTrigger = .proBanner

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                List {
                    // Pro Banner Section (only show if not Pro)
                    if !storeKit.isPro {
                        proBannerSection
                    } else {
                        proStatusSection
                    }

                    // Reader Section
                    readerSection

                    // Sound Section
                    soundSection

                    // Account Section
                    accountSection

                    // About Section
                    aboutSection

                    // Version
                    versionSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: paywallTrigger)
            }
        }
    }

    // MARK: - Pro Banner Section

    private var proBannerSection: some View {
        Section {
            Button {
                paywallTrigger = .proBanner
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(ThemeColors.highlightRed)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speedr Pro")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textPrimary)

                        Text("Unlimited speed & documents")
                            .font(Typography.caption)
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    Text("GET")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Pro Status Section

    private var proStatusSection: some View {
        Section {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Speedr Pro Active")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    if let expiration = storeKit.subscriptionStatus.expirationFormatted {
                        Text("Renews \(expiration)")
                            .font(Typography.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Reader Section

    private var readerSection: some View {
        Section("Reader") {
            // Highlight Color
            NavigationLink {
                ColorPickerView()
            } label: {
                HStack {
                    Label("Highlight Color", systemImage: "paintpalette.fill")

                    Spacer()

                    Circle()
                        .fill(preferences.highlightColor)
                        .frame(width: 24, height: 24)
                }
            }

            // Font Size
            NavigationLink {
                FontSizeSettingView()
            } label: {
                HStack {
                    Label("Font Size", systemImage: "textformat.size")

                    Spacer()

                    Text(fontSizeLabel)
                        .foregroundColor(theme.textSecondary)
                }
            }

            // Theme
            NavigationLink {
                ThemeSettingView()
            } label: {
                HStack {
                    Label("Theme", systemImage: "moon.fill")

                    Spacer()

                    Text(preferences.theme.displayName)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    private var fontSizeLabel: String {
        switch preferences.fontSize {
        case ...0.8: return "Small"
        case 0.8...1.1: return "Medium"
        case 1.1...1.3: return "Large"
        default: return "Extra Large"
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        Section("Sound") {
            Button {
                if storeKit.isPro {
                    // TODO: Open background music settings
                } else {
                    paywallTrigger = .musicFeature
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("Background Music", systemImage: "music.note")
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    if !storeKit.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            // Statistics
            NavigationLink {
                StatsView()
            } label: {
                Label("Statistics", systemImage: "chart.bar.fill")
            }

            // Restore Purchases
            Button {
                Task {
                    await storeKit.restorePurchases()
                }
            } label: {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    if storeKit.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(storeKit.isLoading)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            // Help & FAQ
            NavigationLink {
                HelpView()
            } label: {
                Label("Help & FAQ", systemImage: "questionmark.circle.fill")
            }

            // Rate App
            Button {
                requestAppReview()
            } label: {
                Label("Rate Speedr", systemImage: "star.fill")
                    .foregroundColor(theme.textPrimary)
            }
            .buttonStyle(.plain)

            // Share App
            ShareLink(item: URL(string: "https://apps.apple.com/app/speedr")!) {
                Label("Share Speedr", systemImage: "square.and.arrow.up.fill")
            }
        }
    }

    // MARK: - Version Section

    private var versionSection: some View {
        Section {
            HStack {
                Spacer()
                Text("Version 1.0.0")
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func requestAppReview() {
        // Request app review using StoreKit 2 API (iOS 16+)
        // Reference: RESOURCES.md - Section 3 (StoreKit 2)
        Task {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                await AppStore.requestReview(in: scene)
            }
        }
    }
}

// MARK: - Font Size Setting View

struct FontSizeSettingView: View {
    @Environment(\.theme) private var theme
    @State private var preferences = PreferencesManager.shared

    private let fontSizes: [(label: String, value: Double)] = [
        ("Small", 0.75),
        ("Medium", 1.0),
        ("Large", 1.25),
        ("Extra Large", 1.5)
    ]

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            List {
                // Preview
                Section {
                    VStack {
                        Text(previewWord)
                            .font(Typography.readerWord(size: 48 * preferences.fontSize))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }

                // Options
                Section {
                    ForEach(fontSizes, id: \.value) { option in
                        Button {
                            preferences.fontSize = option.value
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(theme.textPrimary)

                                Spacer()

                                if abs(preferences.fontSize - option.value) < 0.01 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.accentBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Font Size")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewWord: AttributedString {
        TextProcessor.createStyledWord(
            "Speedr",
            highlightColor: preferences.highlightColor,
            baseColor: theme.textPrimary
        )
    }
}

// MARK: - Theme Setting View

struct ThemeSettingView: View {
    @Environment(\.theme) private var theme
    @State private var preferences = PreferencesManager.shared

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            List {
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { themeOption in
                        Button {
                            preferences.theme = themeOption
                        } label: {
                            HStack {
                                Label(themeOption.displayName, systemImage: themeIcon(for: themeOption))
                                    .foregroundColor(theme.textPrimary)

                                Spacer()

                                if preferences.theme == themeOption {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.accentBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeIcon(for theme: AppTheme) -> String {
        switch theme {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.theme) private var theme

    private let faqs: [(question: String, answer: String)] = [
        ("What is RSVP reading?", "RSVP (Rapid Serial Visual Presentation) shows you one word at a time at a fixed point, eliminating eye movement and allowing faster reading."),
        ("What does the red letter mean?", "The red letter marks the Optimal Recognition Point (ORP) - the best position for your eye to focus on each word."),
        ("How fast can I read?", "Most people can comfortably read at 400-600 WPM with practice. Pro users can go up to 1500 WPM."),
        ("What file types are supported?", "Speedr supports PDF and TXT files. More formats coming soon!"),
        ("How do I import documents?", "Tap 'Import Document' on the home screen or use the + button in the Library tab."),
        ("Is my reading progress saved?", "Yes! Your progress is automatically saved for each document.")
    ]

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            List {
                ForEach(faqs, id: \.question) { faq in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(faq.question)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.textPrimary)

                            Text(faq.answer)
                                .font(Typography.body)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .speedrTheme()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Document.self, ReadingSession.self], inMemory: true)
}
