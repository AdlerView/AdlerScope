//
//  Item.swift
//  AdlerScope
//
//  SwiftData Models for AdlerScope application
//  - RecentDocument: Tracks recently opened markdown files with security-scoped bookmarks
//

import Foundation
import SwiftData

// MARK: - Recent Document Model

/// Represents a recently opened document with security-scoped bookmark
/// Used in sidebar for quick access to frequently used files
@Model
final class RecentDocument {
    /// Unique identifier
    var id: UUID = UUID()

    /// File URL (may become stale, use bookmark to resolve)
    var url: URL = URL(fileURLWithPath: "")

    /// Display name (filename)
    var displayName: String = ""

    /// When this document was last opened
    var lastOpened: Date = Date()

    /// Security-scoped bookmark data for sandboxed file access
    /// Required for accessing files outside app container
    var bookmarkData: Data?

    /// Whether user marked this as favorite
    var isFavorite: Bool = false

    /// File size in bytes (cached, may become stale)
    var fileSize: Int64?

    /// File modification date (cached, may become stale)
    var fileModifiedDate: Date?

    // MARK: - Initialization

    init(
        url: URL,
        displayName: String? = nil,
        lastOpened: Date = Date(),
        bookmarkData: Data? = nil,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.url = url
        self.displayName = displayName ?? url.lastPathComponent
        self.lastOpened = lastOpened
        self.bookmarkData = bookmarkData
        self.isFavorite = isFavorite
        self.fileSize = nil
        self.fileModifiedDate = nil
    }

    // MARK: - Bookmark Management

    /// Creates a security-scoped bookmark for this URL
    /// Required for accessing files in sandboxed environment
    /// - Returns: True if bookmark was created successfully
    @MainActor
    func createBookmark() -> Bool {
        do {
            #if os(macOS)
            let options: URL.BookmarkCreationOptions = [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
            #else
            let options: URL.BookmarkCreationOptions = []
            #endif

            let data = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            self.bookmarkData = data
            return true
        } catch {
            print("Failed to create bookmark for \(url.path): \(error)")
            return false
        }
    }

    /// Resolves the security-scoped bookmark to get a valid URL
    /// - Returns: Resolved URL, or nil if bookmark is invalid
    /// - Throws: BookmarkError if resolution fails
    @MainActor
    func resolveBookmark() throws -> URL {
        guard let data = bookmarkData else {
            throw BookmarkError.missingBookmark
        }

        #if os(macOS)
        let resolutionOptions: URL.BookmarkResolutionOptions = .withSecurityScope
        let creationOptions: URL.BookmarkCreationOptions = [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
        #else
        let resolutionOptions: URL.BookmarkResolutionOptions = []
        let creationOptions: URL.BookmarkCreationOptions = []
        #endif

        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: data,
            options: resolutionOptions,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            // Bookmark is stale, recreate it
            _ = resolvedURL.startAccessingSecurityScopedResource()
            defer { resolvedURL.stopAccessingSecurityScopedResource() }

            let newData = try resolvedURL.bookmarkData(
                options: creationOptions,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            self.bookmarkData = newData
            self.url = resolvedURL
        }

        return resolvedURL
    }

    /// Updates cached file metadata (size, modification date)
    @MainActor
    func updateMetadata() {
        do {
            let resolvedURL = try resolveBookmark()
            let resourceValues = try resolvedURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])

            self.fileSize = resourceValues.fileSize.map { Int64($0) }
            self.fileModifiedDate = resourceValues.contentModificationDate
        } catch {
            print("Failed to update metadata for \(displayName): \(error)")
        }
    }
}

// MARK: - Bookmark Errors

enum BookmarkError: Error, LocalizedError {
    case missingBookmark
    case resolutionFailed
    case staleBookmark

    var errorDescription: String? {
        switch self {
        case .missingBookmark:
            return "No security-scoped bookmark data available"
        case .resolutionFailed:
            return "Failed to resolve security-scoped bookmark"
        case .staleBookmark:
            return "Bookmark data is stale and needs refresh"
        }
    }
}

// MARK: - Preview Helpers

extension RecentDocument {
    /// Creates a sample document for SwiftUI previews
    static func sample() -> RecentDocument {
        RecentDocument(
            url: URL(fileURLWithPath: "/Users/test/Documents/README.md"),
            displayName: "README.md",
            lastOpened: Date(),
            isFavorite: true
        )
    }

    /// Creates multiple sample documents for previews
    static func samples() -> [RecentDocument] {
        [
            RecentDocument(
                url: URL(fileURLWithPath: "/Users/test/Documents/README.md"),
                displayName: "README.md",
                lastOpened: Date(),
                isFavorite: true
            ),
            RecentDocument(
                url: URL(fileURLWithPath: "/Users/test/Documents/TODO.md"),
                displayName: "TODO.md",
                lastOpened: Date().addingTimeInterval(-3600),
                isFavorite: false
            ),
            RecentDocument(
                url: URL(fileURLWithPath: "/Users/test/Projects/Notes.md"),
                displayName: "Notes.md",
                lastOpened: Date().addingTimeInterval(-86400),
                isFavorite: true
            )
        ]
    }
}
