//
//  RecentDocumentTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for RecentDocument
//  Enhanced with createBookmark, resolveBookmark, and BookmarkError tests
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("RecentDocument Tests")
@MainActor
struct RecentDocumentTests {

    // MARK: - Initialization Tests

    @Test("Initialize with URL creates document")
    func testInitializeWithURL() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let document = RecentDocument(url: url)

        // Assert
        #expect(document.url == url)
        #expect(document.displayName == "test.md")
        #expect(document.isFavorite == false)
        #expect(document.bookmarkData == nil)
    }

    @Test("Initialize with custom display name")
    func testInitializeWithCustomDisplayName() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let document = RecentDocument(url: url, displayName: "Custom Name")

        // Assert
        #expect(document.displayName == "Custom Name")
    }

    @Test("Initialize as favorite")
    func testInitializeAsFavorite() {
        // Arrange & Act
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let document = RecentDocument(url: url, isFavorite: true)

        // Assert
        #expect(document.isFavorite == true)
    }

    // MARK: - Bookmark Creation Tests

    @Test("Create bookmark with valid file returns true")
    func testCreateBookmarkSuccess() {
        // Arrange
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("bookmark_test.md")
        try? "test content".write(to: tempURL, atomically: true, encoding: .utf8)

        let document = RecentDocument(url: tempURL)

        // Act
        let success = document.createBookmark()

        // Assert
        #expect(success == true)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Create bookmark sets bookmark data")
    func testCreateBookmarkSetsData() {
        // Arrange
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("bookmark_data_test.md")
        try? "test content".write(to: tempURL, atomically: true, encoding: .utf8)

        let document = RecentDocument(url: tempURL)

        // Act
        _ = document.createBookmark()

        // Assert
        #expect(document.bookmarkData != nil)
        #expect(document.bookmarkData!.count > 0)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Create bookmark with non-existent file returns false")
    func testCreateBookmarkWithInvalidURL() {
        // Arrange
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).md")

        let document = RecentDocument(url: nonExistentURL)

        // Act
        let success = document.createBookmark()

        // Assert
        #expect(success == false)
        #expect(document.bookmarkData == nil)
    }

    // MARK: - Bookmark Resolution Tests

    @Test("Resolve bookmark throws when bookmark data missing")
    func testResolveBookmarkThrowsWhenMissing() {
        // Arrange
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let document = RecentDocument(url: url)

        // Assert - bookmarkData is nil
        #expect(document.bookmarkData == nil)

        // Act & Assert
        do {
            _ = try document.resolveBookmark()
            Issue.record("Expected BookmarkError.missingBookmark to be thrown")
        } catch let error as BookmarkError {
            #expect(error == .missingBookmark)
        } catch {
            Issue.record("Expected BookmarkError.missingBookmark, got: \(error)")
        }
    }

    @Test("Resolve bookmark returns valid URL")
    func testResolveBookmarkReturnsValidURL() throws {
        // Arrange
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("resolve_test.md")
        try "test content".write(to: tempURL, atomically: true, encoding: .utf8)

        let document = RecentDocument(url: tempURL)
        let bookmarkCreated = document.createBookmark()

        #expect(bookmarkCreated == true)

        // Act
        let resolvedURL = try document.resolveBookmark()

        // Assert
        #expect(resolvedURL.path == tempURL.path)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Resolve bookmark with valid bookmark data succeeds")
    func testResolveBookmarkWithValidData() throws {
        // Arrange
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("valid_bookmark_test.md")
        try "test content".write(to: tempURL, atomically: true, encoding: .utf8)

        let document = RecentDocument(url: tempURL)
        _ = document.createBookmark()

        #expect(document.bookmarkData != nil)

        // Act
        let resolvedURL = try document.resolveBookmark()

        // Assert
        #expect(resolvedURL.lastPathComponent == "valid_bookmark_test.md")
        #expect(FileManager.default.fileExists(atPath: resolvedURL.path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Metadata Update Tests

    @Test("Update metadata sets file size and modification date")
    func testUpdateMetadataSetsProperties() {
        // Arrange
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("metadata_test.md")
        let content = "test content for metadata"
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)

        let document = RecentDocument(url: tempURL)
        _ = document.createBookmark()

        // Act
        document.updateMetadata()

        // Assert - improved assertions
        #expect(document.fileSize != nil)
        #expect(document.fileSize! > 0)
        #expect(document.fileModifiedDate != nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Update metadata without bookmark handles error gracefully")
    func testUpdateMetadataWithoutBookmark() {
        // Arrange
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let document = RecentDocument(url: url)

        // Act - no bookmark created, should fail gracefully
        document.updateMetadata()

        // Assert - metadata should remain nil
        #expect(document.fileSize == nil)
        #expect(document.fileModifiedDate == nil)
    }

    // MARK: - BookmarkError Tests

    @Test("Missing bookmark error has correct description")
    func testMissingBookmarkErrorDescription() {
        // Arrange
        let error = BookmarkError.missingBookmark

        // Assert
        #expect(error.errorDescription == "No security-scoped bookmark data available")
    }

    @Test("Resolution failed error has correct description")
    func testResolutionFailedErrorDescription() {
        // Arrange
        let error = BookmarkError.resolutionFailed

        // Assert
        #expect(error.errorDescription == "Failed to resolve security-scoped bookmark")
    }

    @Test("Stale bookmark error has correct description")
    func testStaleBookmarkErrorDescription() {
        // Arrange
        let error = BookmarkError.staleBookmark

        // Assert
        #expect(error.errorDescription == "Bookmark data is stale and needs refresh")
    }

    // MARK: - Preview Helper Tests

    @Test("Sample document has expected values")
    func testSampleDocument() {
        // Arrange & Act
        let sample = RecentDocument.sample()

        // Assert
        #expect(sample.displayName == "README.md")
        #expect(sample.isFavorite == true)
    }

    @Test("Sample documents returns multiple documents")
    func testSampleDocuments() {
        // Arrange & Act
        let samples = RecentDocument.samples()

        // Assert
        #expect(samples.count == 3)
        #expect(samples[0].displayName == "README.md")
        #expect(samples[1].displayName == "TODO.md")
        #expect(samples[2].displayName == "Notes.md")
    }
}
