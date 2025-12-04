//
//  ContentView.swift
//  AdlerScope
//
//  Main coordinator view with sidebar and editor
//  Manages document state and file operations
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog

struct ContentView: View {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "ContentView")

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(SettingsViewModel.self) private var settingsViewModel

    // MARK: - SwiftData Queries

    @Query(sort: \RecentDocument.lastOpened, order: .reverse)
    private var recentDocuments: [RecentDocument]

    // MARK: - Document State
    // Note: @SceneStorage persists the selected document ID per window across app restarts
    // This allows each window to remember which document it had open

    @SceneStorage("selectedDocumentID") private var selectedDocumentID: String?
    @State private var selectedDocument: RecentDocument?
    @State private var currentFileDocument: MarkdownFileDocument = MarkdownFileDocument()
    @State private var currentDocumentURL: URL?
    @State private var hasUnsavedChanges: Bool = false

    // MARK: - New Document State

    @State private var isEditingNewDocument: Bool = false

    // MARK: - Loading State

    @State private var isLoadingDocument = false
    @State private var loadError: Error?

    // MARK: - Auto-Save

    @State private var autoSaveTask: Task<Void, Never>?

    // MARK: - Error Handling

    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @State private var showUnsavedChangesAlert = false

    // MARK: - iOS Document Picker

    #if !os(macOS)
    @State private var showDocumentPicker = false
    @State private var showDocumentExporter = false
    #endif

    // MARK: - Body

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iPadOSLayout
        #endif
    }

    // MARK: - macOS Layout

    private var macOSLayout: some View {
        NavigationSplitView {
            RecentDocumentsSidebarView(
                selectedDocument: $selectedDocument,
                onOpenDocument: openDocument,
                onToggleFavorite: toggleFavorite,
                onRemoveDocument: removeDocument
            )
        } detail: {
            if let selected = selectedDocument {
                EditorContainerView(
                    document: selected,
                    currentFileDocument: $currentFileDocument,
                    currentDocumentURL: $currentDocumentURL,
                    hasUnsavedChanges: $hasUnsavedChanges,
                    isLoadingDocument: $isLoadingDocument,
                    loadError: $loadError,
                    parseMarkdownUseCase: dependencyContainer.parseMarkdownUseCase,
                    settingsViewModel: settingsViewModel,
                    onSave: saveDocument,
                    onRetry: { Task { await loadDocument(selected) } },
                    onRemove: { removeDocument(selected) }
                )
            } else if isEditingNewDocument {
                // New document editor without file association
                SplitEditorView(
                    document: $currentFileDocument,
                    parseMarkdownUseCase: dependencyContainer.parseMarkdownUseCase,
                    settingsViewModel: settingsViewModel
                )
                .focusedSceneValue(\.saveDocument) {
                    Task { await saveNewDocument() }
                }
                .focusedSceneValue(\.saveDocumentAs) {
                    Task { await saveAsNewFile() }
                }
                .focusedSceneValue(\.closeDocument) {
                    closeCurrentDocument()
                }
                .focusedSceneValue(\.hasUnsavedChanges, hasUnsavedChanges)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            Task { await saveNewDocument() }
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .disabled(!hasUnsavedChanges && currentDocumentURL != nil)
                        .help("Save document")
                    }
                }
            } else {
                EmptyStateView(
                    onOpenDocument: openDocument,
                    onNewDocument: createNewDocument
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorAlertMessage)
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Don't Save", role: .destructive) {
                selectedDocument = nil
                resetDocumentState()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    await saveDocument()
                    selectedDocument = nil
                    resetDocumentState()
                }
            }
        } message: {
            Text("Do you want to save the changes you made to this document?")
        }
        .onAppear {
            // Restore selected document from @SceneStorage on window open
            restoreSelectedDocument()
        }
        .onChange(of: selectedDocument) { old, new in
            // Persist selection to @SceneStorage for this window
            selectedDocumentID = new?.id.uuidString

            if let doc = new {
                Task { await loadDocument(doc) }
            } else {
                resetDocumentState()
            }
        }
        .onChange(of: currentFileDocument.content) { old, new in
            if old != new {
                hasUnsavedChanges = true
                // Only auto-save if document is already saved (has URL)
                if currentDocumentURL != nil {
                    scheduleAutoSave()
                }
            }
        }
        .onChange(of: NavigationService.shared.pendingAction) { _, action in
            handleNavigationAction(action)
        }
    }

    // MARK: - iPadOS Layout

    #if !os(macOS)
    private var iPadOSLayout: some View {
        Group {
            if let selected = selectedDocument {
                iPadEditorView(selected)
            } else if isEditingNewDocument {
                iPadNewDocumentView
            } else {
                iPadDocumentBrowserView
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(allowedTypes: [
                .plainText,
                UTType(filenameExtension: "md") ?? .plainText,
                UTType(filenameExtension: "markdown") ?? .plainText,
                UTType(filenameExtension: "rmd") ?? .plainText,
                UTType(filenameExtension: "qmd") ?? .plainText
            ]) { url in
                addToRecents(url)
            }
        }
        .sheet(isPresented: $showDocumentExporter) {
            DocumentExporter(
                content: currentFileDocument.content,
                defaultFilename: "Untitled.md"
            ) { url in
                // Add the saved document to recents
                addToRecents(url)
                // Update state
                currentDocumentURL = url
                hasUnsavedChanges = false
                isEditingNewDocument = false
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorAlertMessage)
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Don't Save", role: .destructive) {
                selectedDocument = nil
                resetDocumentState()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    await saveDocument()
                    selectedDocument = nil
                    resetDocumentState()
                }
            }
        } message: {
            Text("Do you want to save the changes you made to this document?")
        }
        .onAppear {
            restoreSelectedDocument()
        }
        .onChange(of: selectedDocument) { old, new in
            selectedDocumentID = new?.id.uuidString
            if let doc = new {
                Task { await loadDocument(doc) }
            } else {
                resetDocumentState()
            }
        }
        .onChange(of: currentFileDocument.content) { old, new in
            if currentDocumentURL != nil && old != new {
                hasUnsavedChanges = true
                scheduleAutoSave()
            }
        }
        .onChange(of: NavigationService.shared.pendingAction) { _, action in
            handleNavigationAction(action)
        }
    }

    @ViewBuilder
    private func iPadEditorView(_ document: RecentDocument) -> some View {
        NavigationStack {
            EditorContainerView(
                document: document,
                currentFileDocument: $currentFileDocument,
                currentDocumentURL: $currentDocumentURL,
                hasUnsavedChanges: $hasUnsavedChanges,
                isLoadingDocument: $isLoadingDocument,
                loadError: $loadError,
                parseMarkdownUseCase: dependencyContainer.parseMarkdownUseCase,
                settingsViewModel: settingsViewModel,
                onSave: saveDocument,
                onRetry: { Task { await loadDocument(document) } },
                onRemove: { removeDocument(document) }
            )
            .navigationTitle(document.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Documents") {
                        selectedDocument = nil
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await saveDocument() }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!hasUnsavedChanges)
                }
            }
        }
    }

    private var iPadDocumentBrowserView: some View {
        NavigationStack {
            List {
                if !recentDocuments.isEmpty {
                    Section("Recent Documents") {
                        ForEach(recentDocuments) { document in
                            Button {
                                selectedDocument = document
                            } label: {
                                iPadDocumentRow(document)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    removeDocument(document)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    toggleFavorite(document)
                                } label: {
                                    Label(
                                        document.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: document.isFavorite ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text",
                        description: Text("Open a markdown file to get started")
                    )
                }
            }
            .navigationTitle("AdlerScope")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        createNewDocument()
                    } label: {
                        Label("New", systemImage: "square.and.pencil")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openDocument()
                    } label: {
                        Label("Open", systemImage: "doc.badge.plus")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func iPadDocumentRow(_ document: RecentDocument) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(document.lastOpened.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let metadata = FileSystemService.shared.fileMetadata(at: document.url) {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(metadata.fileSizeFormatted)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var iPadNewDocumentView: some View {
        NavigationStack {
            MarkdownEditorView(
                document: $currentFileDocument,
                parseMarkdownUseCase: dependencyContainer.parseMarkdownUseCase,
                settingsViewModel: settingsViewModel
            )
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditingNewDocument = false
                        resetDocumentState()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await saveNewDocument() }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(currentFileDocument.content.isEmpty)
                }
            }
        }
    }
    #endif

    // MARK: - Document Loading

    @MainActor
    private func loadDocument(_ recentDoc: RecentDocument) async {
        isLoadingDocument = true
        loadError = nil

        defer {
            isLoadingDocument = false
        }

        do {
            // Resolve security-scoped bookmark
            let url = try recentDoc.resolveBookmark()

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw DocumentLoadError.fileNotAccessible(url)
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Load file content
            let content = try String(contentsOf: url, encoding: .utf8)

            // Update state
            currentFileDocument = MarkdownFileDocument(content: content)
            currentDocumentURL = url
            hasUnsavedChanges = false

            // Update recent document timestamp and metadata (while still accessing security-scoped resource)
            recentDoc.lastOpened = Date()

            // Donate intent for Siri suggestions
            Task {
                await OpenDocumentIntent.donate(for: recentDoc)
            }

            // Update metadata directly without resolving bookmark again (we already have access)
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            recentDoc.fileSize = resourceValues.fileSize.map { Int64($0) }
            recentDoc.fileModifiedDate = resourceValues.contentModificationDate

        } catch {
            Self.logger.error("Failed to load document: \(error, privacy: .public)")
            loadError = error
        }
    }

    // MARK: - Document Saving

    @MainActor
    private func saveDocument() async {
        guard let url = currentDocumentURL else {
            Self.logger.warning("No document URL available")
            return
        }

        do {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw DocumentLoadError.fileNotAccessible(url)
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Write content to file
            try currentFileDocument.content.write(to: url, atomically: true, encoding: .utf8)

            hasUnsavedChanges = false

            // Refresh bookmark (while still accessing security-scoped resource)
            if let recentDoc = selectedDocument {
                _ = recentDoc.createBookmark()  // Refresh bookmark with current security-scoped access

                // Update metadata directly without resolving bookmark (we already have access)
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                recentDoc.fileSize = resourceValues.fileSize.map { Int64($0) }
                recentDoc.fileModifiedDate = resourceValues.contentModificationDate
            }

        } catch {
            Self.logger.error("Failed to save document: \(error, privacy: .public)")
            errorAlertMessage = "Failed to save document: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    // MARK: - Auto-Save

    private func scheduleAutoSave() {
        // Cancel previous auto-save task
        autoSaveTask?.cancel()

        // Schedule new auto-save after 5 seconds
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(5))

            guard !Task.isCancelled else { return }

            await saveDocument()
        }
    }

    // MARK: - File Picker

    private func openDocument() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            UTType(filenameExtension: "rmd") ?? .plainText,
            UTType(filenameExtension: "qmd") ?? .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a markdown file to open"

        if panel.runModal() == .OK, let url = panel.url {
            addToRecents(url)
        }
        #else
        showDocumentPicker = true
        #endif
    }

    private func createNewDocument() {
        // Clear any selected document
        selectedDocument = nil

        // Create empty document
        currentFileDocument = MarkdownFileDocument(content: "# New Document\n\n")
        currentDocumentURL = nil
        hasUnsavedChanges = true

        // Enter new document mode
        isEditingNewDocument = true
    }

    @MainActor
    private func saveNewDocument() async {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText
        ]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Untitled.md"
        panel.message = "Save markdown document"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                // Save content to file
                try currentFileDocument.content.write(to: url, atomically: true, encoding: .utf8)

                // Add to recent documents
                addToRecents(url)

                // Update state
                currentDocumentURL = url
                hasUnsavedChanges = false
                isEditingNewDocument = false
            } catch {
                Self.logger.error("Failed to save document: \(error, privacy: .public)")
                errorAlertMessage = "Failed to save new document: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        #else
        // iOS: Show document exporter sheet
        showDocumentExporter = true
        #endif
    }

    @MainActor
    private func saveAsNewFile() async {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText
        ]
        panel.canCreateDirectories = true

        // If there's a current file, use its name as default
        if let currentURL = currentDocumentURL {
            panel.nameFieldStringValue = currentURL.lastPathComponent
            panel.directoryURL = currentURL.deletingLastPathComponent()
        } else {
            panel.nameFieldStringValue = "Untitled.md"
        }

        panel.message = "Save markdown document as..."

        if panel.runModal() == .OK, let url = panel.url {
            do {
                // Save content to new file
                try currentFileDocument.content.write(to: url, atomically: true, encoding: .utf8)

                // Add to recent documents
                addToRecents(url)

                // Update state
                currentDocumentURL = url
                hasUnsavedChanges = false
                isEditingNewDocument = false
            } catch {
                Self.logger.error("Failed to save document: \(error, privacy: .public)")
                errorAlertMessage = "Failed to save document as: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        #endif
    }

    private func closeCurrentDocument() {
        if hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            selectedDocument = nil
            resetDocumentState()
        }
    }

    private func addToRecents(_ url: URL) {
        // Check if already exists
        if let existing = recentDocuments.first(where: { $0.url == url }) {
            existing.lastOpened = Date()
            selectedDocument = existing
            return
        }

        // Create new recent document
        let document = RecentDocument(url: url)
        _ = document.createBookmark()  // Create security-scoped bookmark
        document.updateMetadata()      // Fetch file size and mod date

        modelContext.insert(document)

        // Select the newly added document (will trigger loadDocument via onChange)
        selectedDocument = document
    }

    // MARK: - Recent Document Actions

    private func toggleFavorite(_ document: RecentDocument) {
        withAnimation {
            document.isFavorite.toggle()
        }
    }

    private func removeDocument(_ document: RecentDocument) {
        withAnimation {
            modelContext.delete(document)
            if selectedDocument?.id == document.id {
                selectedDocument = nil
            }
        }
    }

    // MARK: - State Management

    private func restoreSelectedDocument() {
        // First check if there's a pending document from "Open in New Window"
        if let pendingIDString = UserDefaults.standard.string(forKey: "pendingDocumentID"),
           let pendingUUID = UUID(uuidString: pendingIDString) {
            selectedDocument = recentDocuments.first { $0.id == pendingUUID }
            return
        }

        // Otherwise restore from @SceneStorage if available
        guard let idString = selectedDocumentID,
              let uuid = UUID(uuidString: idString) else {
            return
        }

        // Find document by ID in recent documents
        selectedDocument = recentDocuments.first { $0.id == uuid }
    }

    private func resetDocumentState() {
        currentFileDocument = MarkdownFileDocument()
        currentDocumentURL = nil
        hasUnsavedChanges = false
        loadError = nil
        isEditingNewDocument = false
        autoSaveTask?.cancel()
    }

    // MARK: - App Intent Navigation Handling

    private func handleNavigationAction(_ action: NavigationAction) {
        switch action {
        case .openDocument(let url):
            addToRecents(url)
        case .openDocumentByID(let id):
            if let doc = recentDocuments.first(where: { $0.id == id }) {
                selectedDocument = doc
            }
        case .createNewDocument(let initialContent):
            createNewDocument()
            if let content = initialContent {
                currentFileDocument = MarkdownFileDocument(content: content)
            }
        case .setViewMode:
            // View mode changes are handled by SplitEditorViewModel
            // through FocusedValues - this requires additional integration
            break
        case .showSearch:
            // Search UI integration can be added in future
            break
        case .none:
            break
        }
        NavigationService.shared.clearPendingAction()
    }
}

// MARK: - Preview

@MainActor
private final class MockSettingsRepository: SettingsRepository {
    func load() async throws -> AppSettings? { return .default }
    func save(_ settings: AppSettings) async throws {}
    func resetToDefaults() async throws {}
    func hasSettings() async -> Bool { return true }
}

#Preview {
    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    ContentView()
        .modelContainer(for: RecentDocument.self, inMemory: true)
        .environment(settingsViewModel)
}
