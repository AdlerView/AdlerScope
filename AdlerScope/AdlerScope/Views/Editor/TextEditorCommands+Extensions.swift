//
//  PureSwiftUITextEditor+Extensions.swift
//  AdlerScope
//
//  View modifiers for applying Format and Edit menu commands
//  Extracted to reduce type-checking complexity
//

import SwiftUI

// MARK: - Format Commands Extension

extension View {
    /// Applies all Format menu FocusedValue bindings
    func applyFormatCommands(
        formatActions: FormatMenuActions?,
        onSync: @escaping () -> Void
    ) -> some View {
        self
            .focusedValue(\.toggleBold, formatActions.map { actions in
                { actions.toggleBold(); onSync() }
            })
            .focusedValue(\.toggleItalic, formatActions.map { actions in
                { actions.toggleItalic(); onSync() }
            })
            .focusedValue(\.toggleStrikethrough, formatActions.map { actions in
                { actions.toggleStrikethrough(); onSync() }
            })
            .focusedValue(\.toggleInlineCode, formatActions.map { actions in
                { actions.toggleInlineCode(); onSync() }
            })
            .focusedValue(\.makeHeading1, formatActions.map { actions in
                { actions.makeHeading1(); onSync() }
            })
            .focusedValue(\.makeHeading2, formatActions.map { actions in
                { actions.makeHeading2(); onSync() }
            })
            .focusedValue(\.makeHeading3, formatActions.map { actions in
                { actions.makeHeading3(); onSync() }
            })
            .focusedValue(\.makeHeading4, formatActions.map { actions in
                { actions.makeHeading4(); onSync() }
            })
            .focusedValue(\.makeHeading5, formatActions.map { actions in
                { actions.makeHeading5(); onSync() }
            })
            .focusedValue(\.makeHeading6, formatActions.map { actions in
                { actions.makeHeading6(); onSync() }
            })
            .focusedValue(\.makeBulletList, formatActions.map { actions in
                { actions.makeBulletList(); onSync() }
            })
            .focusedValue(\.makeNumberedList, formatActions.map { actions in
                { actions.makeNumberedList(); onSync() }
            })
            .focusedValue(\.makeTaskList, formatActions.map { actions in
                { actions.makeTaskList(); onSync() }
            })
            .focusedValue(\.makeBlockquote, formatActions.map { actions in
                { actions.makeBlockquote(); onSync() }
            })
            .focusedValue(\.makeCodeBlock, formatActions.map { actions in
                { actions.makeCodeBlock(); onSync() }
            })
            .focusedValue(\.increaseIndent, formatActions.map { actions in
                { actions.increaseIndent(); onSync() }
            })
            .focusedValue(\.decreaseIndent, formatActions.map { actions in
                { actions.decreaseIndent(); onSync() }
            })
    }
}

// MARK: - Edit Commands Extension

extension View {
    /// Applies all Edit menu FocusedValue bindings
    func applyEditCommands(
        editActions: EditMenuActions?,
        onSync: @escaping () -> Void
    ) -> some View {
        self
            .focusedValue(\.insertLink, editActions.map { actions in
                { actions.insertLink(); onSync() }
            })
            .focusedValue(\.insertImage, editActions.map { actions in
                { actions.insertImage(); onSync() }
            })
            .focusedValue(\.insertTable, editActions.map { actions in
                { actions.insertTable(); onSync() }
            })
    }
}

// MARK: - Preview

/// Demo view to preview Format and Edit command extensions
private struct TextEditorCommandsPreview: View {
    @State private var text = """
    # Text Editor Commands Demo

    This preview demonstrates the Format and Edit command extensions.

    ## Available Commands

    **Format Commands:**
    - Bold, Italic, Strikethrough
    - Headings (H1-H6)
    - Lists (Bullet, Numbered, Task)
    - Blockquote, Code Block
    - Indent/Outdent

    **Edit Commands:**
    - Insert Link
    - Insert Image
    - Insert Table
    """

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .applyFormatCommands(formatActions: nil, onSync: {})
            .applyEditCommands(editActions: nil, onSync: {})
            .frame(width: 500, height: 400)
            .padding()
    }
}

#Preview("Text Editor Commands") {
    TextEditorCommandsPreview()
}
