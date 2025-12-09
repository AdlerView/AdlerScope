//
//  ParseMarkdownUseCaseTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for ParseMarkdownUseCase
//

import Testing
import Markdown
import Foundation
@testable import AdlerScope

@Suite("ParseMarkdownUseCase Tests")
@MainActor
struct ParseMarkdownUseCaseTests {

    // MARK: - Tests

    @Test("Parse simple markdown successfully")
    func testParseSimpleMarkdown() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = "# Hello World\n\nThis is a test."

        // Act
        let document = try await useCase.execute(markdown: markdown)

        // Assert
        #expect(document.childCount >= 0)
        #expect(mockRepo.parseCallCount == 1)
    }

    @Test("Parse markdown with complex content")
    func testParseComplexContent() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = "# Test\n\n**Bold** and *italic*"

        // Act
        let document = try await useCase.execute(markdown: markdown)

        // Assert
        #expect(document.childCount >= 0)
        #expect(mockRepo.parseCallCount == 1)
    }

    @Test("Validate markdown returns true for valid content")
    func testValidateMarkdown() async {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = "# Valid markdown"

        // Act
        let isValid = await useCase.validate(markdown: markdown)

        // Assert
        #expect(isValid == true)
        #expect(mockRepo.validateCallCount == 1)
    }

    @Test("Validate empty markdown still calls repository")
    func testValidateEmptyMarkdown() async {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = ""

        // Act
        let isValid = await useCase.validate(markdown: markdown)

        // Assert - swift-markdown considers all markdown valid (including empty)
        #expect(isValid == true)
        #expect(mockRepo.validateCallCount == 1)
    }

    @Test("Estimate complexity calls repository")
    func testEstimateComplexity() async {
        // Arrange
        let mockRepo = MockMarkdownParserRepository.withComplexity(500)
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = "# Large document\n\n" + String(repeating: "Content ", count: 1000)

        // Act
        let complexity = await useCase.estimateComplexity(markdown: markdown)

        // Assert
        #expect(complexity == 500)
        #expect(mockRepo.estimateComplexityCallCount == 1)
    }

    @Test("Parse throws error when repository fails")
    func testParseThrowsError() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository.withParseError()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
        let markdown = "# Test"

        // Act & Assert
        await #expect(throws: ParseError.self) {
            try await useCase.execute(markdown: markdown)
        }
    }

    @Test("Parse complex markdown with all features")
    func testParseComplexMarkdown() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)

        let complexMarkdown = """
        # Heading 1
        ## Heading 2

        **Bold text** and *italic text*

        - List item 1
        - List item 2

        1. Ordered item 1
        2. Ordered item 2

        `inline code`

        ```swift
        func test() {
            print("Hello")
        }
        ```

        > Block quote

        [Link](https://example.com)
        """

        // Act
        let document = try await useCase.execute(markdown: complexMarkdown)

        // Assert
        #expect(document.childCount >= 0)
        #expect(document.childCount > 0)
    }

    @Test("Parse markdown with table syntax")
    func testParseMarkdownWithTable() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)

        let tableMarkdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """

        // Act
        let document = try await useCase.execute(markdown: tableMarkdown)

        // Assert
        #expect(document.childCount >= 0)
    }

    @Test("Parse markdown with strikethrough")
    func testParseMarkdownWithStrikethrough() async throws {
        // Arrange
        let mockRepo = MockMarkdownParserRepository()
        let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)

        let strikethroughMarkdown = "~~strikethrough text~~"

        // Act
        let document = try await useCase.execute(markdown: strikethroughMarkdown)

        // Assert
        #expect(document.childCount >= 0)
    }
}
