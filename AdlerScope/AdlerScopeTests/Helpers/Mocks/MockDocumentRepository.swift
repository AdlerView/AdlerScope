//
//  MockDocumentRepository.swift
//  AdlerScopeTests
//
//  Centralized mock implementation of DocumentRepository for testing
//  Combines features from all mock variants with comprehensive call tracking and flexible configuration
//

import Foundation
import UniformTypeIdentifiers
@testable import AdlerScope

/// Centralized mock implementation of DocumentRepository
/// Provides flexible configuration for all test scenarios
@MainActor
final class MockDocumentRepository: DocumentRepository, @unchecked Sendable {

    // MARK: - Test Data

    /// Content and encoding to return from read operations
    var readResult: (content: String, encoding: String.Encoding) = ("", .utf8)

    /// URL to return from backup operations
    var backupURL: URL?

    /// Whether file exists (for fileExists method)
    var fileExistsResult: Bool = false

    /// Metadata to return from metadata operations
    var metadataResult: [FileAttributeKey: Any] = [:]

    /// File type to return from detectFileType operations
    var fileTypeResult: UTType = .plainText

    // MARK: - Result Configuration (takes precedence over direct error properties)

    /// Result configuration for read operations
    var readResultConfig: Result<(content: String, encoding: String.Encoding), Error>?

    /// Result configuration for write operations
    var writeResult: Result<Void, Error>?

    /// Result configuration for backup operations
    var backupResult: Result<URL, Error>?

    /// Result configuration for metadata operations
    var metadataResultConfig: Result<[FileAttributeKey: Any], Error>?

    // MARK: - Direct Error Configuration (legacy compatibility)

    /// Optional error to throw from read operations (ignored if readResultConfig is set)
    var readError: Error?

    /// Optional error to throw from write operations (ignored if writeResult is set)
    var writeError: Error?

    /// Boolean flag to throw error from backup operations (ignored if backupResult is set)
    var backupShouldThrowError: Bool = false

    // MARK: - Call Tracking

    /// Number of times read was called
    var readCallCount = 0

    /// Number of times write was called
    var writeCallCount = 0

    /// Number of times fileExists was called
    var fileExistsCallCount = 0

    /// Number of times metadata was called
    var metadataCallCount = 0

    /// Number of times detectFileType was called
    var detectFileTypeCallCount = 0

    /// Number of times createBackup was called
    var createBackupCallCount = 0

    // MARK: - Parameter Tracking

    /// Last URL passed to read
    var lastReadURL: URL?

    /// Last content written
    var lastWrittenContent: String?

    /// Last URL written to
    var lastWrittenURL: URL?

    /// Last encoding used for writing
    var lastWrittenEncoding: String.Encoding?

    /// Last URL checked for existence
    var lastFileExistsURL: URL?

    /// Last URL passed to metadata
    var lastMetadataURL: URL?

    /// Last URL passed to detectFileType
    var lastDetectFileTypeURL: URL?

    /// Last URL passed to createBackup
    var lastBackupURL: URL?

    // MARK: - Repository Methods

    func read(from url: URL) async throws -> (content: String, encoding: String.Encoding) {
        readCallCount += 1
        lastReadURL = url

        // Check result configuration first
        if let result = readResultConfig {
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }

        // Check direct error configuration
        if let error = readError {
            throw error
        }

        // Return default result
        return readResult
    }

    func write(_ content: String, to url: URL, encoding: String.Encoding) async throws {
        writeCallCount += 1
        lastWrittenContent = content
        lastWrittenURL = url
        lastWrittenEncoding = encoding

        // Check result configuration first
        if let result = writeResult {
            switch result {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }

        // Check direct error configuration
        if let error = writeError {
            throw error
        }
    }

    func fileExists(at url: URL) async -> Bool {
        fileExistsCallCount += 1
        lastFileExistsURL = url
        return fileExistsResult
    }

    func metadata(for url: URL) async throws -> [FileAttributeKey: Any] {
        metadataCallCount += 1
        lastMetadataURL = url

        // Check result configuration first
        if let result = metadataResultConfig {
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }

        // Return default result
        return metadataResult
    }

    func detectFileType(at url: URL) async -> UTType {
        detectFileTypeCallCount += 1
        lastDetectFileTypeURL = url
        return fileTypeResult
    }

    func createBackup(for url: URL) async throws -> URL {
        createBackupCallCount += 1
        lastBackupURL = url

        // Check result configuration first
        if let result = backupResult {
            switch result {
            case .success(let backupURL):
                return backupURL
            case .failure(let error):
                throw error
            }
        }

        // Check boolean flag
        if backupShouldThrowError {
            throw DocumentError.backupFailed(url, underlyingError: "Mock backup error")
        }

        // Return configured URL or default
        return backupURL ?? url.appendingPathExtension("backup")
    }

    // MARK: - Test Helpers

    /// Reset only call counts and parameter tracking (preserves configuration)
    func resetTracking() {
        readCallCount = 0
        writeCallCount = 0
        fileExistsCallCount = 0
        metadataCallCount = 0
        detectFileTypeCallCount = 0
        createBackupCallCount = 0

        lastReadURL = nil
        lastWrittenContent = nil
        lastWrittenURL = nil
        lastWrittenEncoding = nil
        lastFileExistsURL = nil
        lastMetadataURL = nil
        lastDetectFileTypeURL = nil
        lastBackupURL = nil
    }

    /// Reset all state including configuration
    func reset() {
        resetTracking()

        // Reset results
        readResult = ("", .utf8)
        backupURL = nil
        fileExistsResult = false
        metadataResult = [:]
        fileTypeResult = .plainText

        // Reset result configurations
        readResultConfig = nil
        writeResult = nil
        backupResult = nil
        metadataResultConfig = nil

        // Reset error configurations
        readError = nil
        writeError = nil
        backupShouldThrowError = false
    }
}

// MARK: - Factory Methods

extension MockDocumentRepository {

    /// Create a mock that succeeds for all operations
    /// - Returns: Configured mock repository
    static func withSuccessfulOperations() -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.readResult = ("# Sample Content", .utf8)
        mock.fileExistsResult = false
        return mock
    }

    /// Create a mock with specific read content
    /// - Parameter content: Content to return from read operations
    /// - Parameter encoding: Encoding to return (default: .utf8)
    /// - Returns: Configured mock repository
    static func withReadContent(_ content: String, encoding: String.Encoding = .utf8) -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.readResult = (content, encoding)
        return mock
    }

    /// Create a mock where read operations fail
    /// - Parameter error: Error to throw (default: generic DocumentError)
    /// - Returns: Configured mock repository
    static func withReadError(_ error: Error = DocumentError.fileNotReadable(URL(fileURLWithPath: "/test"))) -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.readError = error
        return mock
    }

    /// Create a mock where write operations fail
    /// - Parameter error: Error to throw (default: generic DocumentError)
    /// - Returns: Configured mock repository
    static func withWriteError(_ error: Error = DocumentError.writeFailed(URL(fileURLWithPath: "/test"), underlyingError: "Mock write error")) -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.writeError = error
        return mock
    }

    /// Create a mock where backup operations fail
    /// - Returns: Configured mock repository
    static func withBackupError() -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.backupShouldThrowError = true
        return mock
    }

    /// Create a mock for file that exists
    /// - Parameter content: Content to return when reading
    /// - Returns: Configured mock repository
    static func withExistingFile(content: String = "# Existing Content") -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.fileExistsResult = true
        mock.readResult = (content, .utf8)
        return mock
    }

    /// Create a mock for new file (doesn't exist)
    /// - Returns: Configured mock repository
    static func withNewFile() -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.fileExistsResult = false
        return mock
    }

    /// Create a mock that throws errors for all operations
    /// - Parameter error: Error to use for all operations
    /// - Returns: Configured mock repository
    static func withErrors(_ error: Error = NSError(domain: "MockDocumentRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])) -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        mock.readError = error
        mock.writeError = error
        mock.backupShouldThrowError = true
        return mock
    }

    /// Create a custom configured mock
    /// - Parameter configure: Configuration closure
    /// - Returns: Configured mock repository
    static func with(_ configure: (MockDocumentRepository) -> Void) -> MockDocumentRepository {
        let mock = MockDocumentRepository()
        configure(mock)
        return mock
    }
}
