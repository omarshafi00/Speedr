//
//  DocumentRow.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "LIBRARY TAB" section
//

import SwiftUI

/// A single row in the document list
struct DocumentRow: View {
    let document: Document
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Document icon
                documentIcon

                // Document info
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(document.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)

                    // Subtitle (word count & status)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Progress indicator
                progressIndicator

                // Play button
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentBlue)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, Constants.Layout.standardMargin)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Components

    private var documentIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.background)
                .frame(width: 44, height: 44)

            Image(systemName: document.isBuiltIn ? "bolt.fill" : "doc.text.fill")
                .font(.system(size: 20))
                .foregroundColor(document.isBuiltIn ? theme.accentBlue : theme.textSecondary)
        }
    }

    private var subtitle: String {
        let wordCount = "\(document.wordCount.formatted()) words"

        if document.isCompleted {
            return "\(wordCount) • Completed"
        } else if document.currentPosition > 0 {
            let timeLeft = document.timeRemainingFormatted()
            return "\(wordCount) • \(timeLeft) left"
        } else {
            return wordCount
        }
    }

    private var progressIndicator: some View {
        Text("\(document.progressPercentage)%")
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundColor(progressColor)
    }

    private var progressColor: Color {
        if document.isCompleted {
            return .green
        } else if document.progress > 0 {
            return theme.accentBlue
        } else {
            return theme.textSecondary
        }
    }
}

// MARK: - Compact Row

/// A more compact version of the document row
struct CompactDocumentRow: View {
    let document: Document
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: document.isBuiltIn ? "bolt.fill" : "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(document.isBuiltIn ? theme.accentBlue : theme.textSecondary)
                    .frame(width: 24)

                // Title
                Text(document.title)
                    .font(Typography.body)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)

                Spacer()

                // Progress
                if document.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Text("\(document.progressPercentage)%")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Card

/// A card-style document display for featured items
struct DocumentCard: View {
    let document: Document
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: document.isBuiltIn ? "bolt.fill" : "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(document.isBuiltIn ? theme.accentBlue : theme.textSecondary)

                    Spacer()

                    if document.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(Typography.caption)
                            .foregroundColor(.green)
                    }
                }

                // Title
                Text(document.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.background)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(document.isCompleted ? Color.green : theme.accentBlue)
                            .frame(width: geometry.size.width * document.progress, height: 4)
                    }
                }
                .frame(height: 4)

                // Footer
                HStack {
                    Text("\(document.wordCount.formatted()) words")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)

                    Spacer()

                    Text("\(document.progressPercentage)%")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(Constants.Layout.cardPadding)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Document Row") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 12) {
            DocumentRow(
                document: Document(
                    title: "Sample Text",
                    content: "Test content here",
                    wordCount: 823,
                    currentPosition: 823,
                    isCompleted: true,
                    isBuiltIn: true
                )
            ) { }

            DocumentRow(
                document: Document(
                    title: "My Document.pdf",
                    content: "Test content here",
                    wordCount: 2340,
                    currentPosition: 1053
                )
            ) { }

            DocumentRow(
                document: Document(
                    title: "New Book",
                    content: "Test content here",
                    wordCount: 5000
                )
            ) { }
        }
        .padding()
    }
    .speedrTheme()
}

#Preview("Document Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        DocumentCard(
            document: Document(
                title: "Welcome to Speedr",
                content: SampleTexts.demo,
                isBuiltIn: true
            )
        ) { }
        .padding()
    }
    .speedrTheme()
}
