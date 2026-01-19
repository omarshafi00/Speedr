//
//  PersistenceManager.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "PersistenceManager"
//  Reference: RESOURCES.md - Section 6 (SwiftData, AppStorage)
//

import Foundation
import SwiftData
import SwiftUI

/// Manages data persistence using SwiftData
@MainActor
final class PersistenceManager {

    // MARK: - Singleton

    static let shared = PersistenceManager()

    // MARK: - Model Container

    let container: ModelContainer

    /// Main model context
    var context: ModelContext {
        container.mainContext
    }

    // MARK: - Initialization

    private init() {
        let schema = Schema([
            Document.self,
            ReadingSession.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: configuration)
            ensureSampleDocumentExists()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Sample Document

    /// Ensure the sample document exists in the database
    private func ensureSampleDocumentExists() {
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )

        do {
            let existingSamples = try context.fetch(descriptor)
            if existingSamples.isEmpty {
                let sample = Document.createSampleDocument()
                context.insert(sample)
                try context.save()
            }
        } catch {
            print("Error checking for sample document: \(error)")
        }
    }

    // MARK: - Document Operations

    /// Fetch all documents
    func fetchDocuments() -> [Document] {
        let descriptor = FetchDescriptor<Document>(
            sortBy: [SortDescriptor(\.lastRead, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching documents: \(error)")
            return []
        }
    }

    /// Fetch user documents (excluding built-in)
    func fetchUserDocuments() -> [Document] {
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isBuiltIn == false },
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching user documents: \(error)")
            return []
        }
    }

    /// Get the sample document
    func getSampleDocument() -> Document? {
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Error fetching sample document: \(error)")
            return nil
        }
    }

    /// Count user documents
    func userDocumentCount() -> Int {
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isBuiltIn == false }
        )

        do {
            return try context.fetchCount(descriptor)
        } catch {
            print("Error counting documents: \(error)")
            return 0
        }
    }

    /// Add a new document
    func addDocument(_ document: Document) throws {
        context.insert(document)
        try context.save()
    }

    /// Delete a document
    func deleteDocument(_ document: Document) throws {
        // Don't allow deleting built-in documents
        guard !document.isBuiltIn else { return }

        context.delete(document)
        try context.save()
    }

    /// Update document reading position
    func updateDocumentPosition(_ document: Document, position: Int) throws {
        document.updatePosition(position)
        try context.save()
    }

    // MARK: - Reading Session Operations

    /// Save a reading session
    func saveSession(_ session: ReadingSession) throws {
        context.insert(session)
        try context.save()

        // Also update preferences stats
        PreferencesManager.shared.recordSession(
            wordsRead: session.wordsRead,
            duration: session.duration
        )
    }

    /// Fetch all reading sessions
    func fetchSessions() -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }

    /// Fetch sessions for a specific document
    func fetchSessions(for documentId: UUID) -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.documentId == documentId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching document sessions: \(error)")
            return []
        }
    }

    // MARK: - Statistics

    /// Get total words read across all sessions
    func totalWordsRead() -> Int {
        let sessions = fetchSessions()
        return sessions.reduce(0) { $0 + $1.wordsRead }
    }

    /// Get total reading time across all sessions
    func totalReadingTime() -> TimeInterval {
        let sessions = fetchSessions()
        return sessions.reduce(0) { $0 + $1.duration }
    }

    /// Get average WPM across all sessions
    func averageWPM() -> Int {
        let sessions = fetchSessions()
        guard !sessions.isEmpty else { return Constants.Reader.defaultWPM }
        let total = sessions.reduce(0) { $0 + $1.averageWPM }
        return total / sessions.count
    }

    /// Get maximum WPM ever achieved
    func maxWPMEverAchieved() -> Int {
        let sessions = fetchSessions()
        return sessions.map(\.maxWPM).max() ?? Constants.Reader.defaultWPM
    }

    // MARK: - Data Management

    /// Clear all user data (documents and sessions)
    func clearAllUserData() throws {
        // Delete all user documents
        let userDocs = fetchUserDocuments()
        for doc in userDocs {
            context.delete(doc)
        }

        // Delete all sessions
        let sessions = fetchSessions()
        for session in sessions {
            context.delete(session)
        }

        // Reset sample document progress
        if let sample = getSampleDocument() {
            sample.resetProgress()
        }

        try context.save()

        // Reset preferences stats
        PreferencesManager.shared.resetStatistics()
    }
}

// MARK: - Environment Key

private struct PersistenceManagerKey: EnvironmentKey {
    static let defaultValue = PersistenceManager.shared
}

extension EnvironmentValues {
    var persistenceManager: PersistenceManager {
        get { self[PersistenceManagerKey.self] }
        set { self[PersistenceManagerKey.self] = newValue }
    }
}
