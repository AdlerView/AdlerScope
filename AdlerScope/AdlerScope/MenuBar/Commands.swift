import SwiftUI

/// AdlerScope menu bar commands
///
/// Provides custom menu items and integrates with SwiftUI's Commands system.
/// Uses FocusedValue to make commands contextually available based on the active window.
///
/// Menu structure based on TextDown architecture specification.
///
struct Commands: SwiftUI.Commands {

    // MARK: - Environment

    @Environment(\.openWindow) var openWindow
    @Environment(\.openURL) var openURL

    // MARK: - File Menu Focused Values

    @FocusedValue(\.newDocument) var newDocument
    @FocusedValue(\.newTab) var newTab
    @FocusedValue(\.openDocument) var openDocument
    @FocusedValue(\.openQuickly) var openQuickly
    @FocusedValue(\.closeDocument) var closeDocument
    @FocusedValue(\.closeTab) var closeTab
    @FocusedValue(\.closeWindow) var closeWindow
    @FocusedValue(\.closeAll) var closeAll
    @FocusedValue(\.saveDocument) var saveDocument
    @FocusedValue(\.saveDocumentAs) var saveDocumentAs
    @FocusedValue(\.saveAll) var saveAll
    @FocusedValue(\.duplicateDocument) var duplicateDocument
    @FocusedValue(\.renameDocument) var renameDocument
    @FocusedValue(\.moveDocument) var moveDocument
    @FocusedValue(\.hasUnsavedChanges) var hasUnsavedChanges
    @FocusedValue(\.revertToLastSaved) var revertToLastSaved
    @FocusedValue(\.revertToLastOpened) var revertToLastOpened
    @FocusedValue(\.browseAllVersions) var browseAllVersions
    @FocusedValue(\.exportToPDF) var exportToPDF
    @FocusedValue(\.exportToHTML) var exportToHTML
    @FocusedValue(\.exportToDOCX) var exportToDOCX
    @FocusedValue(\.exportToPlainText) var exportToPlainText
    @FocusedValue(\.showInFinder) var showInFinder
    @FocusedValue(\.showProperties) var showProperties
    @FocusedValue(\.pageSetup) var pageSetup
    @FocusedValue(\.printDocument) var printDocument

    // MARK: - Edit Menu Focused Values

    @FocusedValue(\.copyAsMarkdown) var copyAsMarkdown
    @FocusedValue(\.copyAsHTML) var copyAsHTML
    @FocusedValue(\.pasteAndMatchStyle) var pasteAndMatchStyle
    @FocusedValue(\.findAndReplace) var findAndReplace
    @FocusedValue(\.makeUpperCase) var makeUpperCase
    @FocusedValue(\.makeLowerCase) var makeLowerCase
    @FocusedValue(\.capitalize) var capitalize
    @FocusedValue(\.insertLink) var insertLink
    @FocusedValue(\.insertImage) var insertImage
    @FocusedValue(\.insertTable) var insertTable
    @FocusedValue(\.insertCodeBlock) var insertCodeBlock
    @FocusedValue(\.insertHorizontalRule) var insertHorizontalRule
    @FocusedValue(\.insertFootnote) var insertFootnote
    @FocusedValue(\.insertTableOfContents) var insertTableOfContents
    @FocusedValue(\.insertCurrentDate) var insertCurrentDate
    @FocusedValue(\.insertCurrentTime) var insertCurrentTime

    // MARK: - View Menu Focused Values

    @FocusedValue(\.showEditor) var showEditor
    @FocusedValue(\.showPreview) var showPreview
    @FocusedValue(\.showSplitView) var showSplitView
    @FocusedValue(\.swapPanes) var swapPanes
    @FocusedValue(\.showDocumentStructure) var showDocumentStructure
    @FocusedValue(\.showWordCount) var showWordCount
    @FocusedValue(\.toggleLineNumbers) var toggleLineNumbers
    @FocusedValue(\.toggleInvisibles) var toggleInvisibles
    @FocusedValue(\.toggleTypewriterMode) var toggleTypewriterMode
    @FocusedValue(\.toggleFocusMode) var toggleFocusMode
    @FocusedValue(\.setPreviewThemeDefault) var setPreviewThemeDefault
    @FocusedValue(\.setPreviewThemeGitHub) var setPreviewThemeGitHub
    @FocusedValue(\.setPreviewThemeAcademic) var setPreviewThemeAcademic
    @FocusedValue(\.setPreviewThemeMinimal) var setPreviewThemeMinimal
    @FocusedValue(\.zoomIn) var zoomIn
    @FocusedValue(\.zoomOut) var zoomOut
    @FocusedValue(\.resetZoom) var resetZoom

    // MARK: - Format Menu Focused Values

    @FocusedValue(\.toggleBold) var toggleBold
    @FocusedValue(\.toggleItalic) var toggleItalic
    @FocusedValue(\.toggleInlineCode) var toggleInlineCode
    @FocusedValue(\.toggleStrikethrough) var toggleStrikethrough
    @FocusedValue(\.toggleHighlight) var toggleHighlight
    @FocusedValue(\.makeHeading1) var makeHeading1
    @FocusedValue(\.makeHeading2) var makeHeading2
    @FocusedValue(\.makeHeading3) var makeHeading3
    @FocusedValue(\.makeHeading4) var makeHeading4
    @FocusedValue(\.makeHeading5) var makeHeading5
    @FocusedValue(\.makeHeading6) var makeHeading6
    @FocusedValue(\.increaseHeadingLevel) var increaseHeadingLevel
    @FocusedValue(\.decreaseHeadingLevel) var decreaseHeadingLevel
    @FocusedValue(\.removeHeading) var removeHeading
    @FocusedValue(\.makeBulletList) var makeBulletList
    @FocusedValue(\.makeNumberedList) var makeNumberedList
    @FocusedValue(\.makeTaskList) var makeTaskList
    @FocusedValue(\.increaseIndent) var increaseIndent
    @FocusedValue(\.decreaseIndent) var decreaseIndent
    @FocusedValue(\.toggleTask) var toggleTask
    @FocusedValue(\.makeBlockquote) var makeBlockquote
    @FocusedValue(\.makeCodeBlock) var makeCodeBlock
    @FocusedValue(\.formatInsertTable) var formatInsertTable
    @FocusedValue(\.addRowAbove) var addRowAbove
    @FocusedValue(\.addRowBelow) var addRowBelow
    @FocusedValue(\.addColumnLeft) var addColumnLeft
    @FocusedValue(\.addColumnRight) var addColumnRight
    @FocusedValue(\.deleteRow) var deleteRow
    @FocusedValue(\.deleteColumn) var deleteColumn
    @FocusedValue(\.deleteTable) var deleteTable
    @FocusedValue(\.clearFormatting) var clearFormatting
    @FocusedValue(\.toggleMarkdownSyntax) var toggleMarkdownSyntax

    // MARK: - Navigate Menu Focused Values

    @FocusedValue(\.goBack) var goBack
    @FocusedValue(\.goForward) var goForward
    @FocusedValue(\.jumpToHeading) var jumpToHeading
    @FocusedValue(\.goToLine) var goToLine
    @FocusedValue(\.previousHeading) var previousHeading
    @FocusedValue(\.nextHeading) var nextHeading
    @FocusedValue(\.foldAll) var foldAll
    @FocusedValue(\.unfoldAll) var unfoldAll
    @FocusedValue(\.foldSection) var foldSection
    @FocusedValue(\.unfoldSection) var unfoldSection

    // MARK: - Help Menu Focused Values

    @FocusedValue(\.showMarkdownGuide) var showMarkdownGuide
    @FocusedValue(\.showKeyboardShortcuts) var showKeyboardShortcuts
    @FocusedValue(\.showReleaseNotes) var showReleaseNotes
    @FocusedValue(\.reportIssue) var reportIssue

    // MARK: - Body

    var body: some SwiftUI.Commands {
        // Group 1: File Menu
        Group {
            fileMenuNewItems
            fileMenuSaveItems
            fileMenuExportItems
            fileMenuPrintItems
        }

        // Group 2: Edit Menu
        Group {
            TextEditingCommands()
            editMenuPasteboardItems
            editMenuTextEditingItems
        }

        // Group 3: View Menu
        Group {
            SidebarCommands()
            ToolbarCommands()
            viewMenuItems
        }

        // Group 4: Format & Navigate Menus
        Group {
            formatMenu
            navigateMenu
        }

        // Group 5: App & Help Menus
        Group {
            appMenuItems
            helpMenuItems
        }
    }

    // MARK: - File Menu Components

    private var fileMenuNewItems: some SwiftUI.Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") {
                newDocument?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(newDocument == nil)

            Button("New Tab") {
                newTab?()
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(newTab == nil)

            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Open...") {
                openDocument?()
            }
            .keyboardShortcut("o", modifiers: .command)
            .disabled(openDocument == nil)

            Button("Open Quickly...") {
                openQuickly?()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .disabled(openQuickly == nil)
        }
    }

    private var fileMenuSaveItems: some SwiftUI.Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Close") {
                closeDocument?()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(closeDocument == nil)

            Button("Close Tab") {
                closeTab?()
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
            .disabled(closeTab == nil)

            Button("Close Window") {
                closeWindow?()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
            .disabled(closeWindow == nil)

            Button("Close All") {
                closeAll?()
            }
            .keyboardShortcut("w", modifiers: [.command, .option, .shift])
            .disabled(closeAll == nil)

            Divider()

            Button("Save") {
                saveDocument?()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(saveDocument == nil || hasUnsavedChanges == false)

            Button("Save As...") {
                saveDocumentAs?()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(saveDocumentAs == nil)

            Button("Save All") {
                saveAll?()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            .disabled(saveAll == nil)

            Button("Duplicate") {
                duplicateDocument?()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(duplicateDocument == nil)

            Button("Rename...") {
                renameDocument?()
            }
            .disabled(renameDocument == nil)

            Button("Move To...") {
                moveDocument?()
            }
            .disabled(moveDocument == nil)

            Divider()

            Menu("Revert To") {
                Button("Last Saved") {
                    revertToLastSaved?()
                }
                .disabled(revertToLastSaved == nil)

                Button("Last Opened") {
                    revertToLastOpened?()
                }
                .disabled(revertToLastOpened == nil)

                Divider()

                Button("Browse All Versions...") {
                    browseAllVersions?()
                }
                .disabled(browseAllVersions == nil)
            }
        }
    }

    private var fileMenuExportItems: some SwiftUI.Commands {
        CommandGroup(replacing: .importExport) {
            Menu("Export") {
                Button("Export as PDF...") {
                    exportToPDF?()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(exportToPDF == nil)

                Button("Export as HTML...") {
                    exportToHTML?()
                }
                .keyboardShortcut("e", modifiers: [.command, .option, .shift])
                .disabled(exportToHTML == nil)

                Button("Export as DOCX...") {
                    exportToDOCX?()
                }
                .disabled(exportToDOCX == nil)

                Button("Export as Plain Text...") {
                    exportToPlainText?()
                }
                .disabled(exportToPlainText == nil)
            }

            Divider()

            Button("Show in Finder") {
                showInFinder?()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(showInFinder == nil)

            Button("Show Properties") {
                showProperties?()
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(showProperties == nil)
        }
    }

    private var fileMenuPrintItems: some SwiftUI.Commands {
        CommandGroup(replacing: .printItem) {
            Button("Page Setup...") {
                pageSetup?()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(pageSetup == nil)

            Button("Print...") {
                printDocument?()
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(printDocument == nil)
        }
    }

    // MARK: - Edit Menu Components

    private var editMenuPasteboardItems: some SwiftUI.Commands {
        CommandGroup(after: .pasteboard) {
            Button("Copy as Markdown") {
                copyAsMarkdown?()
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
            .disabled(copyAsMarkdown == nil)

            Button("Copy as HTML") {
                copyAsHTML?()
            }
            .keyboardShortcut("c", modifiers: [.command, .option, .shift])
            .disabled(copyAsHTML == nil)

            Divider()

            Button("Paste and Match Style") {
                pasteAndMatchStyle?()
            }
            .keyboardShortcut("v", modifiers: [.command, .option, .shift])
            .disabled(pasteAndMatchStyle == nil)
        }
    }

    private var editMenuTextEditingItems: some SwiftUI.Commands {
        CommandGroup(after: .textEditing) {
            Divider()

            Menu("Transformations") {
                Button("Make Upper Case") {
                    makeUpperCase?()
                }
                .disabled(makeUpperCase == nil)

                Button("Make Lower Case") {
                    makeLowerCase?()
                }
                .disabled(makeLowerCase == nil)

                Button("Capitalize") {
                    capitalize?()
                }
                .disabled(capitalize == nil)
            }

            Divider()

            Menu("Insert") {
                Button("Link...") {
                    insertLink?()
                }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(insertLink == nil)

                Button("Image...") {
                    insertImage?()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(insertImage == nil)

                Button("Table...") {
                    insertTable?()
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
                .disabled(insertTable == nil)

                Button("Code Block") {
                    insertCodeBlock?()
                }
                .disabled(insertCodeBlock == nil)

                Button("Horizontal Rule") {
                    insertHorizontalRule?()
                }
                .disabled(insertHorizontalRule == nil)

                Button("Footnote") {
                    insertFootnote?()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(insertFootnote == nil)

                Button("Table of Contents") {
                    insertTableOfContents?()
                }
                .keyboardShortcut(.return, modifiers: [.command, .option])
                .disabled(insertTableOfContents == nil)

                Divider()

                Button("Current Date") {
                    insertCurrentDate?()
                }
                .keyboardShortcut("d", modifiers: [.control, .command])
                .disabled(insertCurrentDate == nil)

                Button("Current Time") {
                    insertCurrentTime?()
                }
                .keyboardShortcut("t", modifiers: [.control, .command])
                .disabled(insertCurrentTime == nil)
            }
        }
    }

    // MARK: - View Menu Components

    private var viewMenuItems: some SwiftUI.Commands {
        CommandGroup(after: .toolbar) {
            Divider()

            Menu("View Mode") {
                Button("Editor Only") {
                    showEditor?()
                }
                .keyboardShortcut("1", modifiers: .command)
                .disabled(showEditor == nil)

                Button("Preview Only") {
                    showPreview?()
                }
                .keyboardShortcut("2", modifiers: .command)
                .disabled(showPreview == nil)

                Button("Split View") {
                    showSplitView?()
                }
                .keyboardShortcut("3", modifiers: .command)
                .disabled(showSplitView == nil)

                Divider()

                Button("Swap Panes") {
                    swapPanes?()
                }
                .keyboardShortcut("3", modifiers: [.command, .option])
                .disabled(swapPanes == nil)
            }

            Divider()

            Button("Show Document Structure") {
                showDocumentStructure?()
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
            .disabled(showDocumentStructure == nil)

            Button("Show Word Count") {
                showWordCount?()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
            .disabled(showWordCount == nil)

            Button("Show Line Numbers") {
                toggleLineNumbers?()
            }
            .keyboardShortcut("l", modifiers: [.control, .command])
            .disabled(toggleLineNumbers == nil)

            Button("Show Invisibles") {
                toggleInvisibles?()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            .disabled(toggleInvisibles == nil)

            Divider()

            Button("Typewriter Mode") {
                toggleTypewriterMode?()
            }
            .keyboardShortcut("m", modifiers: [.control, .command])
            .disabled(toggleTypewriterMode == nil)

            Button("Focus Mode") {
                toggleFocusMode?()
            }
            .keyboardShortcut("f", modifiers: [.command, .option, .shift])
            .disabled(toggleFocusMode == nil)

            Divider()

            Menu("Preview Theme") {
                Button("Default") {
                    setPreviewThemeDefault?()
                }
                .disabled(setPreviewThemeDefault == nil)

                Button("GitHub") {
                    setPreviewThemeGitHub?()
                }
                .disabled(setPreviewThemeGitHub == nil)

                Button("Academic") {
                    setPreviewThemeAcademic?()
                }
                .disabled(setPreviewThemeAcademic == nil)

                Button("Minimal") {
                    setPreviewThemeMinimal?()
                }
                .disabled(setPreviewThemeMinimal == nil)
            }

            Divider()

            Button("Zoom In") {
                zoomIn?()
            }
            .keyboardShortcut("+", modifiers: .command)
            .disabled(zoomIn == nil)

            Button("Zoom Out") {
                zoomOut?()
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(zoomOut == nil)

            Button("Actual Size") {
                resetZoom?()
            }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(resetZoom == nil)
        }
    }

    // MARK: - Format Menu

    private var formatMenu: some SwiftUI.Commands {
        CommandMenu("Format") {
            Menu("Font") {
                Button("Show Fonts") {
                    NSFontManager.shared.orderFrontFontPanel(nil as Any?)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Bigger") {
                    zoomIn?()
                }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(zoomIn == nil)

                Button("Smaller") {
                    zoomOut?()
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(zoomOut == nil)
            }

            Divider()

            Button("Strong (Bold)") {
                toggleBold?()
            }
            .keyboardShortcut("b", modifiers: .command)
            .disabled(toggleBold == nil)

            Button("Emphasis (Italic)") {
                toggleItalic?()
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(toggleItalic == nil)

            Button("Inline Code") {
                toggleInlineCode?()
            }
            .disabled(toggleInlineCode == nil)

            Button("Strikethrough") {
                toggleStrikethrough?()
            }
            .keyboardShortcut("x", modifiers: [.command, .shift])
            .disabled(toggleStrikethrough == nil)

            Button("Highlight") {
                toggleHighlight?()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(toggleHighlight == nil)

            Divider()

            Menu("Heading") {
                Button("Heading 1") {
                    makeHeading1?()
                }
                .keyboardShortcut("1", modifiers: [.command, .control])
                .disabled(makeHeading1 == nil)

                Button("Heading 2") {
                    makeHeading2?()
                }
                .keyboardShortcut("2", modifiers: [.command, .control])
                .disabled(makeHeading2 == nil)

                Button("Heading 3") {
                    makeHeading3?()
                }
                .keyboardShortcut("3", modifiers: [.command, .control])
                .disabled(makeHeading3 == nil)

                Button("Heading 4") {
                    makeHeading4?()
                }
                .keyboardShortcut("4", modifiers: [.command, .control])
                .disabled(makeHeading4 == nil)

                Button("Heading 5") {
                    makeHeading5?()
                }
                .keyboardShortcut("5", modifiers: [.command, .control])
                .disabled(makeHeading5 == nil)

                Button("Heading 6") {
                    makeHeading6?()
                }
                .keyboardShortcut("6", modifiers: [.command, .control])
                .disabled(makeHeading6 == nil)

                Divider()

                Button("Increase Level") {
                    increaseHeadingLevel?()
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(increaseHeadingLevel == nil)

                Button("Decrease Level") {
                    decreaseHeadingLevel?()
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(decreaseHeadingLevel == nil)

                Button("Remove Heading") {
                    removeHeading?()
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                .disabled(removeHeading == nil)
            }

            Divider()

            Menu("Lists") {
                Button("Bulleted List") {
                    makeBulletList?()
                }
                .keyboardShortcut("l", modifiers: [.command, .option])
                .disabled(makeBulletList == nil)

                Button("Numbered List") {
                    makeNumberedList?()
                }
                .keyboardShortcut("l", modifiers: [.command, .option, .shift])
                .disabled(makeNumberedList == nil)

                Button("Task List") {
                    makeTaskList?()
                }
                .disabled(makeTaskList == nil)

                Divider()

                Button("Indent") {
                    increaseIndent?()
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(increaseIndent == nil)

                Button("Outdent") {
                    decreaseIndent?()
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(decreaseIndent == nil)

                Button("Toggle Task") {
                    toggleTask?()
                }
                .disabled(toggleTask == nil)
            }

            Divider()

            Button("Block Quote") {
                makeBlockquote?()
            }
            .keyboardShortcut("'", modifiers: .command)
            .disabled(makeBlockquote == nil)

            Button("Code Block") {
                makeCodeBlock?()
            }
            .disabled(makeCodeBlock == nil)

            Divider()

            Menu("Table") {
                Button("Insert Table...") {
                    formatInsertTable?()
                }
                .disabled(formatInsertTable == nil)

                Button("Add Row Above") {
                    addRowAbove?()
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
                .disabled(addRowAbove == nil)

                Button("Add Row Below") {
                    addRowBelow?()
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
                .disabled(addRowBelow == nil)

                Button("Add Column Left") {
                    addColumnLeft?()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .disabled(addColumnLeft == nil)

                Button("Add Column Right") {
                    addColumnRight?()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .disabled(addColumnRight == nil)

                Button("Delete Row") {
                    deleteRow?()
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option, .shift])
                .disabled(deleteRow == nil)

                Button("Delete Column") {
                    deleteColumn?()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option, .shift])
                .disabled(deleteColumn == nil)

                Button("Delete Table") {
                    deleteTable?()
                }
                .disabled(deleteTable == nil)
            }

            Divider()

            Button("Clear Formatting") {
                clearFormatting?()
            }
            .keyboardShortcut("k", modifiers: [.command, .option, .shift])
            .disabled(clearFormatting == nil)

            Button("Show Markdown Syntax") {
                toggleMarkdownSyntax?()
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            .disabled(toggleMarkdownSyntax == nil)
        }
    }

    // MARK: - Navigate Menu

    private var navigateMenu: some SwiftUI.Commands {
        CommandMenu("Navigate") {
            Button("Go Back") {
                goBack?()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(goBack == nil)

            Button("Go Forward") {
                goForward?()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(goForward == nil)

            Divider()

            Button("Jump to Heading...") {
                jumpToHeading?()
            }
            .disabled(jumpToHeading == nil)

            Button("Go to Line...") {
                goToLine?()
            }
            .keyboardShortcut("g", modifiers: .command)
            .disabled(goToLine == nil)

            Divider()

            Button("Previous Heading") {
                previousHeading?()
            }
            .keyboardShortcut(.upArrow, modifiers: [.control, .command])
            .disabled(previousHeading == nil)

            Button("Next Heading") {
                nextHeading?()
            }
            .keyboardShortcut(.downArrow, modifiers: [.control, .command])
            .disabled(nextHeading == nil)

            Divider()

            Button("Fold All") {
                foldAll?()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            .disabled(foldAll == nil)

            Button("Unfold All") {
                unfoldAll?()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            .disabled(unfoldAll == nil)

            Button("Fold Current Section") {
                foldSection?()
            }
            .keyboardShortcut(.leftArrow, modifiers: .option)
            .disabled(foldSection == nil)

            Button("Unfold Current Section") {
                unfoldSection?()
            }
            .keyboardShortcut(.rightArrow, modifiers: .option)
            .disabled(unfoldSection == nil)
        }
    }

    // MARK: - App Menu

    private var appMenuItems: some SwiftUI.Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About AdlerScope") {
                openWindow(id: "about")
            }
        }
    }

    // MARK: - Help Menu

    private var helpMenuItems: some SwiftUI.Commands {
        CommandGroup(replacing: .help) {
            Button("AdlerScope Help") {
                if let url = URL(string: "https://github.com/adlerflow/AdlerScope") {
                    openURL(url)
                }
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Button("Markdown Guide") {
                showMarkdownGuide?()
            }
            .disabled(showMarkdownGuide == nil)

            Button("Keyboard Shortcuts") {
                showKeyboardShortcuts?()
            }
            .keyboardShortcut("/", modifiers: [.command, .shift])
            .disabled(showKeyboardShortcuts == nil)

            Divider()

            Button("Release Notes") {
                showReleaseNotes?()
            }
            .disabled(showReleaseNotes == nil)

            Button("Report an Issue...") {
                if let url = URL(string: "https://github.com/adlerflow/AdlerScope/issues") {
                    openURL(url)
                }
            }
        }
    }
}
