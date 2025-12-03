import Foundation
import Markdown

/// Concrete implementation of MarkdownParserRepository using swift-markdown
/// Wraps Apple's swift-markdown library and converts to domain entities
actor MarkdownParserRepositoryImpl: MarkdownParserRepository {
    // MARK: - Initialization

    init() {}

    // MARK: - MarkdownParserRepository

    func parse(_ markdown: String) async throws -> Document {
        // Parse using swift-markdown with default behavior
        let document = Document(parsing: markdown)
        return document
    }

    func validate(_ markdown: String) async -> Bool {
        // swift-markdown is lenient and doesn't throw errors
        // Document(parsing:) always succeeds, so all markdown is valid
        _ = Document(parsing: markdown)
        return true
    }

    func estimateComplexity(_ markdown: String) async -> Int {
        // Simple heuristic based on content size and structure
        let lineCount = markdown.components(separatedBy: .newlines).count
        let characterCount = markdown.count

        // Estimate: ~0.1ms per line + ~0.001ms per character
        let estimatedMS = (lineCount / 10) + (characterCount / 1000)

        return max(1, estimatedMS)
    }
}
