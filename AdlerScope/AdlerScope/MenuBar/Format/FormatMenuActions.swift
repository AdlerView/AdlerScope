//
//  FormatMenuActions.swift
//  AdlerScope
//
//  Format menu business logic:
//  - Emphasis formatting (bold, italic, strikethrough, inline code, highlight)
//  - Heading insertion and manipulation (H1-H6, increase/decrease level, remove)
//  - List creation (bullet, numbered, task) and toggle task
//  - Block formatting (blockquote, code block)
//  - Table operations (insert, add/delete rows/columns)
//  - Indentation (increase, decrease)
//  - Clear formatting
//

import SwiftUI
import Observation

/// Handles all Format menu actions
/// Wraps MarkdownFormatter utilities and manages text formatting state
@Observable
final class FormatMenuActions {
    // MARK: - State

    /// Text binding for live formatting updates
    /// This is bound externally by the view that owns the text
    var text: String = ""

    /// Current cursor position (tracked by NSTextView)
    var cursorPosition: Int = 0

    /// Pending text insertion at cursor (consumed by NSTextViewWrapper)
    var pendingInsertion: String?

    // MARK: - Emphasis Formatting

    /// Toggles bold formatting - inserts ** markers at cursor
    func toggleBold() {
        pendingInsertion = "****"
    }

    /// Toggles italic formatting - inserts * markers at cursor
    func toggleItalic() {
        pendingInsertion = "**"
    }

    /// Toggles strikethrough formatting - inserts ~~ markers at cursor
    func toggleStrikethrough() {
        pendingInsertion = "~~~~"
    }

    /// Toggles inline code formatting - inserts ` markers at cursor
    func toggleInlineCode() {
        pendingInsertion = "``"
    }

    /// Toggles highlight formatting - inserts == markers at cursor
    func toggleHighlight() {
        pendingInsertion = "===="
    }

    // MARK: - Heading Formatting

    /// Inserts Heading 1 marker (# ) at cursor
    func makeHeading1() {
        insertHeading(level: 1)
    }

    /// Inserts Heading 2 marker (## ) at cursor
    func makeHeading2() {
        insertHeading(level: 2)
    }

    /// Inserts Heading 3 marker (### ) at cursor
    func makeHeading3() {
        insertHeading(level: 3)
    }

    /// Inserts Heading 4 marker (#### ) at cursor
    func makeHeading4() {
        insertHeading(level: 4)
    }

    /// Inserts Heading 5 marker (##### ) at cursor
    func makeHeading5() {
        insertHeading(level: 5)
    }

    /// Inserts Heading 6 marker (###### ) at cursor
    func makeHeading6() {
        insertHeading(level: 6)
    }

    /// Generic heading insertion helper
    /// - Parameter level: Heading level (1-6)
    private func insertHeading(level: Int) {
        let markers = String(repeating: "#", count: level)
        pendingInsertion = "\n\(markers) "
    }

    /// Increases heading level (e.g., H2 -> H3)
    /// Placeholder - requires line context and parsing
    func increaseHeadingLevel() {
        // Would find current line, detect heading level, increment (max 6)
        // let currentLevel = detectHeadingLevel(atLine: currentLine)
        // if currentLevel < 6 { replaceHeading(level: currentLevel + 1) }
    }

    /// Decreases heading level (e.g., H3 -> H2)
    /// Placeholder - requires line context and parsing
    func decreaseHeadingLevel() {
        // Would find current line, detect heading level, decrement (min 1)
        // let currentLevel = detectHeadingLevel(atLine: currentLine)
        // if currentLevel > 1 { replaceHeading(level: currentLevel - 1) }
    }

    /// Removes heading from current line
    /// Placeholder - requires line context and parsing
    func removeHeading() {
        // Would find current line and remove leading # characters
        // removeLeadingHashes(atLine: currentLine)
    }

    // MARK: - List Formatting

    /// Inserts bullet list item marker (- ) at cursor
    func makeBulletList() {
        pendingInsertion = "\n- "
    }

    /// Inserts numbered list item marker (1. ) at cursor
    func makeNumberedList() {
        pendingInsertion = "\n1. "
    }

    /// Inserts task list item marker (- [ ] ) at cursor
    func makeTaskList() {
        pendingInsertion = "\n- [ ] "
    }

    /// Toggles task completion state ([ ] <-> [x])
    /// Placeholder - requires line context and parsing
    func toggleTask() {
        // Would find task checkbox on current line and toggle
        // if line.contains("- [ ]") { replace with "- [x]" }
        // else if line.contains("- [x]") { replace with "- [ ]" }
    }

    // MARK: - Block Formatting

    /// Inserts blockquote marker at cursor (> )
    func makeBlockquote() {
        pendingInsertion = "\n> "
    }

    /// Inserts code block template at cursor
    func makeCodeBlock() {
        pendingInsertion = "\n```\n\n```"
    }

    // MARK: - Indentation

    /// Increases indentation by adding 2 spaces at cursor
    func increaseIndent() {
        pendingInsertion = "  "
    }

    /// Decreases indentation by removing trailing spaces
    /// Placeholder - requires line context
    func decreaseIndent() {
        // Would remove leading whitespace from current line
        // Proper implementation requires cursor/line context
    }

    // MARK: - Table Operations

    /// Inserts a new table at cursor
    func insertTable() {
        let tableTemplate = """

| Column 1 | Column 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
"""
        pendingInsertion = tableTemplate
    }

    /// Adds a row above the current row
    /// Placeholder - requires table context and cursor position
    func addRowAbove() {
        // Would detect if cursor is in table, find row, insert above
    }

    /// Adds a row below the current row
    /// Placeholder - requires table context and cursor position
    func addRowBelow() {
        // Would detect if cursor is in table, find row, insert below
    }

    /// Adds a column to the left of the current column
    /// Placeholder - requires table context and cursor position
    func addColumnLeft() {
        // Would detect if cursor is in table, find column, insert left
    }

    /// Adds a column to the right of the current column
    /// Placeholder - requires table context and cursor position
    func addColumnRight() {
        // Would detect if cursor is in table, find column, insert right
    }

    /// Deletes the current row
    /// Placeholder - requires table context and cursor position
    func deleteRow() {
        // Would detect if cursor is in table, find row, delete it
    }

    /// Deletes the current column
    /// Placeholder - requires table context and cursor position
    func deleteColumn() {
        // Would detect if cursor is in table, find column, delete it
    }

    /// Deletes the entire table
    /// Placeholder - requires table context and cursor position
    func deleteTable() {
        // Would detect if cursor is in table, select entire table, delete
    }

    // MARK: - Clear Formatting

    /// Removes all markdown formatting from selection
    /// Placeholder - requires selection API and markdown parsing
    func clearFormatting() {
        // Would strip markdown syntax from selected text:
        // - Remove **, *, ~~, `, ==, etc.
        // - Remove heading markers
        // - Remove list markers
        // - Preserve plain text content
    }

    /// Toggles visibility of markdown syntax in editor
    /// Placeholder - requires editor rendering mode toggle
    func toggleMarkdownSyntax() {
        // Would toggle between showing/hiding markdown syntax
        // This affects editor rendering, not the text content
    }
}
