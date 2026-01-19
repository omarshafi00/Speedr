//
//  HomeView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "HOME TAB (Default)" section
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    /// Controls whether the reader is shown
    @State private var showReader = false

    /// Controls whether the file importer is shown
    @State private var showFileImporter = false

    /// Imported document to read
    @State private var importedDocument: Document?

    /// Error handling
    @State private var showError = false
    @State private var errorMessage = ""

    /// Import in progress
    @State private var isImporting = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App Icon placeholder
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.accentBlue)

                // Headline
                VStack(spacing: 8) {
                    Text("Ready to read")
                        .font(Typography.headline)
                        .foregroundColor(theme.textPrimary)
                    Text("faster?")
                        .font(Typography.headline)
                        .foregroundColor(theme.textPrimary)
                }

                // Subtitle
                Text("Most people read 200 words per minute.\nYou can do 3x that.")
                    .font(Typography.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Layout.standardMargin)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Primary CTA - Try Demo
                    Button {
                        showReader = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Try Demo")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Layout.buttonHeight)
                        .background(theme.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }

                    // Secondary CTA - Import Document
                    Button {
                        showFileImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Import Document")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Layout.buttonHeight)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }
                }
                .padding(.horizontal, Constants.Layout.standardMargin)

                Spacer()
                    .frame(height: 40)
            }

            // Loading overlay
            if isImporting {
                importingOverlay
            }
        }
        .fullScreenCover(isPresented: $showReader) {
            ReaderView(
                text: SampleTexts.demo,
                title: SampleTexts.demoTitle
            )
        }
        .fullScreenCover(item: $importedDocument) { document in
            ReaderView(
                text: document.content,
                title: document.title
            )
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: DocumentImporter.supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Importing Overlay

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Importing...")
                    .font(Typography.body)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - File Import Handling

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importDocument(from: url)

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func importDocument(from url: URL) {
        isImporting = true

        Task {
            do {
                let document = try await DocumentImporter.importDocument(from: url)
                await MainActor.run {
                    // Save to SwiftData
                    modelContext.insert(document)
                    try? modelContext.save()

                    isImporting = false

                    // Open reader with imported document
                    importedDocument = document
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isImporting = false
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .speedrTheme()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Document.self, ReadingSession.self], inMemory: true)
}
