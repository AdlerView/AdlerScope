//
//  DocumentErrorTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for DocumentError
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("DocumentError Tests")
struct DocumentErrorTests {

    @Test("File not found error")
    func testFileNotFound() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/missing.md")
        let error = DocumentError.fileNotFound(url)

        // Assert
        #expect(error.localizedDescription.contains("missing.md"))
        #expect(error.localizedDescription.contains("not found"))
    }

    @Test("File not readable error")
    func testFileNotReadable() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/unreadable.md")
        let error = DocumentError.fileNotReadable(url)

        // Assert
        #expect(error.localizedDescription.contains("Cannot read"))
        #expect(error.localizedDescription.contains("unreadable.md"))
    }

    @Test("Directory not writable error")
    func testDirectoryNotWritable() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/protected/directory")
        let error = DocumentError.directoryNotWritable(url)

        // Assert
        #expect(error.localizedDescription.contains("Cannot write"))
        #expect(error.localizedDescription.contains("/protected/directory"))
    }

    @Test("Encoding detection failed error")
    func testEncodingDetectionFailed() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/unknown.md")
        let error = DocumentError.encodingDetectionFailed(url)

        // Assert
        #expect(error.localizedDescription.contains("detect text encoding"))
        #expect(error.localizedDescription.contains("unknown.md"))
    }

    @Test("Decoding failed error")
    func testDecodingFailed() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let error = DocumentError.decodingFailed(url, encoding: .utf8)

        // Assert
        #expect(error.localizedDescription.contains("Failed to decode"))
        #expect(error.localizedDescription.contains("test.md"))
    }

    @Test("Encoding failed error")
    func testEncodingFailed() {
        // Arrange & Act
        let error = DocumentError.encodingFailed(encoding: .utf16)

        // Assert
        #expect(error.localizedDescription.contains("Failed to encode"))
    }

    @Test("Write failed error")
    func testWriteFailed() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let error = DocumentError.writeFailed(url, underlyingError: "Permission denied")

        // Assert
        #expect(error.localizedDescription.contains("Failed to write"))
        #expect(error.localizedDescription.contains("test.md"))
        #expect(error.localizedDescription.contains("Permission denied"))
    }

    @Test("Backup failed error")
    func testBackupFailed() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let error = DocumentError.backupFailed(url, underlyingError: "Disk full")

        // Assert
        #expect(error.localizedDescription.contains("Failed to create backup"))
        #expect(error.localizedDescription.contains("test.md"))
        #expect(error.localizedDescription.contains("Disk full"))
    }

    @Test("Empty content error")
    func testEmptyContent() {
        // Arrange & Act
        let error = DocumentError.emptyContent

        // Assert
        #expect(error.localizedDescription.contains("empty"))
    }

    @Test("Content too large error")
    func testContentTooLarge() {
        // Arrange & Act
        let error = DocumentError.contentTooLarge(size: 10_000_000, maxSize: 5_000_000)

        // Assert
        #expect(error.localizedDescription.contains("10000000"))
        #expect(error.localizedDescription.contains("5000000"))
        #expect(error.localizedDescription.contains("exceeds"))
    }

    @Test("Invalid UTF-8 error")
    func testInvalidUTF8() {
        // Arrange & Act
        let error = DocumentError.invalidUTF8

        // Assert
        #expect(error.localizedDescription.contains("UTF-8"))
    }

    @Test("Error equality with simple cases")
    func testErrorEquality() {
        // Arrange
        let error1 = DocumentError.emptyContent
        let error2 = DocumentError.emptyContent
        let error3 = DocumentError.invalidUTF8

        // Assert
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Error equality with URL associated values")
    func testErrorEqualityWithURLs() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/tmp/test.md")
        let url2 = URL(fileURLWithPath: "/tmp/test.md")
        let url3 = URL(fileURLWithPath: "/tmp/other.md")

        // Same error, same URL
        let error1 = DocumentError.fileNotFound(url1)
        let error2 = DocumentError.fileNotFound(url2)
        #expect(error1 == error2)

        // Same error, different URL
        let error3 = DocumentError.fileNotFound(url3)
        #expect(error1 != error3)

        // Different errors, same URL
        let error4 = DocumentError.fileNotReadable(url1)
        #expect(error1 != error4)
    }

    @Test("Error equality with encoding associated values")
    func testErrorEqualityWithEncodings() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/tmp/test.md")
        let url2 = URL(fileURLWithPath: "/tmp/test.md")

        // Same URL, same encoding
        let error1 = DocumentError.decodingFailed(url1, encoding: .utf8)
        let error2 = DocumentError.decodingFailed(url2, encoding: .utf8)
        #expect(error1 == error2)

        // Same URL, different encoding
        let error3 = DocumentError.decodingFailed(url1, encoding: .utf16)
        #expect(error1 != error3)

        // Different error with encoding
        let error4 = DocumentError.encodingFailed(encoding: .utf8)
        let error5 = DocumentError.encodingFailed(encoding: .utf8)
        #expect(error4 == error5)

        let error6 = DocumentError.encodingFailed(encoding: .utf16)
        #expect(error4 != error6)
    }

    @Test("Error equality with multiple associated values")
    func testErrorEqualityWithMultipleValues() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/tmp/test.md")
        let url2 = URL(fileURLWithPath: "/tmp/test.md")
        let url3 = URL(fileURLWithPath: "/tmp/other.md")

        // writeFailed with same URL and error message
        let error1 = DocumentError.writeFailed(url1, underlyingError: "Permission denied")
        let error2 = DocumentError.writeFailed(url2, underlyingError: "Permission denied")
        #expect(error1 == error2)

        // writeFailed with same URL but different error message
        let error3 = DocumentError.writeFailed(url1, underlyingError: "Disk full")
        #expect(error1 != error3)

        // writeFailed with different URL
        let error4 = DocumentError.writeFailed(url3, underlyingError: "Permission denied")
        #expect(error1 != error4)

        // backupFailed with same values
        let error5 = DocumentError.backupFailed(url1, underlyingError: "No space")
        let error6 = DocumentError.backupFailed(url2, underlyingError: "No space")
        #expect(error5 == error6)
    }

    @Test("Error equality with numeric associated values")
    func testErrorEqualityWithNumericValues() {
        // Arrange
        let error1 = DocumentError.contentTooLarge(size: 10_000_000, maxSize: 5_000_000)
        let error2 = DocumentError.contentTooLarge(size: 10_000_000, maxSize: 5_000_000)
        let error3 = DocumentError.contentTooLarge(size: 20_000_000, maxSize: 5_000_000)
        let error4 = DocumentError.contentTooLarge(size: 10_000_000, maxSize: 10_000_000)

        // Same values
        #expect(error1 == error2)

        // Different size
        #expect(error1 != error3)

        // Different maxSize
        #expect(error1 != error4)
    }
}
