import Foundation
import OSLog

/// Use case for saving markdown documents to disk
/// Thread-safe actor that handles document persistence with backups
actor SaveDocumentUseCase {
    // MARK: - Dependencies

    private let documentRepository: DocumentRepository

    // MARK: - Configuration

    /// Whether to create backups before overwriting files
    private let createBackups: Bool

    // MARK: - Initialization

    init(documentRepository: DocumentRepository, createBackups: Bool = true) {
        self.documentRepository = documentRepository
        self.createBackups = createBackups
    }

    // MARK: - Business Logic

    /// Saves document content to a file with optional backup
    /// - Parameters:
    ///   - content: Markdown content to save
    ///   - url: File URL to write to
    ///   - encoding: Text encoding (default UTF-8)
    /// - Throws: DocumentError if save fails
    nonisolated func execute(content: String, to url: URL, encoding: String.Encoding = .utf8) async throws {
        // Create backup if file exists and backups enabled
        if createBackups {
            let fileExists = await documentRepository.fileExists(at: url)
            if fileExists {
                do {
                    let backupURL = try await documentRepository.createBackup(for: url)
                    #if DEBUG
                    await os_log("Created backup: %{public}@", log: .document, type: .debug, backupURL.lastPathComponent)
                    #endif
                } catch {
                    await os_log("Failed to create backup: %{public}@", log: .document, type: .default, String(describing: error))
                    // Continue with save even if backup fails
                }
            }
        }

        // Write content
        try await documentRepository.write(content, to: url, encoding: encoding)

        await os_log("Saved document: %{public}@", log: .document, type: .info, url.lastPathComponent)
    }

    /// Validates that a URL is writable before attempting save
    /// - Parameter url: File URL to check
    /// - Returns: True if URL is writable
    nonisolated func canWrite(to url: URL) async -> Bool {
        // Check if directory exists and is writable
        let directory = url.deletingLastPathComponent()
        let fileManager = FileManager.default

        return fileManager.isWritableFile(atPath: directory.path)
    }
}
