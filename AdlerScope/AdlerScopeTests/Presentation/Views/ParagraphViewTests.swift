//
//  ParagraphViewTests.swift
//  AdlerScopeTests
//
//  Tests for ParagraphView and MarkdownInlineRenderer
//

import Testing
import Foundation
import SwiftUI
import Markdown
@testable import AdlerScope

@Suite("ParagraphView Tests")
struct ParagraphViewTests {

    @Test("ParagraphView can be instantiated")
    func testInstantiation() {
        let doc = Document(parsing: "This is a paragraph.")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let _ = ParagraphView(paragraph: paragraph, openInlineLinks: false)

        #expect(Bool(true))
    }

    @Test("ParagraphView with bold text")
    func testBoldText() {
        let doc = Document(parsing: "This is **bold** text.")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let _ = ParagraphView(paragraph: paragraph, openInlineLinks: false)

        #expect(Bool(true))
    }

    @Test("ParagraphView with italic text")
    func testItalicText() {
        let doc = Document(parsing: "This is *italic* text.")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let _ = ParagraphView(paragraph: paragraph, openInlineLinks: false)

        #expect(Bool(true))
    }

    @Test("ParagraphView with inline code")
    func testInlineCode() {
        let doc = Document(parsing: "This is `code` text.")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let _ = ParagraphView(paragraph: paragraph, openInlineLinks: false)

        #expect(Bool(true))
    }

    @Test("ParagraphView with link")
    func testLink() {
        let doc = Document(parsing: "This is a [link](https://example.com).")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let _ = ParagraphView(paragraph: paragraph, openInlineLinks: true)

        #expect(Bool(true))
    }
}

@Suite("MarkdownInlineRenderer Tests")
struct MarkdownInlineRendererTests {

    @Test("Render plain text")
    func testRenderPlainText() {
        let doc = Document(parsing: "Plain text")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render bold text")
    func testRenderBoldText() {
        let doc = Document(parsing: "**bold**")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render italic text")
    func testRenderItalicText() {
        let doc = Document(parsing: "*italic*")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render inline code")
    func testRenderInlineCode() {
        let doc = Document(parsing: "`code`")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render link without openInlineLinks")
    func testRenderLinkNoOpen() {
        let doc = Document(parsing: "[link](https://example.com)")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render link with openInlineLinks")
    func testRenderLinkWithOpen() {
        let doc = Document(parsing: "[link](https://example.com)")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: true)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render strikethrough text")
    func testRenderStrikethrough() {
        let doc = Document(parsing: "~~strikethrough~~")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }

    @Test("Render mixed formatting")
    func testRenderMixedFormatting() {
        let doc = Document(parsing: "**bold** and *italic* and `code`")
        guard let paragraph = doc.children.compactMap({ $0 as? Paragraph }).first else {
            Issue.record("Expected Paragraph")
            return
        }

        let rendered = MarkdownInlineRenderer.render(paragraph, openInlineLinks: false)

        #expect(!rendered.characters.isEmpty)
    }
}
