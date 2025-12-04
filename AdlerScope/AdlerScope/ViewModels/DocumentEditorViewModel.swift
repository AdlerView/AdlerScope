//
//  DocumentEditorViewModel.swift
//  AdlerScope
//
//  Centralized document editing state management
//  Uses @Observable pattern (Swift 5.9+)
//

import SwiftUI
import SwiftData
import Observation
import OSLog

private let logger = Logger(subsystem: "org.advision.AdlerScope", category: "DocumentEditor")

@Observable
final class DocumentEditorViewModel {

    // MARK: - Published State

    var selectedDocument: RecentDocument?
    var currentFileDocument = MarkdownFileDocument()
    var currentDocumentURL: URL?
    var hasUnsavedChanges = false
    var isLoadingDocument = false
    var loadError: DocumentLoadError?
    var alertError: AlertError?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let fileSystemService: FileSystemService
    @ObservationIgnored private var autoSaveTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var canSave: Bool {
        hasUnsavedChanges && currentDocumentURL != nil
    }

    var documentTitle: String {
        selectedDocument?.displayName ?? "No Document"
    }

    var documentSubtitle: String {
        currentDocumentURL?.path ?? ""
    }

    // MARK: - Initialization

    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
        self.fileSystemService = .shared
    }

    // MARK: - Document Operations

    func loadDocument(_ recentDoc: RecentDocument) async {
        logger.info("Loading document: \(recentDoc.displayName)")
        isLoadingDocument = true
        loadError = nil

        defer { isLoadingDocument = false }

        do {
            // Resolve bookmark (ViewModel is on MainActor)
            let url = try recentDoc.resolveBookmark()

            // File I/O off main thread
            let content = try await fileSystemService.loadDocument(from: url)

            currentFileDocument = MarkdownFileDocument(content: content)
            currentDocumentURL = url
            hasUnsavedChanges = false

            // Update metadata
            recentDoc.lastOpened = Date()
            recentDoc.updateMetadata()

            logger.info("Document loaded successfully: \(content.count) characters")

        } catch let error as DocumentLoadError {
            logger.error("Failed to load document: \(error.localizedDescription)")
            loadError = error
            alertError = AlertError(from: error)
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            let wrappedError = DocumentLoadError.unknown(error)
            loadError = wrappedError
            alertError = AlertError(from: wrappedError)
        }
    }

    func saveDocument() async {
        guard let url = currentDocumentURL else {
            alertError = AlertError(
                title: "Cannot Save",
                message: "No document URL is available"
            )
            return
        }

        logger.info("Saving document: \(url.lastPathComponent)")

        do {
            try await fileSystemService.saveDocument(
                content: currentFileDocument.content,
                to: url
            )

            hasUnsavedChanges = false
            selectedDocument?.updateMetadata()

            logger.info("Document saved successfully")

        } catch let error as DocumentLoadError {
            logger.error("Failed to save: \(error.localizedDescription)")
            alertError = AlertError(from: error)
        } catch {
            logger.error("Unexpected save error: \(error.localizedDescription)")
            alertError = AlertError(
                title: "Save Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Auto-Save

    func scheduleAutoSave() {
        autoSaveTask?.cancel()

        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await saveDocument()
        }
    }

    func contentDidChange() {
        guard currentDocumentURL != nil else { return }
        hasUnsavedChanges = true
        scheduleAutoSave()
    }

    // MARK: - Document Management

    func toggleFavorite(_ document: RecentDocument) {
        #if DEBUG
        logger.debug("Toggling favorite for: \(document.displayName)")
        #endif
        document.isFavorite.toggle()
    }

    func removeDocument(_ document: RecentDocument) {
        logger.info("Removing document: \(document.displayName)")
        modelContext.delete(document)

        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
    }

    func addToRecents(_ url: URL) {
        logger.info("Adding to recents: \(url.lastPathComponent)")

        do {
            // Use FetchDescriptor (BackyardBirds Pattern)
            if let existing = try RecentDocument.find(url: url, in: modelContext) {
                existing.lastOpened = Date()
                selectedDocument = existing
                #if DEBUG
                logger.debug("Updated existing document")
                #endif
                return
            }

            // Create new
            let document = RecentDocument(url: url)
            _ = document.createBookmark()
            document.updateMetadata()

            modelContext.insert(document)
            selectedDocument = document

            logger.info("Created new recent document")

        } catch {
            logger.error("Failed to add to recents: \(error.localizedDescription)")
            alertError = AlertError(
                title: "Database Error",
                message: "Failed to add document to recents: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Cleanup

    func reset() {
        #if DEBUG
        logger.debug("Resetting document state")
        #endif
        currentFileDocument = MarkdownFileDocument()
        currentDocumentURL = nil
        hasUnsavedChanges = false
        loadError = nil
        alertError = nil
        autoSaveTask?.cancel()
    }

    deinit {
        autoSaveTask?.cancel()
    }
}

