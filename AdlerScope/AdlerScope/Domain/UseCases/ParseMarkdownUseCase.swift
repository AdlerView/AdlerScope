import Foundation
import Markdown
import OSLog

/// Use case for parsing markdown text with configured settings
/// Thread-safe actor that orchestrates markdown parsing operations
actor ParseMarkdownUseCase {
    // MARK: - Dependencies

    private let parserRepository: MarkdownParserRepository

    // MARK: - Initialization

    init(parserRepository: MarkdownParserRepository) {
        self.parserRepository = parserRepository
    }

    // MARK: - Business Logic

    /// Parses markdown text using swift-markdown
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Parsed markdown document (AST)
    /// - Throws: ParseError if parsing fails
    nonisolated func execute(markdown: String) async throws -> Document {
        // Check complexity for performance warning
        let complexity = await parserRepository.estimateComplexity(markdown)
        if complexity > 5000 {
            await os_log("High complexity markdown (%d ms estimated) - may cause UI lag", log: .rendering, type: .info, complexity)
        }

        // Parse with swift-markdown default behavior
        let document = try await parserRepository.parse(markdown)

        return document
    }

    /// Validates markdown syntax without full parsing
    /// - Parameter markdown: Raw markdown text
    /// - Returns: True if markdown is syntactically valid
    nonisolated func validate(markdown: String) async -> Bool {
        await parserRepository.validate(markdown)
    }

    /// Estimates parsing time for performance optimization
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Estimated parsing time in milliseconds
    nonisolated func estimateComplexity(markdown: String) async -> Int {
        await parserRepository.estimateComplexity(markdown)
    }
}
