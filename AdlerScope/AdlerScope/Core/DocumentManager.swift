//
//  DocumentManager.swift
//  AdlerScope
//
//  Manages document lifecycle for WindowGroup architecture
//  Handles file I/O, recent documents, and document state tracking
//

import Foundation
import SwiftUI
import Observation
import UniformTypeIdentifiers

/// Manages document state and file operations for WindowGroup
@Observable
class DocumentManager {
    // MARK: - Observable Properties

    /// Current document URL (nil for new unsaved documents)
    var currentDocumentURL: URL?

    /// Current markdown content
    var currentContent: String = ""

    /// Whether document has unsaved changes
    var hasUnsavedChanges: Bool = false

    /// Recent documents list
    var recentDocuments: [RecentDocumentInfo] = []

    /// Current document encoding
    var currentEncoding: String.Encoding = .utf8

    // MARK: - Dependencies

    private let documentRepository: DocumentRepository

    // MARK: - Initialization

    init(documentRepository: DocumentRepository) {
        self.documentRepository = documentRepository
    }

    // MARK: - File Operations

    /// Opens a document using NSOpenPanel
    /// - Returns: True if document was opened successfully
    @discardableResult
    func openDocument() async -> Bool {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a markdown file to open"

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return false
        }

        return await openDocument(from: url)
        #else
        return false
        #endif
    }

    /// Opens a document from a specific URL
    /// - Parameter url: URL of the document to open
    /// - Returns: True if document was opened successfully
    func openDocument(from url: URL) async -> Bool {
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Read document
            let (content, encoding) = try await documentRepository.read(from: url)

            // Update state
            currentContent = content
            currentDocumentURL = url
            currentEncoding = encoding
            hasUnsavedChanges = false

            // Add to recent documents
            addToRecentDocuments(url)

            return true
        } catch {
            print("Failed to open document: \(error)")
            return false
        }
    }

    /// Saves the current document
    /// - Returns: True if document was saved successfully
    @discardableResult
    func saveDocument() async -> Bool {
        guard let url = currentDocumentURL else {
            // No URL? Use Save As...
            return await saveDocumentAs()
        }

        return await saveDocument(to: url)
    }

    /// Saves the current document to a specific URL
    /// - Parameter url: URL to save to
    /// - Returns: True if document was saved successfully
    func saveDocument(to url: URL) async -> Bool {
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Write document
            try await documentRepository.write(currentContent, to: url, encoding: currentEncoding)

            // Update state
            currentDocumentURL = url
            hasUnsavedChanges = false

            // Add to recent documents
            addToRecentDocuments(url)

            return true
        } catch {
            print("Failed to save document: \(error)")
            return false
        }
    }

    /// Shows Save As panel and saves document
    /// - Returns: True if document was saved successfully
    @discardableResult
    func saveDocumentAs() async -> Bool {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText
        ]
        panel.nameFieldStringValue = currentDocumentURL?.lastPathComponent ?? "Untitled.md"
        panel.message = "Choose a location to save your markdown file"

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return false
        }

        return await saveDocument(to: url)
        #else
        return false
        #endif
    }

    /// Creates a new empty document
    func newDocument() {
        currentContent = ""
        currentDocumentURL = nil
        currentEncoding = .utf8
        hasUnsavedChanges = false
    }

    /// Updates document content and marks as having unsaved changes
    /// - Parameter content: New content
    func updateContent(_ content: String) {
        guard content != currentContent else { return }
        currentContent = content
        hasUnsavedChanges = true
    }

    // MARK: - Recent Documents

    /// Adds a document to the recent documents list
    /// - Parameter url: URL of the document
    private func addToRecentDocuments(_ url: URL) {
        let info = RecentDocumentInfo(
            url: url,
            lastOpened: Date(),
            displayName: url.lastPathComponent
        )

        // Remove existing entry if present
        recentDocuments.removeAll { $0.url == url }

        // Add to beginning
        recentDocuments.insert(info, at: 0)

        // Keep only last 10
        if recentDocuments.count > 10 {
            recentDocuments = Array(recentDocuments.prefix(10))
        }
    }

    /// Opens a recent document
    /// - Parameter info: Recent document info
    func openRecentDocument(_ info: RecentDocumentInfo) async {
        _ = await openDocument(from: info.url)
    }

    // MARK: - Window Title Helpers

    /// Returns the current window title
    var windowTitle: String {
        let filename = currentDocumentURL?.lastPathComponent ?? "Untitled"
        return hasUnsavedChanges ? "\(filename) •" : filename
    }

    /// Returns the current document path (for subtitle)
    var documentPath: String {
        currentDocumentURL?.deletingLastPathComponent().path ?? ""
    }
}

// MARK: - Recent Document Info

/// Information about a recent document
struct RecentDocumentInfo: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let lastOpened: Date
    let displayName: String

    static func == (lhs: RecentDocumentInfo, rhs: RecentDocumentInfo) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Environment Key

struct DocumentManagerKey: EnvironmentKey {
    static let defaultValue: DocumentManager? = nil
}

extension EnvironmentValues {
    var documentManager: DocumentManager? {
        get { self[DocumentManagerKey.self] }
        set { self[DocumentManagerKey.self] = newValue }
    }
}
