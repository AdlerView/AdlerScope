//
//  EditorContainerView.swift
//  AdlerScope
//
//  Container for markdown editor with loading and error states
//

import SwiftUI

struct EditorContainerView: View {
    // MARK: - Properties

    let document: RecentDocument
    @Binding var currentFileDocument: MarkdownFileDocument
    @Binding var currentDocumentURL: URL?
    @Binding var hasUnsavedChanges: Bool
    @Binding var isLoadingDocument: Bool
    @Binding var loadError: Error?

    // MARK: - Dependencies

    let parseMarkdownUseCase: ParseMarkdownUseCase
    let settingsViewModel: SettingsViewModel

    // MARK: - Actions

    let onSave: () async -> Void
    let onRetry: () -> Void
    let onRemove: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Loading indicator
            if isLoadingDocument {
                ProgressView("Loading \(document.displayName)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // Error state
            else if let error = loadError {
                DocumentErrorView(
                    error: error,
                    document: document,
                    onRetry: onRetry,
                    onRemove: onRemove
                )
            }
            // Editor
            else {
                SplitEditorView(
                    document: $currentFileDocument,
                    parseMarkdownUseCase: parseMarkdownUseCase,
                    settingsViewModel: settingsViewModel
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Save button
                Button {
                    Task { await onSave() }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!hasUnsavedChanges || currentDocumentURL == nil)

                // Unsaved changes indicator
                if hasUnsavedChanges {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                        .help("Unsaved changes")
                }
            }
        }
        .navigationTitle(document.displayName)
        .navigationSubtitle(currentDocumentURL?.path ?? "")
    }
}

// MARK: - Preview

@MainActor
private final class PreviewSettingsRepository: SettingsRepository {
    func load() async throws -> AppSettings? { return .default }
    func save(_ settings: AppSettings) async throws {}
    func resetToDefaults() async throws {}
    func hasSettings() async -> Bool { return true }
}

#Preview {
    @Previewable @State var fileDoc = MarkdownFileDocument(content: "# Hello\n\nTest content")
    @Previewable @State var url: URL? = URL(fileURLWithPath: "/Users/test/README.md")
    @Previewable @State var hasChanges = true
    @Previewable @State var isLoading = false
    @Previewable @State var error: Error?

    let container = DependencyContainer.shared
    let mockRepo = PreviewSettingsRepository()
    let settingsVM = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    NavigationStack {
        EditorContainerView(
            document: RecentDocument.sample(),
            currentFileDocument: $fileDoc,
            currentDocumentURL: $url,
            hasUnsavedChanges: $hasChanges,
            isLoadingDocument: $isLoading,
            loadError: $error,
            parseMarkdownUseCase: container.parseMarkdownUseCase,
            settingsViewModel: settingsVM,
            onSave: { print("Save") },
            onRetry: { print("Retry") },
            onRemove: { print("Remove") }
        )
    }
}
