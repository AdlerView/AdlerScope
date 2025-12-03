//
//  MarkdownFileDocumentTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for MarkdownFileDocument functionality
//

import Testing
import Foundation
import SwiftUI
import UniformTypeIdentifiers
@testable import AdlerScope

@Suite("MarkdownFileDocument Tests")
struct MarkdownFileDocumentTests {

    @Test("Initialization with empty content")
    func testInitEmpty() {
        let document = MarkdownFileDocument()

        #expect(document.content == "")
    }

    @Test("Initialization with content")
    func testInitWithContent() {
        let document = MarkdownFileDocument(content: "# Hello World")

        #expect(document.content == "# Hello World")
    }

    @Test("Initialization with multiline content")
    func testInitWithMultilineContent() {
        let content = """
        # Heading

        Paragraph text
        """
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("readableContentTypes contains expected types")
    func testReadableContentTypes() {
        let types = MarkdownFileDocument.readableContentTypes

        #expect(!types.isEmpty)
        #expect(types.contains(.plainText))
    }

    @Test("readableContentTypes contains R Markdown")
    func testReadableContentTypesRMarkdown() {
        let types = MarkdownFileDocument.readableContentTypes

        #expect(types.contains(.rMarkdown))
    }

    @Test("readableContentTypes contains Quarto")
    func testReadableContentTypesQuarto() {
        let types = MarkdownFileDocument.readableContentTypes

        #expect(types.contains(.quarto))
    }

    @Test("Content can be modified")
    func testContentModification() {
        var document = MarkdownFileDocument(content: "Initial")
        document.content = "Modified"

        #expect(document.content == "Modified")
    }

    @Test("Content with unicode characters")
    func testUnicodeContent() {
        let content = "# 你好世界\n\nこんにちは\n\nمرحبا"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Content with emoji")
    func testEmojiContent() {
        let content = "Hello 👋 World 🌍"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Content with special characters")
    func testSpecialCharacters() {
        let content = "Special: !@#$%^&*()_+-={}[]|\\:\";<>?,./"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Very large content")
    func testVeryLargeContent() {
        let content = String(repeating: "Line of text\n", count: 10000)
        let document = MarkdownFileDocument(content: content)

        #expect(document.content.count == content.count)
        #expect(document.content == content)
    }
}

@Suite("UTType Extensions Tests")
struct UTTypeMarkdownExtensionTests {

    @Test("plainText is markdown")
    func testPlainTextIsMarkdown() {
        #expect(UTType.plainText.isMarkdown == true)
    }

    @Test("rMarkdown is markdown")
    func testRMarkdownIsMarkdown() {
        #expect(UTType.rMarkdown.isMarkdown == true)
    }

    @Test("quarto is markdown")
    func testQuartoIsMarkdown() {
        #expect(UTType.quarto.isMarkdown == true)
    }

    @Test("PDF is not markdown")
    func testPDFIsNotMarkdown() {
        #expect(UTType.pdf.isMarkdown == false)
    }

    @Test("Image is not markdown")
    func testImageIsNotMarkdown() {
        #expect(UTType.image.isMarkdown == false)
    }

    @Test("JSON is not markdown")
    func testJSONIsNotMarkdown() {
        #expect(UTType.json.isMarkdown == false)
    }

    @Test("XML is not markdown")
    func testXMLIsNotMarkdown() {
        #expect(UTType.xml.isMarkdown == false)
    }
}

@Suite("MarkdownFileDocument Edge Cases")
struct MarkdownFileDocumentEdgeCaseTests {

    @Test("Empty string content")
    func testEmptyStringContent() {
        let document = MarkdownFileDocument(content: "")

        #expect(document.content.isEmpty)
    }

    @Test("Whitespace-only content")
    func testWhitespaceContent() {
        let content = "   \n\n\t\t  "
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Content with null character")
    func testNullCharacter() {
        let content = "Before\u{0000}After"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Content with line breaks")
    func testLineBreaks() {
        let content = "Line1\nLine2\r\nLine3\rLine4"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }

    @Test("Content with tabs")
    func testTabs() {
        let content = "Col1\tCol2\tCol3"
        let document = MarkdownFileDocument(content: content)

        #expect(document.content == content)
    }
}
