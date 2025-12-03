import Foundation
import Markdown

/// Repository protocol for markdown parsing operations
/// Abstracts the underlying markdown parser (swift-markdown, cmark-gfm, etc.)
/// Implementations wrap parser libraries and convert to domain entities
protocol MarkdownParserRepository: Sendable {
    /// Parses markdown text into an AST (Abstract Syntax Tree)
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Parsed Markdown.Document (swift-markdown AST)
    /// - Throws: If parsing fails due to invalid syntax or encoding issues
    func parse(_ markdown: String) async throws -> Document

    /// Validates markdown syntax without full parsing
    /// - Parameter markdown: Raw markdown text
    /// - Returns: True if syntax is valid
    func validate(_ markdown: String) async -> Bool

    /// Estimates parsing complexity (for performance optimization)
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Estimated parsing time in milliseconds
    func estimateComplexity(_ markdown: String) async -> Int
}
