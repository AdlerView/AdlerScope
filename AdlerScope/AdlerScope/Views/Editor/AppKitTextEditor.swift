#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// AppKit-based Text Editor with cursor position tracking
///
/// Wraps NSTextView for native macOS text editing capabilities.
/// Key advantages over SwiftUI TextEditor:
/// - Access to cursor position via selectedRange()
/// - Insert text at cursor instead of end of document
/// - Native macOS text editing behavior
/// - Full undo/redo support
/// - Image drag-and-drop support
struct AppKitTextEditor: NSViewRepresentable {
    @Binding var text: String
    let formatActions: FormatMenuActions?
    let editActions: EditMenuActions?
    let imageDropHandler: ImageDropHandler?

    init(
        text: Binding<String>,
        formatActions: FormatMenuActions?,
        editActions: EditMenuActions?,
        imageDropHandler: ImageDropHandler? = nil
    ) {
        self._text = text
        self.formatActions = formatActions
        self.editActions = editActions
        self.imageDropHandler = imageDropHandler
    }

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

    // MARK: - Custom NSTextView for Drag-and-Drop

    /// Custom NSTextView subclass that handles image drag-and-drop
    final class ImageDropTextView: NSTextView {
        weak var imageDropHandler: ImageDropHandler?

        override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
            // Check if we can handle this drag
            if let handler = imageDropHandler,
               let urls = extractURLs(from: sender.draggingPasteboard),
               handler.canHandleDrop(of: urls) {
                return .copy
            }
            // Fall back to default text handling
            return super.draggingEntered(sender)
        }

        override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
            if let handler = imageDropHandler,
               let urls = extractURLs(from: sender.draggingPasteboard),
               handler.canHandleDrop(of: urls) {
                return .copy
            }
            return super.draggingUpdated(sender)
        }

        override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
            if let handler = imageDropHandler,
               let urls = extractURLs(from: sender.draggingPasteboard),
               handler.canHandleDrop(of: urls) {
                return handler.handleDrop(of: urls)
            }
            return super.performDragOperation(sender)
        }

        private func extractURLs(from pasteboard: NSPasteboard) -> [URL]? {
            let options: [NSPasteboard.ReadingOptionKey: Any] = [
                .urlReadingFileURLsOnly: true
            ]
            return pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view with custom text view for drag-and-drop
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Create custom text view
        let contentSize = scrollView.contentSize
        let textContainer = NSTextContainer(containerSize: NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        let textView = ImageDropTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

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

        // Configure image drop handling
        textView.imageDropHandler = imageDropHandler
        textView.registerForDraggedTypes(ImageDropHandler.acceptedDragTypes)

        // Set initial text
        textView.string = text

        // Sync initial state to action managers
        formatActions?.text = text
        formatActions?.cursorPosition = 0
        editActions?.text = text

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update image drop handler reference
        if let imageDropTextView = textView as? ImageDropTextView {
            imageDropTextView.imageDropHandler = imageDropHandler
        }

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

        // Check if we need to insert an image reference (from image drop handler)
        if let formatActions = formatActions,
           let pending = formatActions.pendingImageInsertion {
            let markdown = "![\(pending.altText)](\(pending.filename))"
            insertTextAtCursor(textView: textView, text: markdown)
            formatActions.pendingImageInsertion = nil
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
