import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI Text Editor with Undo/Redo, Native Find, Drag & Drop
/// Used for iOS and as fallback for macOS
struct SwiftUITextEditor: View {
    @Binding var text: String
    let formatActions: FormatMenuActions?
    let editActions: EditMenuActions?
    @Environment(\.openURL) var openURL
    @State private var isFindNavigatorPresented = false

    var body: some View {
        editorView
    }

    private var editorView: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .findNavigator(isPresented: $isFindNavigatorPresented)
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
            .onChange(of: text) { oldValue, newValue in
                handleTextChange(oldValue: oldValue, newValue: newValue)
            }
            .applyFormatCommands(formatActions: formatActions, onSync: syncText)
            .applyEditCommands(editActions: editActions, onSync: syncEditText)
    }

    // MARK: - Text Change Handler

    private func handleTextChange(oldValue: String, newValue: String) {
        // Sync text to action managers
        formatActions?.text = newValue
        editActions?.text = newValue
        // Record change for undo/redo
        editActions?.recordChange(oldText: oldValue, newText: newValue)
    }

    // MARK: - Format Actions Sync

    /// Syncs text from formatActions back to binding
    private func syncText() {
        if let updated = formatActions?.text {
            text = updated
        }
    }

    /// Syncs text from editActions back to binding
    private func syncEditText() {
        if let updated = editActions?.text {
            text = updated
        }
    }

    // MARK: - Drag & Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          FileValidator.isMarkdownFile(url) else {
                        return
                    }

                    // Open in new window via openURL
                    Task { @MainActor in
                        openURL(url)
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Preview

#Preview("SwiftUI Text Editor") {
    @Previewable @State var text = """
    # Welcome to AdlerScope

    This is a **live preview** of the SwiftUI-based text editor.

    ## Features
    - Cross-platform (iOS & macOS)
    - Native Find Navigator
    - Drag & Drop support
    - Undo/Redo
    """

    SwiftUITextEditor(
        text: $text,
        formatActions: nil,
        editActions: nil
    )
    .frame(width: 600, height: 400)
}
