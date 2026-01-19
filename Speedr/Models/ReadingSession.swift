//
//  ReadingSession.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Data Models" section
//

import Foundation
import SwiftData

/// Records a single reading session for statistics
@Model
final class ReadingSession: Identifiable {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// ID of the document that was read
    var documentId: UUID

    /// When the session occurred
    var date: Date

    /// Number of words read in this session
    var wordsRead: Int

    /// Duration of the session in seconds
    var duration: TimeInterval

    /// Average WPM during the session
    var averageWPM: Int

    /// Maximum WPM reached during the session
    var maxWPM: Int

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        documentId: UUID,
        date: Date = Date(),
        wordsRead: Int,
        duration: TimeInterval,
        averageWPM: Int,
        maxWPM: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.date = date
        self.wordsRead = wordsRead
        self.duration = duration
        self.averageWPM = averageWPM
        self.maxWPM = maxWPM
    }

    // MARK: - Computed Properties

    /// Formatted duration string
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    /// Formatted date string
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Session Builder

/// Helper to build a reading session from reader state
struct ReadingSessionBuilder: Sendable {
    let documentId: UUID
    let startTime: Date
    let wordsReadStart: Int
    var wpmSamples: [Int] = []

    init(documentId: UUID, startPosition: Int) {
        self.documentId = documentId
        self.startTime = Date()
        self.wordsReadStart = startPosition
    }

    /// Record a WPM sample
    mutating func recordWPM(_ wpm: Int) {
        wpmSamples.append(wpm)
    }

    /// Build the final session
    func build(endPosition: Int) -> ReadingSession {
        let wordsRead = max(0, endPosition - wordsReadStart)
        let duration = Date().timeIntervalSince(startTime)
        let averageWPM = wpmSamples.isEmpty ? 300 : wpmSamples.reduce(0, +) / wpmSamples.count
        let maxWPM = wpmSamples.max() ?? 300

        return ReadingSession(
            documentId: documentId,
            wordsRead: wordsRead,
            duration: duration,
            averageWPM: averageWPM,
            maxWPM: maxWPM
        )
    }
}
