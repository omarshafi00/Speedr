//
//  StatsView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SETTINGS TAB" section
//

import SwiftUI
import SwiftData

/// View displaying reading statistics
struct StatsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    /// Reading sessions from SwiftData
    @Query(sort: \ReadingSession.date, order: .reverse) private var sessions: [ReadingSession]

    /// Preferences manager for stats
    @State private var preferences = PreferencesManager.shared

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Summary cards
                    summarySection

                    // Recent sessions
                    recentSessionsSection
                }
                .padding(Constants.Layout.standardMargin)
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Words Read",
                    value: formattedWordsRead,
                    icon: "text.word.spacing",
                    color: theme.accentBlue
                )

                StatCard(
                    title: "Reading Time",
                    value: formattedReadingTime,
                    icon: "clock.fill",
                    color: .green
                )

                StatCard(
                    title: "Sessions",
                    value: "\(sessions.count)",
                    icon: "book.fill",
                    color: .orange
                )

                StatCard(
                    title: "Avg Speed",
                    value: "\(averageWPM) WPM",
                    icon: "speedometer",
                    color: ThemeColors.highlightRed
                )
            }

            // Max speed card (full width)
            StatCard(
                title: "Fastest Speed",
                value: "\(maxWPM) WPM",
                icon: "bolt.fill",
                color: .yellow,
                isLarge: true
            )
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textSecondary)

                Spacer()

                if !sessions.isEmpty {
                    Text("\(sessions.count) total")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }

            if sessions.isEmpty {
                emptySessionsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sessions.prefix(10)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }

    private var emptySessionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(theme.textSecondary)

            Text("No reading sessions yet")
                .font(Typography.body)
                .foregroundColor(theme.textSecondary)

            Text("Start reading to track your progress")
                .font(Typography.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    // MARK: - Computed Stats

    private var totalWordsRead: Int {
        sessions.reduce(0) { $0 + $1.wordsRead }
    }

    private var formattedWordsRead: String {
        if totalWordsRead >= 1000000 {
            return String(format: "%.1fM", Double(totalWordsRead) / 1000000)
        } else if totalWordsRead >= 1000 {
            return String(format: "%.1fK", Double(totalWordsRead) / 1000)
        }
        return "\(totalWordsRead)"
    }

    private var totalReadingTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    private var formattedReadingTime: String {
        let hours = Int(totalReadingTime) / 3600
        let minutes = (Int(totalReadingTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var averageWPM: Int {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.averageWPM }
        return total / sessions.count
    }

    private var maxWPM: Int {
        sessions.map(\.maxWPM).max() ?? 0
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLarge: Bool = false

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 20 : 16))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: isLarge ? 28 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ReadingSession

    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)

                Text(formattedTime)
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.wordsRead)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Text("words")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.averageWPM)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.accentBlue)

                    Text("WPM")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: session.date)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.date)
    }
}

// MARK: - Previews

#Preview("Stats View") {
    NavigationStack {
        StatsView()
    }
    .speedrTheme()
    .preferredColorScheme(.dark)
    .modelContainer(for: [Document.self, ReadingSession.self], inMemory: true)
}
