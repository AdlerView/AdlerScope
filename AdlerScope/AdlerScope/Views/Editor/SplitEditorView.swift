import SwiftUI
import Markdown

/// Split editor view with multiple view modes (Editor Only | Preview Only | Split)
/// Uses Clean Architecture with dependency injection
struct SplitEditorView: View {
    @Binding var document: MarkdownFileDocument
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @State private var viewModel: SplitEditorViewModel

    init(
        document: Binding<MarkdownFileDocument>,
        parseMarkdownUseCase: ParseMarkdownUseCase,
        settingsViewModel: SettingsViewModel
    ) {
        self._document = document

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
                    editActions: viewModel.editActions
                )
                .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                .focusedSceneValue(\.editorText, $document.content)

            case .previewOnly:
                // Preview Only Mode
                PreviewView(document: viewModel.renderedDocument)

            case .split:
                // Split View Mode
                HSplitView {
                    if viewModel.swapPanes {
                        // Swapped: Preview on left, Editor on right
                        PreviewView(document: viewModel.renderedDocument)

                        AppKitTextEditor(
                            text: $document.content,
                            formatActions: viewModel.formatActions,
                            editActions: viewModel.editActions
                        )
                        .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                        .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                        .focusedSceneValue(\.editorText, $document.content)
                    } else {
                        // Normal: Editor on left, Preview on right
                        AppKitTextEditor(
                            text: $document.content,
                            formatActions: viewModel.formatActions,
                            editActions: viewModel.editActions
                        )
                        .applyFormatCommands(formatActions: viewModel.formatActions, onSync: syncText)
                        .applyEditCommands(editActions: viewModel.editActions, onSync: syncText)
                        .focusedSceneValue(\.editorText, $document.content)

                        PreviewView(document: viewModel.renderedDocument)
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

                PreviewView(document: viewModel.renderedDocument)
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
        .onChange(of: document.content) { oldValue, newValue in
            viewModel.debounceRender(content: newValue)
        }
        .onChange(of: viewModel.refreshTrigger) { _, _ in
            viewModel.forceRender(content: document.content)
        }
        .onAppear {
            Task {
                await viewModel.render(content: document.content)
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
