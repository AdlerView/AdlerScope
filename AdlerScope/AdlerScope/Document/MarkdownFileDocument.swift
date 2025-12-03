import PDFKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Content Type

/// Represents the type of content in the document
enum DocumentContentType: Equatable, Sendable {
    case markdown
    case pdf
    case image
}

/// Pure SwiftUI FileDocument implementation for markdown, PDF, and image files
/// Used with DocumentGroup for native macOS document handling
struct MarkdownFileDocument: FileDocument {
    // MARK: - Content Types

    /// Types that can be read by this document
    static var readableContentTypes: [UTType] {
        [.markdown, .plainText, .rMarkdown, .quarto, .pdf, .image]
    }

    /// Types that can be written by this document (PDFs are read-only)
    static var writableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    // MARK: - Content

    /// The type of content stored in this document
    let contentType: DocumentContentType

    /// Markdown content (only valid when contentType == .markdown)
    var content: String

    /// PDF data (only valid when contentType == .pdf)
    let pdfData: Data?

    /// Image data (only valid when contentType == .image)
    let imageData: Data?

    /// PDF document for viewing (computed, only valid when contentType == .pdf)
    var pdfDocument: PDFDocument? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)
    }

    /// Check if this document is a PDF
    var isPDF: Bool {
        contentType == .pdf
    }

    /// Check if this document is an image
    var isImage: Bool {
        contentType == .image
    }

    // MARK: - Initialization

    /// Creates a new empty markdown document (for Cmd+N)
    init(content: String = "") {
        self.contentType = .markdown
        self.content = content
        self.pdfData = nil
        self.imageData = nil
    }

    /// Loads document from file (for Finder open, Cmd+O, etc.)
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        // Check if this is a PDF file
        if configuration.contentType == .pdf {
            // Validate PDF data
            guard let pdf = PDFDocument(data: data) else {
                throw CocoaError(.fileReadCorruptFile)
            }

            // Check for password protection
            if pdf.isLocked {
                throw CocoaError(.fileReadNoPermission)
            }

            self.contentType = .pdf
            self.content = ""
            self.pdfData = data
            self.imageData = nil
        } else if configuration.contentType.conforms(to: .image) {
            // Handle as image file
            self.contentType = .image
            self.content = ""
            self.pdfData = nil
            self.imageData = data
        } else {
            // Handle as text/markdown
            self.contentType = .markdown
            self.pdfData = nil
            self.imageData = nil

            // Try UTF-8 first, fallback to other encodings
            if let string = String(data: data, encoding: .utf8) {
                self.content = string
            } else if let string = String(data: data, encoding: .isoLatin1) {
                self.content = string
            } else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
        }
    }

    // MARK: - Serialization

    /// Saves document to file (autosave, Cmd+S, etc.)
    /// Note: PDFs and images are read-only, this only saves markdown content
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // PDFs should not be saved (read-only)
        if case .pdf = contentType {
            // Return original PDF data unchanged
            if let data = pdfData {
                return FileWrapper(regularFileWithContents: data)
            }
            throw CocoaError(.fileWriteUnknown)
        }

        // Images should not be saved (read-only)
        if case .image = contentType {
            // Return original image data unchanged
            if let data = imageData {
                return FileWrapper(regularFileWithContents: data)
            }
            throw CocoaError(.fileWriteUnknown)
        }

        let data = Data(content.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - UTType Extensions for Markdown

extension UTType {
    /// Check if UTType is a markdown variant
    var isMarkdown: Bool {
        conforms(to: .plainText) ||
        conforms(to: .rMarkdown) ||
        conforms(to: .quarto) ||
        identifier == "net.daringfireball.markdown" ||
        identifier == "public.markdown"
    }
}
