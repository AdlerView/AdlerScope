#if os(macOS)
import SwiftUI
import AppKit

/// AppKit-based Text Editor with cursor position tracking
///
/// Wraps NSTextView for native macOS text editing capabilities.
/// Key advantages over SwiftUI TextEditor:
/// - Access to cursor position via selectedRange()
/// - Insert text at cursor instead of end of document
/// - Native macOS text editing behavior
/// - Full undo/redo support
struct AppKitTextEditor: NSViewRepresentable {
    @Binding var text: String
    let formatActions: FormatMenuActions?
    let editActions: EditMenuActions?

    /// Coordinator manages NSTextView delegate callbacks and text synchronization
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AppKitTextEditor
        var isUpdatingFromBinding = false

        init(_ parent: AppKitTextEditor) {
            self.parent = parent
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromBinding,
                  let textView = notification.object as? NSTextView else {
                return
            }

            let oldValue = parent.text
            let newValue = textView.string

            // Update binding
            parent.text = newValue

            // Sync to action managers
            parent.formatActions?.text = newValue
            parent.formatActions?.cursorPosition = textView.selectedRange().location
            parent.editActions?.text = newValue

            // Record change for undo/redo
            parent.editActions?.recordChange(oldText: oldValue, newText: newValue)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update cursor position in format actions
            parent.formatActions?.cursorPosition = textView.selectedRange().location
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view
        let scrollView = NSTextView.scrollableTextView()

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure text view
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        // Set initial text
        textView.string = text

        // Sync initial state to action managers
        formatActions?.text = text
        formatActions?.cursorPosition = 0
        editActions?.text = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update if text changed from outside (binding update)
        if textView.string != text {
            context.coordinator.isUpdatingFromBinding = true

            // Preserve cursor position during external updates
            let oldSelectedRange = textView.selectedRange()
            textView.string = text

            // Restore cursor position if still valid
            if oldSelectedRange.location <= text.count {
                textView.setSelectedRange(oldSelectedRange)
            }

            context.coordinator.isUpdatingFromBinding = false
        }

        // Check if we need to insert text at cursor (from format actions)
        if let formatActions = formatActions,
           let insertionText = formatActions.pendingInsertion {
            insertTextAtCursor(textView: textView, text: insertionText)
            formatActions.pendingInsertion = nil
        }
    }

    // MARK: - Text Insertion

    private func insertTextAtCursor(textView: NSTextView, text: String) {
        let selectedRange = textView.selectedRange()

        // Insert text at cursor
        if textView.shouldChangeText(in: selectedRange, replacementString: text) {
            textView.replaceCharacters(in: selectedRange, with: text)
            textView.didChangeText()

            // Move cursor after inserted text
            let newPosition = selectedRange.location + text.count
            textView.setSelectedRange(NSRange(location: newPosition, length: 0))
        }
    }
}

// MARK: - Preview

#Preview("AppKit Text Editor") {
    @Previewable @State var text = """
    # Welcome to AdlerScope

    This is a **live preview** of the AppKit-based text editor.

    ## Features
    - Native macOS text editing
    - Cursor position tracking
    - Full undo/redo support

    ```swift
    let greeting = "Hello, World!"
    print(greeting)
    ```
    """

    AppKitTextEditor(
        text: $text,
        formatActions: nil,
        editActions: nil
    )
    .frame(width: 600, height: 400)
}

#endif
