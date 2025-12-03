//
//  DocumentEditorView.swift
//  AdlerScope
//
//  Main editor view for DocumentGroup-based document handling
//  Handles both Markdown editing and PDF viewing
//

import PDFKit
import PhotosUI
import SwiftUI

/// Main document editor view used by DocumentGroup
/// Receives document binding from DocumentGroup and delegates to appropriate view
struct DocumentEditorView: View {
    // MARK: - Document Binding

    @Binding var document: MarkdownFileDocument

    // MARK: - Environment

    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(SettingsViewModel.self) private var settingsViewModel

    // MARK: - Photo Import State

    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isProcessingPhotos = false
    @State private var photoImportError: String?

    // MARK: - Body

    var body: some View {
        Group {
            if document.isPDF {
                // PDF Viewer (read-only)
                PDFDocumentView(document: document)
            } else {
                // Markdown Editor
                SplitEditorView(
                    document: $document,
                    parseMarkdownUseCase: dependencyContainer.parseMarkdownUseCase,
                    settingsViewModel: settingsViewModel
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #endif
        .focusedSceneValue(\.importFromPhotos, showPhotosPicker)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItems) { oldItems, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await processSelectedPhotos(newItems)
            }
        }
        .alert("Photo Import Error", isPresented: .init(
            get: { photoImportError != nil },
            set: { if !$0 { photoImportError = nil } }
        )) {
            Button("OK") { photoImportError = nil }
        } message: {
            if let error = photoImportError {
                Text(error)
            }
        }
    }

    // MARK: - Photo Import Actions

    /// Shows the Photos picker
    private func showPhotosPicker() {
        guard !document.isPDF else { return }
        selectedPhotoItems = []
        showPhotoPicker = true
    }

    /// Processes selected photos and inserts markdown image references
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }

        var markdownImages: [String] = []

        for item in items {
            do {
                // Try to load as Data first for file info
                if let _ = try await item.loadTransferable(type: Data.self) {
                    // Generate a unique filename based on current timestamp
                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let filename = "photo_\(timestamp)_\(markdownImages.count + 1)"

                    // Determine file extension from supported content types
                    let fileExtension: String
                    if item.supportedContentTypes.contains(where: { $0.identifier.contains("png") }) {
                        fileExtension = "png"
                    } else if item.supportedContentTypes.contains(where: { $0.identifier.contains("gif") }) {
                        fileExtension = "gif"
                    } else {
                        fileExtension = "jpg"
                    }

                    // Create markdown image syntax
                    // Note: In a full implementation, you would save the image data to a file
                    // and reference the actual path. For now, we insert a placeholder.
                    let imageName = "\(filename).\(fileExtension)"
                    let markdown = "![Imported Image](\(imageName))"
                    markdownImages.append(markdown)
                }
            } catch {
                await MainActor.run {
                    photoImportError = "Failed to import photo: \(error.localizedDescription)"
                }
            }
        }

        // Insert markdown at the end of the document
        if !markdownImages.isEmpty {
            await MainActor.run {
                let imageMarkdown = markdownImages.joined(separator: "\n\n")
                if document.content.isEmpty {
                    document.content = imageMarkdown
                } else {
                    document.content += "\n\n" + imageMarkdown
                }
                selectedPhotoItems = []
            }
        }
    }
}

// MARK: - PDF Document View

/// View for displaying PDF documents (read-only)
struct PDFDocumentView: View {
    let document: MarkdownFileDocument

    @State private var totalPages: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if let pdf = document.pdfDocument {
                #if os(macOS)
                PDFViewRepresentable(pdfDocument: pdf)
                #else
                Text("PDF viewing is only available on macOS")
                    .foregroundColor(.secondary)
                #endif
            } else {
                ContentUnavailableView(
                    "Unable to Load PDF",
                    systemImage: "doc.fill.badge.ellipsis",
                    description: Text("The PDF document could not be displayed.")
                )
            }
        }
        .onAppear {
            totalPages = document.pdfDocument?.pageCount ?? 0
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if totalPages > 0 {
                    Text("\(totalPages) page\(totalPages == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        #endif
    }
}

// MARK: - Preview

#Preview("Markdown Editor") {
    @Previewable @State var document = MarkdownFileDocument(content: """
        # Sample Document

        This is a **sample** markdown document for preview.

        ## Features
        - Lists
        - **Bold** and *italic*
        - Code blocks

        ```swift
        let greeting = "Hello, World!"
        ```
        """)

    @MainActor
    class MockSettingsRepository: SettingsRepository {
        func load() async throws -> AppSettings? { return .default }
        func save(_ settings: AppSettings) async throws {}
        func resetToDefaults() async throws {}
        func hasSettings() async -> Bool { return true }
    }

    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    return DocumentEditorView(document: $document)
        .environment(\.dependencyContainer, DependencyContainer.shared)
        .environment(settingsViewModel)
}
