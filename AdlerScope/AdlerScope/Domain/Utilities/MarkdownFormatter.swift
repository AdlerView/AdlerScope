//
//  MarkdownFormatter.swift
//  AdlerScope
//
//  Provides markdown formatting utilities for text manipulation.
//
//  Note: SwiftUI's TextEditor doesn't expose selection APIs, so these formatters
//  work by inserting markdown syntax templates at the end of text. Users can then
//  move their cursor to type between the markers.
//

import Foundation

/// Utilities for formatting text with markdown syntax
struct MarkdownFormatter {

    // MARK: - Emphasis Formatting

    /// Wraps text with bold markdown syntax (**text**)
    /// - Parameter text: The text to format
    /// - Returns: Text with bold markers inserted at the end
    static func insertBold(in text: String) -> String {
        return text + "****"
    }

    /// Wraps text with italic markdown syntax (*text* or _text_)
    /// - Parameter text: The text to format
    /// - Returns: Text with italic markers inserted at the end
    static func insertItalic(in text: String) -> String {
        return text + "**"
    }

    /// Wraps text with strikethrough markdown syntax (~~text~~)
    /// - Parameter text: The text to format
    /// - Returns: Text with strikethrough markers inserted at the end
    static func insertStrikethrough(in text: String) -> String {
        return text + "~~~~"
    }

    /// Wraps text with inline code markdown syntax (`text`)
    /// - Parameter text: The text to format
    /// - Returns: Text with inline code markers inserted at the end
    static func insertInlineCode(in text: String) -> String {
        return text + "``"
    }

    // MARK: - Block Formatting

    /// Wraps text with blockquote markdown syntax (> text)
    /// - Parameter text: The text to format
    /// - Returns: Text with blockquote marker added to the last line
    static func insertBlockquote(in text: String) -> String {
        // Add blockquote marker at the end
        return text + "\n> "
    }

    /// Wraps text with code block markdown syntax (```text```)
    /// - Parameter text: The text to format
    /// - Returns: Text with code block markers inserted
    static func insertCodeBlock(in text: String) -> String {
        return text + "\n```\n\n```"
    }

    // MARK: - Advanced Formatting (with selection support for future)

    /// Wraps selected text with bold markdown syntax
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with bold formatting applied to selection
    static func wrapBold(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])
        let wrapped = "**\(selectedText)**"
        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }

    /// Wraps selected text with italic markdown syntax
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with italic formatting applied to selection
    static func wrapItalic(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])
        let wrapped = "*\(selectedText)*"
        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }

    /// Wraps selected text with strikethrough markdown syntax
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with strikethrough formatting applied to selection
    static func wrapStrikethrough(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])
        let wrapped = "~~\(selectedText)~~"
        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }

    /// Wraps selected text with inline code markdown syntax
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with inline code formatting applied to selection
    static func wrapInlineCode(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])
        let wrapped = "`\(selectedText)`"
        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }

    /// Formats selected lines as blockquote
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with blockquote formatting applied to selected lines
    static func formatBlockquote(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])

        // Split into lines and add > prefix to each
        let lines = selectedText.components(separatedBy: .newlines)
        let quotedLines = lines.map { line in
            line.isEmpty ? ">" : "> \(line)"
        }
        let wrapped = quotedLines.joined(separator: "\n")

        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }

    /// Wraps selected text with code block markdown syntax
    /// - Parameters:
    ///   - text: The full text
    ///   - range: The NSRange of selected text
    /// - Returns: Text with code block formatting applied to selection
    static func wrapCodeBlock(in text: String, range: NSRange) -> String {
        guard let stringRange = Range(range, in: text) else { return text }
        let selectedText = String(text[stringRange])
        let wrapped = "```\n\(selectedText)\n```"
        var result = text
        result.replaceSubrange(stringRange, with: wrapped)
        return result
    }
}
