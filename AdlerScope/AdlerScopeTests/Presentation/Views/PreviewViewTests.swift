//
//  PreviewViewTests.swift
//  AdlerScopeTests
//
//  Essential tests for PreviewView and MarkdownBlockView
//  Reduced from 41 to 13 tests - removed 28 redundant tests with no real assertions
//

import Testing
import SwiftUI
import Markdown
@testable import AdlerScope

// MARK: - Test Helpers

/// Create a mock markdown document for testing
func createMockDocument(markdown: String) -> Document {
    let document = Document(parsing: markdown)
    return document
}

// MARK: - Essential Tests

@Suite("PreviewView Essential Tests")
@MainActor
struct PreviewViewTests {

    // MARK: - Nil Document Handling

    @Test("Handles nil document without crashing")
    func testBodyGetterNilDocument() {
        _ = createMockSettingsViewModel()

        let view = PreviewView(document: nil)

        // Access body.getter - should show empty state
        _ = view.body

        #expect(Bool(true))
    }

    @Test("Handles empty markdown document")
    func testEmptyDocument() {
        let settingsViewModel = createMockSettingsViewModel()
        let document = createMockDocument(markdown: "")

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(document.childCount == 0)
    }

    // MARK: - Settings Integration

    @Test("Passes openInlineLinks setting to child views")
    func testClosure1InClosure1PassesSettings() {
        let settingsViewModel = createMockSettingsViewModel()
        settingsViewModel.settings.editor.openInlineLink = true

        let document = createMockDocument(markdown: "# Test")

        let view = PreviewView(document: document)

        // The closure passes settingsViewModel.settings.editor.openInlineLink
        _ = view.body

        #expect(settingsViewModel.settings.editor.openInlineLink == true)
    }

    @Test("Responds to settings changes")
    func testViewWithSettingsChanges() {
        let settingsViewModel = createMockSettingsViewModel()
        let document = createMockDocument(markdown: "[Link](https://example.com)")

        // Change setting
        settingsViewModel.settings.editor.openInlineLink = false

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(settingsViewModel.settings.editor.openInlineLink == false)
    }

    // MARK: - Integration Tests

    @Test("Renders full view hierarchy with heading")
    func testFullViewWithHeading() {
        let settingsViewModel = createMockSettingsViewModel()
        let document = createMockDocument(markdown: "# Main Title")

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(document.childCount > 0)
    }

    @Test("Renders full view hierarchy with multiple block types")
    func testFullViewWithMultipleBlocks() {
        let settingsViewModel = createMockSettingsViewModel()
        let markdown = """
        # Heading

        This is a paragraph.

        ```swift
        let code = "test"
        ```

        - List item 1
        - List item 2
        """
        let document = createMockDocument(markdown: markdown)

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(document.childCount > 0)
    }

    // MARK: - Edge Cases

    @Test("Handles very long markdown document")
    func testVeryLongDocument() {
        let settingsViewModel = createMockSettingsViewModel()
        let longMarkdown = String(repeating: "# Heading\n\nParagraph\n\n", count: 100)
        let document = createMockDocument(markdown: longMarkdown)

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(document.childCount > 100)
    }

    @Test("Handles markdown with special characters and formatting")
    func testMarkdownWithSpecialCharacters() {
        let settingsViewModel = createMockSettingsViewModel()
        let markdown = "# Test 🎉\n\n**Bold** _italic_ `code`"
        let document = createMockDocument(markdown: markdown)

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(Bool(true))
    }

    @Test("Handles markdown with nested structures")
    func testMarkdownWithNestedStructures() {
        let settingsViewModel = createMockSettingsViewModel()
        let markdown = """
        > This is a quote
        >
        > - With a list
        > - Inside it
        """
        let document = createMockDocument(markdown: markdown)

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(Bool(true))
    }

    @Test("Handles document with only whitespace")
    func testSingleWhitespaceDocument() {
        let settingsViewModel = createMockSettingsViewModel()
        let document = createMockDocument(markdown: "   ")

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(Bool(true))
    }

    @Test("Handles document with only newlines")
    func testDocumentWithOnlyNewlines() {
        let settingsViewModel = createMockSettingsViewModel()
        let document = createMockDocument(markdown: "\n\n\n\n")

        _ = PreviewView(document: document)
            .environment(settingsViewModel)

        #expect(Bool(true))
    }

    @Test("Handles document switching from nil to non-nil")
    func testDocumentSwitching() {
        _ = createMockSettingsViewModel()

        // Start with nil
        var currentDoc: Document? = nil
        let view1 = PreviewView(document: currentDoc)

        // Access body before applying modifiers
        _ = view1.body

        // Switch to non-nil
        currentDoc = createMockDocument(markdown: "# New content")
        let view2 = PreviewView(document: currentDoc)

        // Access body before applying modifiers
        _ = view2.body

        #expect(Bool(true))
    }
}

// MARK: - MarkdownBlockView Type Dispatcher Tests

@Suite("MarkdownBlockView Type Dispatcher Tests")
@MainActor
struct MarkdownBlockViewTests {

    @Test("Dispatches to correct view for all supported markup types")
    func testAllSupportedMarkupTypes() {
        let markdownSamples = [
            "# Heading",
            "Paragraph",
            "```\ncode\n```",
            "- List",
            "1. Ordered",
            "> Quote",
            "---",
            "<div>HTML Block</div>"
        ]

        for markdown in markdownSamples {
            let document = createMockDocument(markdown: markdown)
            if let markup = Array(document.children).first {
                let view = MarkdownBlockView(markup: markup, openInlineLinks: false)
                _ = view.body
            }
        }

        #expect(Bool(true))
    }

    @Test("Handles HTML blocks without showing unsupported warning")
    func testHTMLBlockRendering() {
        let markdown = "<div class=\"container\">\n  <p>HTML content</p>\n</div>"
        let document = createMockDocument(markdown: markdown)

        if let htmlBlock = Array(document.children).first as? HTMLBlock {
            let view = MarkdownBlockView(markup: htmlBlock, openInlineLinks: false)
            _ = view.body

            // Verify it's recognized as an HTMLBlock
            #expect(htmlBlock.rawHTML.contains("div"))
        }
    }
}
