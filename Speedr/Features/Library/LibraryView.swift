//
//  LibraryView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "LIBRARY TAB" section
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    /// All documents from SwiftData
    @Query(sort: \Document.lastRead, order: .reverse) private var documents: [Document]

    /// StoreKit manager for subscription status
    @State private var storeKit = StoreKitManager.shared

    /// Search text
    @State private var searchText = ""

    /// File importer state
    @State private var showFileImporter = false

    /// Selected document for reading
    @State private var selectedDocument: Document?

    /// Paywall state
    @State private var showPaywall = false

    /// Error alert state
    @State private var showError = false
    @State private var errorMessage = ""

    /// Import in progress
    @State private var isImporting = false

    /// Number of user-imported documents (excluding built-in)
    private var userDocumentCount: Int {
        documents.filter { !$0.isBuiltIn }.count
    }

    /// Whether user can import more documents
    private var canImportMoreDocuments: Bool {
        storeKit.isPro || userDocumentCount < Constants.Limits.freeDocumentLimit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                if documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }

                // Loading overlay
                if isImporting {
                    importingOverlay
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        handleAddDocument()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: DocumentImporter.supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .fullScreenCover(item: $selectedDocument) { document in
                ReaderView(
                    text: document.content,
                    title: document.title,
                    documentId: document.id
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .documentLimit)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Add Document Handler

    private func handleAddDocument() {
        if canImportMoreDocuments {
            showFileImporter = true
        } else {
            showPaywall = true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Documents Yet",
            systemImage: "doc.text",
            description: Text("Import a document to start reading")
        )
    }

    // MARK: - Document List

    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Document limit banner (for free users)
                if !storeKit.isPro && userDocumentCount >= Constants.Limits.freeDocumentLimit {
                    documentLimitBanner
                }

                // My Documents Section
                if !filteredDocuments.isEmpty {
                    Section {
                        ForEach(filteredDocuments) { document in
                            DocumentRow(document: document) {
                                selectedDocument = document
                            }
                            .contextMenu {
                                documentContextMenu(for: document)
                            }
                        }
                    } header: {
                        sectionHeader("MY DOCUMENTS", count: userDocumentCount)
                    }
                }

                // Coming Soon Card
                comingSoonCard
                    .padding(.top, 8)
            }
            .padding(.horizontal, Constants.Layout.standardMargin)
            .padding(.vertical, 12)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Document Limit Banner

    private var documentLimitBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Document Limit Reached")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    Text("Upgrade to Pro for unlimited documents")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Text("UPGRADE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(12)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtered Documents

    private var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        }
        return documents.filter { document in
            document.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)

            // Show document count with limit info for free users
            if let count = count, !storeKit.isPro {
                Text("(\(count)/\(Constants.Limits.freeDocumentLimit))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(count >= Constants.Limits.freeDocumentLimit ? .orange : theme.textSecondary)
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func documentContextMenu(for document: Document) -> some View {
        Button {
            selectedDocument = document
        } label: {
            Label("Read", systemImage: "play.fill")
        }

        if document.currentPosition > 0 && !document.isCompleted {
            Button {
                document.resetProgress()
                try? modelContext.save()
            } label: {
                Label("Reset Progress", systemImage: "arrow.counterclockwise")
            }
        }

        if !document.isBuiltIn {
            Divider()

            Button(role: .destructive) {
                deleteDocument(document)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Coming Soon Card

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accentBlue)

                Text("COMING SOON")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.accentBlue)
            }

            Text("Book Library")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.textPrimary)

            Text("Thousands of books at your fingertips. Stay tuned!")
                .font(Typography.body)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Layout.cardPadding)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
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

    // MARK: - Actions

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
                    modelContext.insert(document)
                    try? modelContext.save()
                    isImporting = false
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

    private func deleteDocument(_ document: Document) {
        modelContext.delete(document)
        try? modelContext.save()
    }
}

#Preview {
    LibraryView()
        .speedrTheme()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Document.self, ReadingSession.self], inMemory: true)
}
