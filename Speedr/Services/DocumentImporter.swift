//
//  DocumentImporter.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "DocumentImporter"
//  Reference: RESOURCES.md - Section 5 (FileImporter, PDFKit)
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Handles importing documents from various file formats
final class DocumentImporter {

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case fileAccessDenied
        case unsupportedFormat
        case emptyContent
        case pdfExtractionFailed
        case readFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileAccessDenied:
                return "Unable to access the file. Please try again."
            case .unsupportedFormat:
                return "This file format is not supported. Please use PDF or TXT files."
            case .emptyContent:
                return "The file appears to be empty."
            case .pdfExtractionFailed:
                return "Unable to extract text from the PDF."
            case .readFailed(let error):
                return "Failed to read file: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Supported Types

    /// Supported content types for import
    static let supportedTypes: [UTType] = [.plainText, .pdf]

    // MARK: - Import Methods

    /// Import a document from a URL
    /// - Parameter url: File URL to import
    /// - Returns: A new Document with the file content
    static func importDocument(from url: URL) async throws -> Document {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Determine file type and extract content
        let content: String

        if url.pathExtension.lowercased() == "pdf" {
            content = try extractTextFromPDF(url: url)
        } else if url.pathExtension.lowercased() == "txt" {
            content = try extractTextFromTXT(url: url)
        } else {
            // Try to read as plain text
            content = try extractTextFromTXT(url: url)
        }

        // Validate content
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw ImportError.emptyContent
        }

        // Create document
        let title = url.deletingPathExtension().lastPathComponent
        let document = Document(
            title: title,
            content: trimmedContent,
            sourceURL: url.absoluteString
        )

        return document
    }

    // MARK: - Text Extraction

    /// Extract text from a plain text file
    private static func extractTextFromTXT(url: URL) throws -> String {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            // Try other encodings
            if let content = try? String(contentsOf: url, encoding: .ascii) {
                return content
            }
            if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                return content
            }
            throw ImportError.readFailed(error)
        }
    }

    /// Extract text from a PDF file
    private static func extractTextFromPDF(url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ImportError.pdfExtractionFailed
        }

        var fullText = ""

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            if let pageText = page.string {
                fullText += pageText
                fullText += "\n\n" // Add spacing between pages
            }
        }

        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyContent
        }

        return fullText
    }

    // MARK: - Validation

    /// Check if a URL points to a supported file type
    static func isSupported(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "pdf" || ext == "txt"
    }

    /// Get the document type for a URL
    static func documentType(for url: URL) -> DocumentType? {
        let ext = url.pathExtension.lowercased()
        return DocumentType(rawValue: ext)
    }
}

// MARK: - Import Result

/// Result of a document import operation
struct ImportResult {
    let document: Document?
    let error: Error?

    var isSuccess: Bool {
        document != nil && error == nil
    }

    static func success(_ document: Document) -> ImportResult {
        ImportResult(document: document, error: nil)
    }

    static func failure(_ error: Error) -> ImportResult {
        ImportResult(document: nil, error: error)
    }
}

// MARK: - Batch Import

extension DocumentImporter {
    /// Import multiple documents from URLs
    /// - Parameter urls: Array of file URLs to import
    /// - Returns: Array of import results
    static func importDocuments(from urls: [URL]) async -> [ImportResult] {
        var results: [ImportResult] = []

        for url in urls {
            do {
                let document = try await importDocument(from: url)
                results.append(.success(document))
            } catch {
                results.append(.failure(error))
            }
        }

        return results
    }
}
