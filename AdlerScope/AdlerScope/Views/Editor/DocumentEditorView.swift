//
//  DocumentEditorView.swift
//  AdlerScope
//
//  Main editor view for DocumentGroup-based document handling
//  Handles Markdown editing, PDF viewing, and image viewing
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
            } else if document.isImage {
                // Image Viewer (read-only)
                ImageDocumentView(document: document)
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
        guard !document.isPDF, !document.isImage else { return }
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

// MARK: - Image Document View

/// View for displaying image documents (read-only)
struct ImageDocumentView: View {
    let document: MarkdownFileDocument

    @State private var zoomScale: CGFloat = 1.0
    @State private var imageSize: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                if let imageData = document.imageData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(zoomScale)
                            .frame(
                                minWidth: geometry.size.width,
                                minHeight: geometry.size.height
                            )
                            .onAppear {
                                imageSize = nsImage.size
                            }
                    } else {
                        imageErrorView
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(zoomScale)
                            .frame(
                                minWidth: geometry.size.width,
                                minHeight: geometry.size.height
                            )
                            .onAppear {
                                imageSize = uiImage.size
                            }
                    } else {
                        imageErrorView
                    }
                    #endif
                } else {
                    imageErrorView
                }
            }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    withAnimation { zoomScale = max(0.1, zoomScale - 0.25) }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out")

                Button {
                    withAnimation { zoomScale = 1.0 }
                } label: {
                    Text("\(Int(zoomScale * 100))%")
                        .frame(minWidth: 50)
                }
                .help("Reset Zoom")

                Button {
                    withAnimation { zoomScale = min(5.0, zoomScale + 0.25) }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In")

                Divider()

                if imageSize != .zero {
                    Text("\(Int(imageSize.width)) × \(Int(imageSize.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        #endif
    }

    private var imageErrorView: some View {
        ContentUnavailableView(
            "Unable to Load Image",
            systemImage: "photo.badge.exclamationmark",
            description: Text("The image could not be displayed.")
        )
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
