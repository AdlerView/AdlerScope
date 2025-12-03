import Foundation

/// Domain errors for document operations
/// Used with typed throws for exhaustive error handling
enum DocumentError: Error, Sendable, Equatable {
    // MARK: - File I/O Errors

    /// File not found at the specified URL
    case fileNotFound(URL)

    /// File exists but is not readable
    case fileNotReadable(URL)

    /// Directory is not writable
    case directoryNotWritable(URL)

    /// File encoding could not be detected
    case encodingDetectionFailed(URL)

    /// Failed to decode file with specified encoding
    case decodingFailed(URL, encoding: String.Encoding)

    /// Failed to encode content with specified encoding
    case encodingFailed(encoding: String.Encoding)

    /// Failed to write file to disk
    case writeFailed(URL, underlyingError: String)

    /// Failed to create backup
    case backupFailed(URL, underlyingError: String)

    // MARK: - Content Errors

    /// Document content is empty
    case emptyContent

    /// Document content exceeds maximum size
    case contentTooLarge(size: Int, maxSize: Int)

    /// Invalid UTF-8 byte sequence
    case invalidUTF8

    // MARK: - User-Friendly Messages

    var localizedDescription: String {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .fileNotReadable(let url):
            return "Cannot read file: \(url.lastPathComponent)"
        case .directoryNotWritable(let url):
            return "Cannot write to directory: \(url.path)"
        case .encodingDetectionFailed(let url):
            return "Could not detect text encoding for: \(url.lastPathComponent)"
        case .decodingFailed(let url, let encoding):
            return "Failed to decode \(url.lastPathComponent) using \(encoding.description)"
        case .encodingFailed(let encoding):
            return "Failed to encode text using \(encoding.description)"
        case .writeFailed(let url, let error):
            return "Failed to write \(url.lastPathComponent): \(error)"
        case .backupFailed(let url, let error):
            return "Failed to create backup of \(url.lastPathComponent): \(error)"
        case .emptyContent:
            return "Document is empty"
        case .contentTooLarge(let size, let maxSize):
            return "Document size (\(size) bytes) exceeds maximum (\(maxSize) bytes)"
        case .invalidUTF8:
            return "Invalid UTF-8 encoding detected"
        }
    }
}
