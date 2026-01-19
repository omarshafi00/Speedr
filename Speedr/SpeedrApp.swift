//
//  SpeedrApp.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - App entry point
//

import SwiftUI
import SwiftData

@main
struct SpeedrApp: App {
    /// SwiftData model container for persistence
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Document.self,
                ReadingSession.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: configuration)

            // Ensure sample document exists
            ensureSampleDocumentExists()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .speedrTheme()
                .preferredColorScheme(.dark) // Default to dark theme
        }
        .modelContainer(container)
    }

    /// Ensure the sample document exists in the database
    private func ensureSampleDocumentExists() {
        let context = container.mainContext

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
}
