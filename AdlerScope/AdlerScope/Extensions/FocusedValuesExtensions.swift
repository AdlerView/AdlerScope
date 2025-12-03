//
//  FocusedValuesExtensions.swift
//  AdlerScope
//
//  Defines custom FocusedValues keys for AdlerScope commands.
//
//  FocusedValues allow commands in the menu bar to dynamically enable/disable
//  based on the currently focused view in the active window.
//
//  All FocusedValues must be Optional types (the default value is always nil).
//
//  Uses @Entry macro (modern approach since June 2023) instead of FocusedValueKey protocol.
//

import SwiftUI

// MARK: - FocusedValues Extensions

extension FocusedValues {

    // MARK: - Editor State

    /// Binding to editor text for command coordination
    @Entry var editorText: Binding<String>?

    /// Whether there is a text selection
    @Entry var hasSelection: Bool?

    // MARK: - File Menu Actions

    /// Action to create a new document
    @Entry var newDocument: (() -> Void)?

    /// Action to create a new tab
    @Entry var newTab: (() -> Void)?

    /// Action to open an existing document
    @Entry var openDocument: (() -> Void)?

    /// Action to open quickly (fuzzy finder)
    @Entry var openQuickly: (() -> Void)?

    /// Action to close the current document
    @Entry var closeDocument: (() -> Void)?

    /// Action to close the current tab
    @Entry var closeTab: (() -> Void)?

    /// Action to close the current window
    @Entry var closeWindow: (() -> Void)?

    /// Action to close all documents
    @Entry var closeAll: (() -> Void)?

    /// Action to save the current document
    @Entry var saveDocument: (() -> Void)?

    /// Action to save the current document as a new file
    @Entry var saveDocumentAs: (() -> Void)?

    /// Action to save all open documents
    @Entry var saveAll: (() -> Void)?

    /// Action to duplicate the current document
    @Entry var duplicateDocument: (() -> Void)?

    /// Action to rename the current document
    @Entry var renameDocument: (() -> Void)?

    /// Action to move the document to another location
    @Entry var moveDocument: (() -> Void)?

    /// Whether the current document has unsaved changes
    @Entry var hasUnsavedChanges: Bool?

    /// Action to revert to last saved version
    @Entry var revertToLastSaved: (() -> Void)?

    /// Action to revert to last opened version
    @Entry var revertToLastOpened: (() -> Void)?

    /// Action to browse all versions
    @Entry var browseAllVersions: (() -> Void)?

    /// Action to export document as PDF
    @Entry var exportToPDF: (() -> Void)?

    /// Action to export document as HTML
    @Entry var exportToHTML: (() -> Void)?

    /// Action to export document as DOCX
    @Entry var exportToDOCX: (() -> Void)?

    /// Action to export document as plain text
    @Entry var exportToPlainText: (() -> Void)?

    /// Action to import from Photos
    @Entry var importFromPhotos: (() -> Void)?

    /// Action to reveal document in Finder
    @Entry var showInFinder: (() -> Void)?

    /// Action to show document properties
    @Entry var showProperties: (() -> Void)?

    /// Action to show page setup dialog
    @Entry var pageSetup: (() -> Void)?

    /// Action to print the current document
    @Entry var printDocument: (() -> Void)?

    // MARK: - Edit Menu Actions

    /// Action to copy as markdown
    @Entry var copyAsMarkdown: (() -> Void)?

    /// Action to copy as HTML
    @Entry var copyAsHTML: (() -> Void)?

    /// Action to paste and match style
    @Entry var pasteAndMatchStyle: (() -> Void)?

    /// Action to find and replace
    @Entry var findAndReplace: (() -> Void)?

    /// Action to transform text to uppercase
    @Entry var makeUpperCase: (() -> Void)?

    /// Action to transform text to lowercase
    @Entry var makeLowerCase: (() -> Void)?

    /// Action to capitalize text
    @Entry var capitalize: (() -> Void)?

    /// Action to insert a markdown link
    @Entry var insertLink: (() -> Void)?

    /// Action to insert an image
    @Entry var insertImage: (() -> Void)?

    /// Action to insert a table
    @Entry var insertTable: (() -> Void)?

    /// Action to insert a code block
    @Entry var insertCodeBlock: (() -> Void)?

    /// Action to insert a horizontal rule
    @Entry var insertHorizontalRule: (() -> Void)?

    /// Action to insert a footnote
    @Entry var insertFootnote: (() -> Void)?

    /// Action to insert table of contents
    @Entry var insertTableOfContents: (() -> Void)?

    /// Action to insert current date
    @Entry var insertCurrentDate: (() -> Void)?

    /// Action to insert current time
    @Entry var insertCurrentTime: (() -> Void)?

    // MARK: - View Menu Actions

    /// Action to show editor-only mode
    @Entry var showEditor: (() -> Void)?

    /// Action to show preview-only mode
    @Entry var showPreview: (() -> Void)?

    /// Action to show split view (editor + preview)
    @Entry var showSplitView: (() -> Void)?

    /// Action to swap panes in split view
    @Entry var swapPanes: (() -> Void)?

    /// Action to show document structure panel
    @Entry var showDocumentStructure: (() -> Void)?

    /// Action to show word count panel
    @Entry var showWordCount: (() -> Void)?

    /// Action to toggle line numbers
    @Entry var toggleLineNumbers: (() -> Void)?

    /// Action to toggle invisible characters
    @Entry var toggleInvisibles: (() -> Void)?

    /// Action to toggle typewriter mode
    @Entry var toggleTypewriterMode: (() -> Void)?

    /// Action to toggle focus mode
    @Entry var toggleFocusMode: (() -> Void)?

    /// Action to set preview theme to default
    @Entry var setPreviewThemeDefault: (() -> Void)?

    /// Action to set preview theme to GitHub
    @Entry var setPreviewThemeGitHub: (() -> Void)?

    /// Action to set preview theme to Academic
    @Entry var setPreviewThemeAcademic: (() -> Void)?

    /// Action to set preview theme to Minimal
    @Entry var setPreviewThemeMinimal: (() -> Void)?

    /// Action to zoom in (increase font size)
    @Entry var zoomIn: (() -> Void)?

    /// Action to zoom out (decrease font size)
    @Entry var zoomOut: (() -> Void)?

    /// Action to reset zoom to default size
    @Entry var resetZoom: (() -> Void)?

    // MARK: - Format Menu Actions

    /// Action to toggle bold formatting
    @Entry var toggleBold: (() -> Void)?

    /// Action to toggle italic formatting
    @Entry var toggleItalic: (() -> Void)?

    /// Action to toggle inline code formatting
    @Entry var toggleInlineCode: (() -> Void)?

    /// Action to toggle strikethrough formatting
    @Entry var toggleStrikethrough: (() -> Void)?

    /// Action to toggle highlight formatting
    @Entry var toggleHighlight: (() -> Void)?

    /// Action to make current line Heading 1
    @Entry var makeHeading1: (() -> Void)?

    /// Action to make current line Heading 2
    @Entry var makeHeading2: (() -> Void)?

    /// Action to make current line Heading 3
    @Entry var makeHeading3: (() -> Void)?

    /// Action to make current line Heading 4
    @Entry var makeHeading4: (() -> Void)?

    /// Action to make current line Heading 5
    @Entry var makeHeading5: (() -> Void)?

    /// Action to make current line Heading 6
    @Entry var makeHeading6: (() -> Void)?

    /// Action to increase heading level
    @Entry var increaseHeadingLevel: (() -> Void)?

    /// Action to decrease heading level
    @Entry var decreaseHeadingLevel: (() -> Void)?

    /// Action to remove heading
    @Entry var removeHeading: (() -> Void)?

    /// Action to convert to bullet list
    @Entry var makeBulletList: (() -> Void)?

    /// Action to convert to numbered list
    @Entry var makeNumberedList: (() -> Void)?

    /// Action to convert to task list
    @Entry var makeTaskList: (() -> Void)?

    /// Action to increase indentation
    @Entry var increaseIndent: (() -> Void)?

    /// Action to decrease indentation
    @Entry var decreaseIndent: (() -> Void)?

    /// Action to toggle task completion
    @Entry var toggleTask: (() -> Void)?

    /// Action to convert to blockquote
    @Entry var makeBlockquote: (() -> Void)?

    /// Action to convert to code block
    @Entry var makeCodeBlock: (() -> Void)?

    /// Action to insert table
    @Entry var formatInsertTable: (() -> Void)?

    /// Action to add row above
    @Entry var addRowAbove: (() -> Void)?

    /// Action to add row below
    @Entry var addRowBelow: (() -> Void)?

    /// Action to add column left
    @Entry var addColumnLeft: (() -> Void)?

    /// Action to add column right
    @Entry var addColumnRight: (() -> Void)?

    /// Action to delete current row
    @Entry var deleteRow: (() -> Void)?

    /// Action to delete current column
    @Entry var deleteColumn: (() -> Void)?

    /// Action to delete entire table
    @Entry var deleteTable: (() -> Void)?

    /// Action to clear all formatting
    @Entry var clearFormatting: (() -> Void)?

    /// Action to toggle markdown syntax visibility
    @Entry var toggleMarkdownSyntax: (() -> Void)?

    // MARK: - Navigate Menu Actions

    /// Action to navigate back in history
    @Entry var goBack: (() -> Void)?

    /// Action to navigate forward in history
    @Entry var goForward: (() -> Void)?

    /// Action to show jump-to-heading picker
    @Entry var jumpToHeading: (() -> Void)?

    /// Action to go to specific line
    @Entry var goToLine: (() -> Void)?

    /// Action to go to previous heading
    @Entry var previousHeading: (() -> Void)?

    /// Action to go to next heading
    @Entry var nextHeading: (() -> Void)?

    /// Action to fold all sections
    @Entry var foldAll: (() -> Void)?

    /// Action to unfold all sections
    @Entry var unfoldAll: (() -> Void)?

    /// Action to fold current section
    @Entry var foldSection: (() -> Void)?

    /// Action to unfold current section
    @Entry var unfoldSection: (() -> Void)?

    // MARK: - Help Menu Actions

    /// Action to show markdown guide
    @Entry var showMarkdownGuide: (() -> Void)?

    /// Action to show keyboard shortcuts
    @Entry var showKeyboardShortcuts: (() -> Void)?

    /// Action to show release notes
    @Entry var showReleaseNotes: (() -> Void)?

    /// Action to report an issue
    @Entry var reportIssue: (() -> Void)?
}
