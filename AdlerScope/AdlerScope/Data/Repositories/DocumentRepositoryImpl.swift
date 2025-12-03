import Foundation
import UniformTypeIdentifiers

/// Concrete implementation of DocumentRepository using FileManager
/// Handles file I/O operations with proper error handling and encoding detection
actor DocumentRepositoryImpl: DocumentRepository {
    // MARK: - Properties

    private nonisolated(unsafe) let fileManager: FileManager

    // MARK: - Initialization

    init() {
        self.fileManager = FileManager.default
    }

    // MARK: - DocumentRepository

    func read(from url: URL) async throws -> (content: String, encoding: String.Encoding) {
        // Try UTF-8 first (most common)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            return (content, .utf8)
        }

        // Try other encodings
        // UTF-16 variants first (have BOM detection)
        // Then ISO-Latin-1/Windows CP1252 (for extended ASCII)
        // Then macOSRoman and ASCII
        let encodings: [String.Encoding] = [
            .utf16,
            .utf16BigEndian,
            .utf16LittleEndian,
            .isoLatin1,
            .windowsCP1252,
            .macOSRoman,
            .ascii
        ]

        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding) {
                return (content, encoding)
            }
        }

        // Last resort: use system encoding detection
        var usedEncoding: String.Encoding = .utf8
        let content = try String(contentsOf: url, usedEncoding: &usedEncoding)

        return (content, usedEncoding)
    }

    func write(_ content: String, to url: URL, encoding: String.Encoding = .utf8) async throws {
        try content.write(to: url, atomically: true, encoding: encoding)
    }

    func fileExists(at url: URL) async -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func metadata(for url: URL) async throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: url.path)
    }

    func detectFileType(at url: URL) async -> UTType {
        // Check extension first
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "md", "markdown", "mdown", "mkd", "mkdn":
            return .plainText
        case "rmd":
            if let rMarkdown = UTType("org.r-project.r-markdown") {
                return rMarkdown
            }
            return .plainText
        case "qmd":
            if let qmdMarkdown = UTType("org.quarto.qmd") {
                return qmdMarkdown
            }
            return .plainText
        case "txt", "text":
            return .plainText
        default:
            // Try to infer from content type
            if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
               let contentType = resourceValues.contentType {
                return contentType
            }

            // Default to plainText
            return .plainText
        }
    }

    func createBackup(for url: URL) async throws -> URL {
        // Generate backup URL with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let backupFilename = "\(filename)_backup_\(timestamp).\(ext)"

        let backupURL = url.deletingLastPathComponent()
            .appendingPathComponent(backupFilename)

        // Copy file
        try fileManager.copyItem(at: url, to: backupURL)

        return backupURL
    }
}
