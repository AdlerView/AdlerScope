import SwiftUI
import Markdown
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

/// Split editor view with multiple view modes (Editor Only | Preview Only | Split)
/// Uses Clean Architecture with dependency injection
struct SplitEditorView: View {
    @Binding var document: MarkdownFileDocument
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @State private var viewModel: SplitEditorViewModel

    // MARK: - Image Handling

    /// Document URL for sidecar management (optional, enables image insertion when set)
    let documentURL: URL?

    /// Manages the sidecar directory for images
    @State private var sidecarManager = SidecarManager()

    /// Handles image drag-and-drop operations
    @State private var imageDropHandler: ImageDropHandler?

    init(
        document: Binding<MarkdownFileDocument>,
        parseMarkdownUseCase: ParseMarkdownUseCase,
        settingsViewModel: SettingsViewModel,
        documentURL: URL? = nil
    ) {
        self._document = document
        self.documentURL = documentURL

        // Create ViewModel with injected dependencies
        self._viewModel = State(wrappedValue: SplitEditorViewModel(
            parseMarkdownUseCase: parseMarkdownUseCase,
            settingsViewModel: settingsViewModel
        ))
    }

    var body: some View {
        Group {
            #if os(macOS)
            switch viewModel.viewMode {
            case .editorOnly:
                // Editor Only Mode
                AppKitTextEditor(
                    text: $document.content,
                    formatActions: viewModel.formatActions,
                    editActions: viewModel.editActions,
                    imageDropHandler: imageDropHandler,
                    zoomManager: viewModel.viewActions.zoomManager
                )
                .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                .focusedSceneValue(\.editorText, $document.content)

            case .previewOnly:
                // Preview Only Mode
                PreviewView(
                    document: viewModel.renderedDocument,
                    sidecarManager: sidecarManager,
                    zoomLevel: viewModel.zoomLevel,
                    onZoomIn: viewModel.zoomIn,
                    onZoomOut: viewModel.zoomOut
                )

            case .split:
                // Split View Mode
                HSplitView {
                    if viewModel.swapPanes {
                        // Swapped: Preview on left, Editor on right
                        PreviewView(
                            document: viewModel.renderedDocument,
                            sidecarManager: sidecarManager,
                            zoomLevel: viewModel.zoomLevel,
                            onZoomIn: viewModel.zoomIn,
                            onZoomOut: viewModel.zoomOut
                        )

                        AppKitTextEditor(
                            text: $document.content,
                            formatActions: viewModel.formatActions,
                            editActions: viewModel.editActions,
                            imageDropHandler: imageDropHandler,
                            zoomManager: viewModel.viewActions.zoomManager
                        )
                        .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                        .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                        .focusedSceneValue(\.editorText, $document.content)
                    } else {
                        // Normal: Editor on left, Preview on right
                        AppKitTextEditor(
                            text: $document.content,
                            formatActions: viewModel.formatActions,
                            editActions: viewModel.editActions,
                            imageDropHandler: imageDropHandler,
                            zoomManager: viewModel.viewActions.zoomManager
                        )
                        .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                        .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                        .focusedSceneValue(\.editorText, $document.content)

                        PreviewView(
                            document: viewModel.renderedDocument,
                            sidecarManager: sidecarManager,
                            zoomLevel: viewModel.zoomLevel,
                            onZoomIn: viewModel.zoomIn,
                            onZoomOut: viewModel.zoomOut
                        )
                    }
                }
            }
            #else
            // iOS: Always show split view (no mode switching on iOS)
            HStack(spacing: 0) {
                SwiftUITextEditor(
                    text: $document.content,
                    formatActions: viewModel.formatActions,
                    editActions: viewModel.editActions
                )
                .focusedSceneValue(\.editorText, $document.content)

                Divider()

                PreviewView(
                    document: viewModel.renderedDocument,
                    sidecarManager: sidecarManager,
                    zoomLevel: viewModel.zoomLevel,
                    onZoomIn: viewModel.zoomIn,
                    onZoomOut: viewModel.zoomOut
                )
            }
            #endif
        }
        .focusedSceneValue(\.showEditor, viewModel.showEditorOnly)
        .focusedSceneValue(\.showPreview, viewModel.showPreviewOnly)
        .focusedSceneValue(\.showSplitView, viewModel.showSplitView)
        .focusedSceneValue(\.swapPanes, viewModel.toggleSwapPanes)
        .focusedSceneValue(\.zoomIn, viewModel.zoomIn)
        .focusedSceneValue(\.zoomOut, viewModel.zoomOut)
        .focusedSceneValue(\.resetZoom, viewModel.resetZoom)
        #if os(macOS)
        .focusedSceneValue(\.insertImage, presentImagePicker)
        #endif
        .onChange(of: document.content) { oldValue, newValue in
            viewModel.debounceRender(content: newValue)
        }
        .onChange(of: viewModel.refreshTrigger) { _, _ in
            viewModel.forceRender(content: document.content)
        }
        .onAppear {
            configureImageHandling()
            Task {
                await viewModel.render(content: document.content)
            }
        }
        .onChange(of: documentURL) { _, newURL in
            if let url = newURL {
                sidecarManager.configure(for: url)
                createImageDropHandler()
            }
        }
    }

    // MARK: - Sync Helpers

    /// Syncs text from formatActions back to document binding
    private func syncText() {
        if viewModel.formatActions.text != document.content {
            document.content = viewModel.formatActions.text
        }
    }

    // MARK: - Image Handling Helpers

    /// Configures sidecar manager and image drop handler
    private func configureImageHandling() {
        if let url = documentURL {
            sidecarManager.configure(for: url)
            createImageDropHandler()
        }
    }

    /// Creates the image drop handler with current dependencies
    private func createImageDropHandler() {
        #if os(macOS)
        imageDropHandler = ImageDropHandler(
            sidecarManager: sidecarManager,
            formatActions: viewModel.formatActions,
            undoManager: nil
        )
        #endif
    }

    #if os(macOS)
    /// Presents the image picker panel
    private func presentImagePicker() {
        guard sidecarManager.sidecarURL != nil else {
            // Document must be saved first
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.message = "Select images to insert"
        panel.prompt = "Insert"

        panel.begin { response in
            guard response == .OK else { return }
            imageDropHandler?.handleDrop(of: panel.urls)
        }
    }
    #endif
}

// MARK: - Preview

@MainActor
private final class MockSettingsRepository: SettingsRepository {
    func load() async throws -> AppSettings? { return .default }
    func save(_ settings: AppSettings) async throws {}
    func resetToDefaults() async throws {}
    func hasSettings() async -> Bool { return true }
}

#Preview("Split Editor - Editor Only") {
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

    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    SplitEditorView(
        document: $document,
        parseMarkdownUseCase: ParseMarkdownUseCase(
            parserRepository: MarkdownParserRepositoryImpl()
        ),
        settingsViewModel: settingsViewModel
    )
    .environment(settingsViewModel)
}

#Preview("Split Editor - Split View") {
    @Previewable @State var document = MarkdownFileDocument(content: """
        # AdlerScope Preview

        A markdown editor with live preview.

        ## Inline Styles
        - **Bold text**
        - *Italic text*
        - ~~Strikethrough~~
        - `inline code`

        ## Block Elements

        > This is a blockquote.
        > It can span multiple lines.

        ### Code Block

        ```python
        def hello_world():
            print("Hello, World!")
        ```
        """)

    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    SplitEditorView(
        document: $document,
        parseMarkdownUseCase: ParseMarkdownUseCase(
            parserRepository: MarkdownParserRepositoryImpl()
        ),
        settingsViewModel: settingsViewModel
    )
    .environment(settingsViewModel)
}
