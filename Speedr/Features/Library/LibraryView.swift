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

    /// Add document action sheet
    @State private var showAddOptions = false

    /// Plain text input sheet
    @State private var showPlainTextInput = false

    /// Web link input sheet
    @State private var showWebLinkInput = false

    /// Paste from clipboard
    @State private var pastedText: String = ""

    /// Number of user-imported documents (excluding built-in)
    private var userDocumentCount: Int {
        documents.filter { !$0.isBuiltIn }.count
    }

    /// Whether user can import more documents
    private var canImportMoreDocuments: Bool {
        storeKit.isPro || userDocumentCount < Constants.Limits.freeMaxDocuments
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
                    documentId: document.id,
                    startPosition: document.currentPosition
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .documentLimit)
            }
            .sheet(isPresented: $showPlainTextInput) {
                PlainTextInputSheet { text, title in
                    createDocumentFromText(text, title: title)
                }
            }
            .sheet(isPresented: $showWebLinkInput) {
                WebLinkInputSheet { url in
                    fetchWebContent(from: url)
                }
            }
            .confirmationDialog("Add Document", isPresented: $showAddOptions, titleVisibility: .visible) {
                Button {
                    handlePasteFromClipboard()
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("Import File", systemImage: "doc.fill")
                }

                Button {
                    showPlainTextInput = true
                } label: {
                    Label("Enter Plain Text", systemImage: "text.alignleft")
                }

                Button {
                    showWebLinkInput = true
                } label: {
                    Label("Web Link", systemImage: "link")
                }

                // Note: Scan option requires VisionKit - showing as disabled/coming soon
                Button {
                    errorMessage = "Scan feature coming soon!"
                    showError = true
                } label: {
                    Label("Scan Document", systemImage: "doc.viewfinder")
                }

                Button("Cancel", role: .cancel) { }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Web Content Fetching

    private func fetchWebContent(from url: URL) {
        isImporting = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                // Try to extract text from HTML or use raw text
                let text: String
                if let htmlString = String(data: data, encoding: .utf8) {
                    text = extractTextFromHTML(htmlString)
                } else {
                    text = String(data: data, encoding: .utf8) ?? ""
                }

                guard !text.isEmpty else {
                    throw NSError(domain: "LibraryView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not extract text from URL"])
                }

                await MainActor.run {
                    let title = url.host ?? "Web Article"
                    createDocumentFromText(text, title: title)
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch: \(error.localizedDescription)"
                    showError = true
                    isImporting = false
                }
            }
        }
    }

    private func extractTextFromHTML(_ html: String) -> String {
        // Simple HTML to text extraction
        var text = html

        // Remove script and style tags with content
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)

        // Replace common block elements with newlines
        text = text.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</h[1-6]>", with: "\n\n", options: .regularExpression)

        // Remove remaining HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")

        // Clean up whitespace
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Add Document Handler

    private func handleAddDocument() {
        if canImportMoreDocuments {
            showAddOptions = true
        } else {
            showPaywall = true
        }
    }

    private func handlePasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string, !clipboardText.isEmpty {
            createDocumentFromText(clipboardText, title: "Pasted Text")
        } else {
            errorMessage = "No text found in clipboard"
            showError = true
        }
    }

    private func createDocumentFromText(_ text: String, title: String) {
        let document = Document(
            title: title,
            content: text
        )
        modelContext.insert(document)
        try? modelContext.save()

        // Open the document for reading
        selectedDocument = document
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
                if !storeKit.isPro && userDocumentCount >= Constants.Limits.freeMaxDocuments {
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
                Text("(\(count)/\(Constants.Limits.freeMaxDocuments))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(count >= Constants.Limits.freeMaxDocuments ? .orange : theme.textSecondary)
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

// MARK: - Plain Text Input Sheet

struct PlainTextInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var title = ""
    @State private var content = ""

    let onCreate: (String, String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Title field
                    TextField("Document Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    // Content area
                    TextEditor(text: $content)
                        .scrollContentBackground(.hidden)
                        .background(theme.surface)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Paste or type your text here...")
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding(.vertical)
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let documentTitle = title.isEmpty ? "Untitled" : title
                        onCreate(content, documentTitle)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Web Link Input Sheet

struct WebLinkInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var urlString = ""

    let onFetch: (URL) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter a web URL to import its text content")
                            .font(Typography.body)
                            .foregroundColor(theme.textSecondary)

                        TextField("https://example.com/article", text: $urlString)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Import from Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fetch") {
                        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
                            urlStr = "https://" + urlStr
                        }
                        if let url = URL(string: urlStr) {
                            onFetch(url)
                            dismiss()
                        }
                    }
                    .disabled(!isValidURL)
                }
            }
        }
    }

    private var isValidURL: Bool {
        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlStr.isEmpty { return false }
        if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
            urlStr = "https://" + urlStr
        }
        return URL(string: urlStr) != nil
    }
}

#Preview {
    LibraryView()
        .speedrTheme()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Document.self, ReadingSession.self], inMemory: true)
}

#Preview("Plain Text Input") {
    PlainTextInputSheet { text, title in
        print("Created: \(title)")
    }
    .speedrTheme()
}

#Preview("Web Link Input") {
    WebLinkInputSheet { url in
        print("Fetch: \(url)")
    }
    .speedrTheme()
}
