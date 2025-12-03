//
//  NavigateMenuActions.swift
//  AdlerScope
//
//  Navigate menu business logic:
//  - History navigation (back/forward)
//  - Heading navigation (jump to heading, previous/next heading)
//  - Line navigation (go to line)
//  - Code folding (fold/unfold sections)
//
//  Note: Full implementation requires TextEditor selection API and cursor manipulation,
//  which are not currently available in SwiftUI's TextEditor.
//

import SwiftUI
import Observation
import Markdown

/// Handles all Navigate menu actions
/// Provides navigation history, heading jumps, and code folding
@Observable
final class NavigateMenuActions {
    // MARK: - Navigation History

    /// Stack of visited positions for back navigation
    private var backStack: [NavigationPosition] = []

    /// Stack of positions for forward navigation
    private var forwardStack: [NavigationPosition] = []

    // MARK: - Document State

    /// Current rendered markdown document (for heading extraction)
    /// This should be set by the parent view/viewmodel
    var document: Document?

    /// Current cursor line (tracked by text view)
    var currentLine: Int = 0

    // MARK: - Computed Properties

    var canGoBack: Bool {
        !backStack.isEmpty
    }

    var canGoForward: Bool {
        !forwardStack.isEmpty
    }

    // MARK: - History Navigation

    /// Navigates back to previous position
    /// Placeholder - requires cursor/selection API to implement
    func goBack() {
        guard !backStack.isEmpty else { return }
        // let position = backStack.popLast()
        // forwardStack.append(currentPosition)
        // setCursorPosition(position) // Requires TextEditor selection API
    }

    /// Navigates forward to next position
    /// Placeholder - requires cursor/selection API to implement
    func goForward() {
        guard !forwardStack.isEmpty else { return }
        // let position = forwardStack.popLast()
        // backStack.append(currentPosition)
        // setCursorPosition(position) // Requires TextEditor selection API
    }

    // MARK: - Heading Navigation

    /// Opens heading selection sheet and jumps to selected heading
    /// Placeholder - requires cursor/selection API to implement
    func jumpToHeading() {
        // Would extract headings and show picker
        // let headings = extractHeadings(from: document)
        // showHeadingPicker(headings)
        // onSelect: setCursorPosition(heading.position)
    }

    /// Navigates to the previous heading in the document
    /// Placeholder - requires heading extraction and cursor API
    func previousHeading() {
        // Would find heading above current cursor position
        // let headings = extractHeadings(from: document)
        // let previousHeading = headings.last { $0.line < currentLine }
        // if let heading = previousHeading { setCursorPosition(heading.position) }
    }

    /// Navigates to the next heading in the document
    /// Placeholder - requires heading extraction and cursor API
    func nextHeading() {
        // Would find heading below current cursor position
        // let headings = extractHeadings(from: document)
        // let nextHeading = headings.first { $0.line > currentLine }
        // if let heading = nextHeading { setCursorPosition(heading.position) }
    }

    // MARK: - Line Navigation

    /// Opens go-to-line dialog and jumps to specified line
    /// Placeholder - requires cursor/selection API to implement
    func goToLine() {
        // Would show line number input dialog
        // onConfirm: setCursorToLine(lineNumber)
    }

    // MARK: - Code Folding

    /// State for folded sections (line ranges)
    private var foldedRanges: Set<ClosedRange<Int>> = []

    /// Folds the current section
    /// Placeholder - requires custom text view with folding support
    func foldSection() {
        // Would fold section at cursor
        // let range = getCurrentSectionRange()
        // foldedRanges.insert(range)
    }

    /// Unfolds the current section
    /// Placeholder - requires custom text view with folding support
    func unfoldSection() {
        // Would unfold section at cursor
        // let range = getCurrentSectionRange()
        // foldedRanges.remove(range)
    }

    /// Folds all sections in the document
    /// Placeholder - requires custom text view with folding support
    func foldAll() {
        // Would fold all headings/code blocks
        // let allSections = extractAllFoldableSections()
        // foldedRanges = Set(allSections)
    }

    /// Unfolds all sections in the document
    func unfoldAll() {
        foldedRanges.removeAll()
    }

    // MARK: - Helper Types

    /// Represents a position in the document
    private struct NavigationPosition: Hashable {
        let line: Int
        let column: Int
    }

    /// Information about a heading for navigation
    struct HeadingInfo {
        let text: String
        let level: Int
        let line: Int
    }

    // MARK: - Heading Extraction

    /// Extracts all headings from the document
    /// - Returns: Array of heading information sorted by line number
    func extractHeadings() -> [HeadingInfo] {
        guard let document = document else { return [] }

        var headings: [HeadingInfo] = []

        func walkChildren(_ markup: Markup, line: Int) {
            if let heading = markup as? Heading {
                let text = heading.plainText
                headings.append(HeadingInfo(text: text, level: heading.level, line: line))
            }

            for child in markup.children {
                walkChildren(child, line: line)
            }
        }

        var currentLine = 0
        for child in document.children {
            walkChildren(child, line: currentLine)
            // Note: Accurate line tracking requires source range from parser
            currentLine += 1
        }

        return headings
    }
}
