//
//  DocumentDetailView.swift
//  AdlerScope
//
//  Detail view for displaying and editing documents
//  Uses @Bindable for ViewModel binding
//

import SwiftData
import SwiftUI

struct DocumentDetailView: View {
    @Bindable var viewModel: DocumentEditorViewModel
    @Environment(\.dependencyContainer) private var dependencies
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingDocument {
                loadingView
            } else if let error = viewModel.loadError, let document = viewModel.selectedDocument {
                DocumentErrorView(
                    error: error,
                    document: document,
                    onRetry: {
                        Task {
                            await viewModel.loadDocument(document)
                        }
                    },
                    onRemove: {
                        viewModel.removeDocument(document)
                    }
                )
            } else {
                editorView
            }
        }
        .toolbar {
            toolbarContent
        }
        .navigationTitle(viewModel.documentTitle)
        .navigationSubtitle(viewModel.documentSubtitle)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading \(viewModel.documentTitle)...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading document")
    }

    private var editorView: some View {
        SplitEditorView(
            document: $viewModel.currentFileDocument,
            parseMarkdownUseCase: dependencies.parseMarkdownUseCase,
            settingsViewModel: settingsViewModel
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                Task { await viewModel.saveDocument() }
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!viewModel.canSave)
            .accessibilityLabel("Save document")
            .accessibilityHint("Saves changes to the current document")

            if viewModel.hasUnsavedChanges {
                unsavedChangesIndicator
            }
        }
    }

    private var unsavedChangesIndicator: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .foregroundStyle(.orange)
            .help("Unsaved changes")
            .accessibilityLabel("Document has unsaved changes")
    }
}

// MARK: - Previews

@MainActor
private final class PreviewSettingsRepository: SettingsRepository {
    func load() async throws -> AppSettings? { return .default }
    func save(_ settings: AppSettings) async throws {}
    func resetToDefaults() async throws {}
    func hasSettings() async -> Bool { return true }
}

@MainActor
private func makePreviewSettingsViewModel() -> SettingsViewModel {
    let mockRepo = PreviewSettingsRepository()
    return SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )
}

#Preview("Document Detail - Editor") {
    let container = try! ModelContainer(
        for: AppSettings.self, RecentDocument.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = DocumentEditorViewModel(modelContext: container.mainContext)
    viewModel.currentFileDocument = MarkdownFileDocument(content: """
        # Sample Document

        This is a **preview** of the document detail view.

        ## Features
        - Markdown editing
        - Live preview
        - Auto-save

        ```swift
        let greeting = "Hello, World!"
        ```
        """)

    return NavigationStack {
        DocumentDetailView(viewModel: viewModel)
            .environment(\.dependencyContainer, DependencyContainer.shared)
            .environment(makePreviewSettingsViewModel())
    }
    .frame(width: 800, height: 600)
}

#Preview("Document Detail - Loading") {
    let container = try! ModelContainer(
        for: AppSettings.self, RecentDocument.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = DocumentEditorViewModel(modelContext: container.mainContext)
    viewModel.isLoadingDocument = true

    return NavigationStack {
        DocumentDetailView(viewModel: viewModel)
            .environment(\.dependencyContainer, DependencyContainer.shared)
            .environment(makePreviewSettingsViewModel())
    }
    .frame(width: 800, height: 600)
}

#Preview("Document Detail - Unsaved Changes") {
    let container = try! ModelContainer(
        for: AppSettings.self, RecentDocument.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = DocumentEditorViewModel(modelContext: container.mainContext)
    viewModel.currentFileDocument = MarkdownFileDocument(content: "# Edited Document\n\nThis document has unsaved changes.")
    viewModel.hasUnsavedChanges = true
    viewModel.currentDocumentURL = URL(fileURLWithPath: "/tmp/test.md")

    return NavigationStack {
        DocumentDetailView(viewModel: viewModel)
            .environment(\.dependencyContainer, DependencyContainer.shared)
            .environment(makePreviewSettingsViewModel())
    }
    .frame(width: 800, height: 600)
}
