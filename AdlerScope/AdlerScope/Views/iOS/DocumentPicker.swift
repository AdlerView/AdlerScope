//
//  DocumentPicker.swift
//  AdlerScope
//
//  iOS/iPadOS Document Picker wrapper
//

#if !os(macOS)
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let dismiss: DismissAction

        init(onPick: @escaping (URL) -> Void, dismiss: DismissAction) {
            self.onPick = onPick
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
            dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
    }
}

// MARK: - Preview

private struct DocumentPickerPreview: View {
    @State private var isPresented = false
    @State private var pickedURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            Text("Document Picker Preview")
                .font(.headline)

            Text("Tap the button to open the document picker")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Pick Document") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)

            if let url = pickedURL {
                VStack(spacing: 4) {
                    Text("Selected:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .sheet(isPresented: $isPresented) {
            DocumentPicker(
                allowedTypes: [.plainText, .markdown],
                onPick: { url in
                    pickedURL = url
                }
            )
        }
    }
}

#Preview("Document Picker") {
    DocumentPickerPreview()
}
#endif
