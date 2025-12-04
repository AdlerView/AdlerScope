//
//  DocumentExporter.swift
//  AdlerScope
//
//  iOS/iPadOS Document Export wrapper for saving files
//

#if !os(macOS)
import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct DocumentExporter: UIViewControllerRepresentable {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "DocumentExporter")

    let content: String
    let defaultFilename: String
    let onExport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Write content to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(defaultFilename)

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            Self.logger.error("Failed to write temporary file: \(error, privacy: .public)")
        }

        // Create picker for exporting/moving
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onExport: onExport, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onExport: (URL) -> Void
        let dismiss: DismissAction

        init(onExport: @escaping (URL) -> Void, dismiss: DismissAction) {
            self.onExport = onExport
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onExport(url)
            dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
    }
}

// MARK: - Preview

private struct DocumentExporterPreview: View {
    @State private var isPresented = false
    @State private var exportedURL: URL?

    let sampleContent = """
    # Sample Document

    This is a **sample** markdown document for export testing.

    ## Features
    - Export to file system
    - Choose save location
    - Automatic file extension
    """

    var body: some View {
        VStack(spacing: 20) {
            Text("Document Exporter Preview")
                .font(.headline)

            Text("Tap the button to present the export dialog")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Export Document") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)

            if let url = exportedURL {
                Text("Exported to: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .sheet(isPresented: $isPresented) {
            DocumentExporter(
                content: sampleContent,
                defaultFilename: "sample.md",
                onExport: { url in
                    exportedURL = url
                }
            )
        }
    }
}

#Preview("Document Exporter") {
    DocumentExporterPreview()
}
#endif
