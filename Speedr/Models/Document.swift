//
//  Document.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Data Models" section
//

import Foundation
import SwiftData

/// Represents a document that can be read in Speedr
@Model
final class Document {
    /// Unique identifier
    var id: UUID

    /// Document title (filename or custom name)
    var title: String

    /// Full text content of the document
    var content: String

    /// Total number of words in the document
    var wordCount: Int

    /// Current reading position (word index where user stopped)
    var currentPosition: Int

    /// Date the document was added
    var dateAdded: Date

    /// Last time the document was read
    var lastRead: Date?

    /// Whether the user has completed reading this document
    var isCompleted: Bool

    /// Whether this is a built-in sample document
    var isBuiltIn: Bool

    /// Original file URL (for imported documents)
    var sourceURL: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        wordCount: Int? = nil,
        currentPosition: Int = 0,
        dateAdded: Date = Date(),
        lastRead: Date? = nil,
        isCompleted: Bool = false,
        isBuiltIn: Bool = false,
        sourceURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.wordCount = wordCount ?? TextProcessor.splitIntoWords(content).count
        self.currentPosition = currentPosition
        self.dateAdded = dateAdded
        self.lastRead = lastRead
        self.isCompleted = isCompleted
        self.isBuiltIn = isBuiltIn
        self.sourceURL = sourceURL
    }

    // MARK: - Computed Properties

    /// Reading progress as a value from 0.0 to 1.0
    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(currentPosition) / Double(wordCount)
    }

    /// Progress as percentage integer (0-100)
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// Number of words remaining
    var wordsRemaining: Int {
        max(0, wordCount - currentPosition)
    }

    /// Estimated time remaining at a given WPM
    func timeRemaining(at wpm: Int) -> TimeInterval {
        TextProcessor.estimatedReadingTime(wordCount: wordsRemaining, wpm: wpm)
    }

    /// Formatted time remaining string
    func timeRemainingFormatted(at wpm: Int = Constants.Reader.defaultWPM) -> String {
        TextProcessor.formatReadingTime(timeRemaining(at: wpm))
    }

    // MARK: - Methods

    /// Update reading position
    func updatePosition(_ position: Int) {
        currentPosition = min(position, wordCount)
        lastRead = Date()
        isCompleted = currentPosition >= wordCount - 1
    }

    /// Reset reading progress
    func resetProgress() {
        currentPosition = 0
        isCompleted = false
    }

    /// Mark as completed
    func markCompleted() {
        currentPosition = wordCount
        isCompleted = true
        lastRead = Date()
    }
}

// MARK: - Sample Document Factory

extension Document {
    /// Create the built-in sample document
    static func createSampleDocument() -> Document {
        Document(
            title: SampleTexts.demoTitle,
            content: SampleTexts.demo,
            isBuiltIn: true
        )
    }
}

// MARK: - Identifiable & Hashable

extension Document: Identifiable {}

// MARK: - Document Type

/// Supported document types for import
enum DocumentType: String, CaseIterable {
    case txt = "txt"
    case pdf = "pdf"

    var displayName: String {
        switch self {
        case .txt: return "Text File"
        case .pdf: return "PDF Document"
        }
    }

    var icon: String {
        switch self {
        case .txt: return "doc.text"
        case .pdf: return "doc.richtext"
        }
    }
}
