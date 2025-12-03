//
//  PreviewView.swift
//  AdlerScope
//
//  Main container and dispatcher for markdown rendering
//  Individual view implementations are in separate files
//

import SwiftUI
import Markdown

/// Native SwiftUI Markdown Preview using swift-markdown AST
struct PreviewView: View {
    let document: Document?
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        ScrollView {
            if let doc = document {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(doc.children.enumerated()), id: \.offset) { index, child in
                        MarkdownBlockView(
                            markup: child,
                            openInlineLinks: settingsViewModel.settings.editor?.openInlineLink ?? false
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No preview available")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Start typing markdown in the editor")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.Markdown.textBackground)
    }
}

// MARK: - Block Dispatcher

/// Block-Level Renderer (Dispatcher)
/// Routes markdown blocks to appropriate view renderers
struct MarkdownBlockView: View {
    let markup: Markup
    let openInlineLinks: Bool

    var body: some View {
        Group {
            if let heading = markup as? Heading {
                HeadingView(heading: heading, openInlineLinks: openInlineLinks)
            } else if let paragraph = markup as? Paragraph {
                ParagraphView(paragraph: paragraph, openInlineLinks: openInlineLinks)
            } else if let codeBlock = markup as? CodeBlock {
                CodeBlockView(codeBlock: codeBlock)
            } else if let table = markup as? Markdown.Table {
                TableView(table: table, openInlineLinks: openInlineLinks)
            } else if let list = markup as? UnorderedList {
                UnorderedListView(list: list, openInlineLinks: openInlineLinks)
            } else if let list = markup as? OrderedList {
                OrderedListView(list: list, openInlineLinks: openInlineLinks)
            } else if let blockQuote = markup as? BlockQuote {
                BlockQuoteView(blockQuote: blockQuote, openInlineLinks: openInlineLinks)
            } else if markup is ThematicBreak {
                Divider()
                    .padding(.vertical, 8)
            } else if let htmlBlock = markup as? HTMLBlock {
                HTMLBlockView(htmlBlock: htmlBlock)
            } else {
                // Fallback for unsupported blocks
                Text("⚠️ Unsupported block: \(String(describing: type(of: markup)))")
                    .foregroundStyle(Color.Markdown.warning)
                    .font(.caption)
                    .padding(8)
                    .background(Color.Markdown.warning.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - HTML Block View

/// Renders HTML blocks found in markdown
/// Displays raw HTML with syntax-like styling
struct HTMLBlockView: View {
    let htmlBlock: HTMLBlock

    var body: some View {
        Text(htmlBlock.rawHTML)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Markdown.codeBackground)
            .cornerRadius(6)
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

#Preview("Preview - Empty State") {
    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    PreviewView(document: nil)
        .environment(settingsViewModel)
        .frame(width: 600, height: 400)
}

#Preview("Preview - Sample Content") {
    let markdown = """
        # Welcome to AdlerScope

        A native markdown editor for macOS.

        ## Features

        - **Live Preview** - See your changes instantly
        - *Syntax Highlighting* - Beautiful code blocks
        - Tables, lists, and more

        ### Code Example

        ```swift
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        ```

        ### Blockquote

        > This is a blockquote.
        > It spans multiple lines.

        ### Lists

        1. First item
        2. Second item
        3. Third item

        - Bullet point
        - Another bullet

        ### Table

        | Feature | Status |
        |---------|--------|
        | Preview | ✅ |
        | Editor  | ✅ |
        | Export  | 🚧 |
        """

    let document = Document(parsing: markdown)
    let mockRepo = MockSettingsRepository()
    let settingsViewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    PreviewView(document: document)
        .environment(settingsViewModel)
        .frame(width: 600, height: 800)
}
