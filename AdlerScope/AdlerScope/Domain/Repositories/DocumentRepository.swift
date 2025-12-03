import Foundation
import UniformTypeIdentifiers

/// Repository protocol for document file I/O operations
/// Abstracts file system access, cloud storage, etc.
/// Implementations handle reading/writing markdown files
protocol DocumentRepository: Sendable {
    /// Reads document content from a file URL
    /// - Parameter url: File URL to read from
    /// - Returns: Tuple of (content string, detected encoding)
    /// - Throws: If file reading fails or encoding detection fails
    func read(from url: URL) async throws -> (content: String, encoding: String.Encoding)

    /// Writes document content to a file URL
    /// - Parameters:
    ///   - content: Markdown content to write
    ///   - url: File URL to write to
    ///   - encoding: Text encoding (default UTF-8)
    /// - Throws: If file writing fails
    func write(_ content: String, to url: URL, encoding: String.Encoding) async throws

    /// Checks if a file exists at the given URL
    /// - Parameter url: File URL to check
    /// - Returns: True if file exists and is readable
    func fileExists(at url: URL) async -> Bool

    /// Gets file metadata (size, modification date, etc.)
    /// - Parameter url: File URL to inspect
    /// - Returns: File attributes dictionary
    /// - Throws: If metadata retrieval fails
    func metadata(for url: URL) async throws -> [FileAttributeKey: Any]

    /// Detects file type from content or extension
    /// - Parameter url: File URL to inspect
    /// - Returns: Detected UTType (e.g., .markdown, .plainText, .rMarkdown)
    func detectFileType(at url: URL) async -> UTType

    /// Creates a backup of a file before modification
    /// - Parameter url: Original file URL
    /// - Returns: Backup file URL
    /// - Throws: If backup creation fails
    func createBackup(for url: URL) async throws -> URL
}
