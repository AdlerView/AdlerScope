//
//  EditMenuActions.swift
//  AdlerScope
//
//  Edit menu business logic:
//  - Undo/redo stack management
//  - Copy operations (markdown, HTML)
//  - Text transformations (uppercase, lowercase, capitalize)
//  - Insert operations (link, image, table, code block, etc.)
//

import SwiftUI
import Observation

/// Handles all Edit menu actions
/// Manages undo/redo state, copy variants, transformations, and insert operations
@Observable
final class EditMenuActions {
    // MARK: - Undo/Redo Stack

    private var undoStack: [String] = []
    private var redoStack: [String] = []
    private let maxUndoStackSize = 50

    // MARK: - State

    /// Text binding for live updates
    /// This is bound externally by the view that owns the text
    var text: String = ""

    /// Pending text insertion at cursor (consumed by NSTextViewWrapper)
    var pendingInsertion: String?

    // MARK: - Computed Properties

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var canRedo: Bool {
        !redoStack.isEmpty
    }

    // MARK: - Undo/Redo Operations

    /// Records a text change for undo/redo (only significant changes)
    /// - Parameters:
    ///   - oldText: Previous text state
    ///   - newText: New text state
    func recordChange(oldText: String, newText: String) {
        // Only record significant changes (more than 1 character difference)
        guard abs(oldText.count - newText.count) > 1 else { return }

        undoStack.append(oldText)
        redoStack.removeAll()

        // Limit stack size
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
    }

    /// Performs undo operation
    func performUndo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(text)
        text = previous
    }

    /// Performs redo operation
    func performRedo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(text)
        text = next
    }

    // MARK: - Copy Operations

    /// Copies text as markdown (preserves markdown syntax)
    /// Placeholder - requires pasteboard integration
    func copyAsMarkdown() {
        // Would copy selected text as-is (markdown format)
        // NSPasteboard.general.setString(selectedText, forType: .string)
    }

    /// Copies text as HTML (converts markdown to HTML)
    /// Placeholder - requires markdown-to-HTML conversion and pasteboard integration
    func copyAsHTML() {
        // Would convert selected markdown to HTML and copy
        // let html = convertMarkdownToHTML(selectedText)
        // NSPasteboard.general.setString(html, forType: .html)
    }

    /// Pastes and matches editor style
    /// Placeholder - requires pasteboard integration
    func pasteAndMatchStyle() {
        // Would paste plain text, stripping formatting
        // let plainText = NSPasteboard.general.string(forType: .string)
        // insertAtCursor(plainText)
    }

    // MARK: - Text Transformations

    /// Transforms selected text to uppercase
    /// Placeholder - requires selection API
    func makeUpperCase() {
        // Would transform selected text: selectedText.uppercased()
    }

    /// Transforms selected text to lowercase
    /// Placeholder - requires selection API
    func makeLowerCase() {
        // Would transform selected text: selectedText.lowercased()
    }

    /// Capitalizes selected text
    /// Placeholder - requires selection API
    func capitalize() {
        // Would transform selected text: selectedText.capitalized
    }

    // MARK: - Insert Operations

    /// Inserts link markdown template [text](url)
    func insertLink() {
        pendingInsertion = "[](url)"
    }

    /// Inserts image markdown template ![alt](url)
    func insertImage() {
        pendingInsertion = "![](url)"
    }

    /// Inserts table markdown template
    func insertTable() {
        let tableTemplate = """

| Column 1 | Column 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
"""
        pendingInsertion = tableTemplate
    }

    /// Inserts code block with language placeholder
    func insertCodeBlock() {
        pendingInsertion = "\n```\n\n```"
    }

    /// Inserts horizontal rule
    func insertHorizontalRule() {
        pendingInsertion = "\n---\n"
    }

    /// Inserts footnote reference and definition
    func insertFootnote() {
        pendingInsertion = "[^1]\n\n[^1]: "
    }

    /// Inserts table of contents placeholder
    func insertTableOfContents() {
        pendingInsertion = "\n[[toc]]\n"
    }

    /// Inserts current date in ISO format
    func insertCurrentDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        pendingInsertion = formatter.string(from: Date())
    }

    /// Inserts current time in 24-hour format
    func insertCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        pendingInsertion = formatter.string(from: Date())
    }
}
