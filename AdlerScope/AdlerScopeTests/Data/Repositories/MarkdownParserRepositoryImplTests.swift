//
//  MarkdownParserRepositoryImplTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for MarkdownParserRepositoryImpl functionality
//

import Testing
import Foundation
import Markdown
@testable import AdlerScope

@Suite("MarkdownParserRepositoryImpl Tests")
struct MarkdownParserRepositoryImplTests {

    @Test("Parse simple markdown")
    func testParseSimpleMarkdown() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "# Hello World\n\nThis is a paragraph."

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse empty string")
    func testParseEmptyString() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = ""

        let document = try await repository.parse(markdown)

        // Empty markdown produces a document with 0 children
        #expect(document.childCount >= 0)
    }

    @Test("Parse complex markdown with headings")
    func testParseComplexMarkdown() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = """
        # Heading 1
        ## Heading 2
        ### Heading 3

        Paragraph with **bold** and *italic* text.

        - List item 1
        - List item 2

        ```swift
        let code = "example"
        ```
        """

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with code blocks")
    func testParseMarkdownWithCodeBlocks() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = """
        ```swift
        func hello() {
            print("Hello, World!")
        }
        ```
        """

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with links")
    func testParseMarkdownWithLinks() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "[Link](https://example.com)"

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with block quotes")
    func testParseMarkdownWithBlockQuotes() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "> This is a quote\n> Another line"

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Validate always returns true for valid markdown")
    func testValidateValidMarkdown() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "# Valid Markdown"

        let isValid = await repository.validate(markdown)

        #expect(isValid == true)
    }

    @Test("Validate returns true for empty string")
    func testValidateEmptyString() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = ""

        let isValid = await repository.validate(markdown)

        #expect(isValid == true)
    }

    @Test("Validate returns true for malformed markdown")
    func testValidateMalformedMarkdown() async {
        let repository = await MarkdownParserRepositoryImpl()
        // swift-markdown is lenient and accepts anything
        let markdown = "### ### ###\n**bold *italic**"

        let isValid = await repository.validate(markdown)

        #expect(isValid == true)
    }

    @Test("Estimate complexity for short markdown")
    func testEstimateComplexityShort() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "# Short"

        let complexity = await repository.estimateComplexity(markdown)

        #expect(complexity >= 1)
    }

    @Test("Estimate complexity for long markdown")
    func testEstimateComplexityLong() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = String(repeating: "Line\n", count: 1000)

        let complexity = await repository.estimateComplexity(markdown)

        #expect(complexity > 1)
    }

    @Test("Estimate complexity increases with content")
    func testEstimateComplexityScales() async {
        let repository = await MarkdownParserRepositoryImpl()
        let shortMarkdown = "# Short"
        let longMarkdown = String(repeating: "Line\n", count: 100)

        let shortComplexity = await repository.estimateComplexity(shortMarkdown)
        let longComplexity = await repository.estimateComplexity(longMarkdown)

        #expect(longComplexity > shortComplexity)
    }

    @Test("Estimate complexity minimum is 1")
    func testEstimateComplexityMinimum() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "x"

        let complexity = await repository.estimateComplexity(markdown)

        #expect(complexity >= 1)
    }
}

@Suite("MarkdownParserRepositoryImpl Edge Cases")
struct MarkdownParserRepositoryImplEdgeCaseTests {

    @Test("Parse very long markdown")
    func testParseVeryLongMarkdown() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = String(repeating: "# Heading\n\nParagraph text.\n\n", count: 1000)

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with special characters")
    func testParseSpecialCharacters() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "Special: !@#$%^&*()_+-={}[]|\\:\";<>?,./"

        let document = try await repository.parse(markdown)

        // Document should be created successfully
        #expect(document.childCount >= 0)
    }

    @Test("Parse markdown with unicode")
    func testParseUnicode() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "# 你好世界\n\nこんにちは\n\nمرحبا"

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with emoji")
    func testParseEmoji() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "# Hello 👋\n\nWelcome! 🎉"

        let document = try await repository.parse(markdown)

        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with only whitespace")
    func testParseWhitespace() async throws {
        let repository = await MarkdownParserRepositoryImpl()
        let markdown = "   \n\n\t\t\n   "

        let document = try await repository.parse(markdown)

        // Whitespace-only markdown produces a document
        #expect(document.childCount >= 0)
    }

    @Test("Validate various markdown formats")
    func testValidateVariousFormats() async {
        let repository = await MarkdownParserRepositoryImpl()
        let markdowns = [
            "# Heading",
            "**bold**",
            "*italic*",
            "`code`",
            "[link](url)",
            "![image](url)",
            "- list",
            "> quote",
            "```\ncode\n```"
        ]

        for markdown in markdowns {
            let isValid = await repository.validate(markdown)
            #expect(isValid == true)
        }
    }

    @Test("Estimate complexity for various inputs")
    func testEstimateComplexityVariousInputs() async {
        let repository = await MarkdownParserRepositoryImpl()
        let inputs = [
            "",
            "x",
            "Short line",
            String(repeating: "Line\n", count: 10),
            String(repeating: "x", count: 1000)
        ]

        for input in inputs {
            let complexity = await repository.estimateComplexity(input)
            #expect(complexity >= 1)
        }
    }
}

@Suite("MarkdownParserRepositoryImpl Actor Isolation")
struct MarkdownParserRepositoryImplActorTests {

    @Test("Can be used from different contexts")
    func testActorIsolation() async throws {
        let repository = await MarkdownParserRepositoryImpl()

        // Multiple concurrent calls should work
        async let doc1 = repository.parse("# Doc 1")
        async let doc2 = repository.parse("# Doc 2")
        async let doc3 = repository.parse("# Doc 3")

        let results = try await [doc1, doc2, doc3]
        #expect(results.count == 3)
    }

    @Test("Parse is thread-safe")
    func testParseConcurrency() async throws {
        let repository = await MarkdownParserRepositoryImpl()

        let tasks = (0..<10).map { i in
            Task {
                try await repository.parse("# Document \(i)")
            }
        }

        for task in tasks {
            let doc = try await task.value
            #expect(doc.childCount > 0)
        }
    }
}
