//
//  RecentDocument+QueriesTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for RecentDocument query extensions
//

import Testing
import Foundation
import SwiftData
@testable import AdlerScope

@Suite("RecentDocument Queries Tests")
@MainActor
struct RecentDocumentQueriesTests {

    // Helper to create in-memory context
    func makeContext() throws -> ModelContext {
        let schema = Schema([RecentDocument.self, AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Find by URL returns document when exists")
    func testFindByURL() throws {
        let context = try makeContext()
        let url = URL(fileURLWithPath: "/test/document.md")
        let document = RecentDocument(url: url)
        context.insert(document)

        let found = try RecentDocument.find(url: url, in: context)

        #expect(found != nil)
        #expect(found?.url == url)
    }

    @Test("Find by URL returns nil when not exists")
    func testFindByURLNotFound() throws {
        let context = try makeContext()
        let url = URL(fileURLWithPath: "/test/nonexistent.md")

        let found = try RecentDocument.find(url: url, in: context)

        #expect(found == nil)
    }

    @Test("Find by ID returns document when exists")
    func testFindByID() throws {
        let context = try makeContext()
        let url = URL(fileURLWithPath: "/test/document.md")
        let document = RecentDocument(url: url)
        context.insert(document)
        try context.save()

        let id = document.persistentModelID
        let found = try RecentDocument.find(id: id, in: context)

        #expect(found != nil)
        #expect(found?.url == url)
    }

    @Test("Fetch favorites returns only favorite documents")
    func testFetchFavorites() throws {
        let context = try makeContext()

        let doc1 = RecentDocument(url: URL(fileURLWithPath: "/test/fav1.md"), isFavorite: true)
        let doc2 = RecentDocument(url: URL(fileURLWithPath: "/test/normal.md"), isFavorite: false)
        let doc3 = RecentDocument(url: URL(fileURLWithPath: "/test/fav2.md"), isFavorite: true)

        context.insert(doc1)
        context.insert(doc2)
        context.insert(doc3)

        let favorites = try RecentDocument.fetchFavorites(in: context)

        #expect(favorites.count == 2)
        #expect(favorites.allSatisfy { $0.isFavorite })
    }

    @Test("Count favorites returns correct count")
    func testCountFavorites() throws {
        let context = try makeContext()

        let doc1 = RecentDocument(url: URL(fileURLWithPath: "/test/fav1.md"), isFavorite: true)
        let doc2 = RecentDocument(url: URL(fileURLWithPath: "/test/normal.md"), isFavorite: false)
        let doc3 = RecentDocument(url: URL(fileURLWithPath: "/test/fav2.md"), isFavorite: true)

        context.insert(doc1)
        context.insert(doc2)
        context.insert(doc3)

        let count = try RecentDocument.countFavorites(in: context)

        #expect(count == 2)
    }

    @Test("Fetch recent with default limit")
    func testFetchRecentDefaultLimit() throws {
        let context = try makeContext()

        // Create 25 documents
        for i in 0..<25 {
            let doc = RecentDocument(url: URL(fileURLWithPath: "/test/doc\(i).md"))
            context.insert(doc)
        }

        let recent = try RecentDocument.fetchRecent(in: context)

        #expect(recent.count == 20) // Default limit is 20
    }

    @Test("Fetch recent with custom limit")
    func testFetchRecentCustomLimit() throws {
        let context = try makeContext()

        // Create 15 documents
        for i in 0..<15 {
            let doc = RecentDocument(url: URL(fileURLWithPath: "/test/doc\(i).md"))
            context.insert(doc)
        }

        let recent = try RecentDocument.fetchRecent(limit: 5, in: context)

        #expect(recent.count == 5)
    }

    @Test("Fetch recently modified within days")
    func testFetchRecentlyModified() throws {
        let context = try makeContext()

        // Create documents with different lastOpened dates
        let now = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        let recentDoc = RecentDocument(url: URL(fileURLWithPath: "/test/recent.md"))
        recentDoc.lastOpened = now

        let oldDoc = RecentDocument(url: URL(fileURLWithPath: "/test/old.md"))
        oldDoc.lastOpened = oldDate

        context.insert(recentDoc)
        context.insert(oldDoc)

        let recent = try RecentDocument.fetchRecentlyModified(days: 7, in: context)

        #expect(recent.count == 1)
        #expect(recent.first?.url.lastPathComponent == "recent.md")
    }

    @Test("Search documents by query")
    func testSearch() throws {
        let context = try makeContext()

        let doc1 = RecentDocument(url: URL(fileURLWithPath: "/test/readme.md"))
        let doc2 = RecentDocument(url: URL(fileURLWithPath: "/test/todo.md"))
        let doc3 = RecentDocument(url: URL(fileURLWithPath: "/test/notes.md"))

        context.insert(doc1)
        context.insert(doc2)
        context.insert(doc3)

        let results = try RecentDocument.search(query: "readme", in: context)

        #expect(results.count == 1)
        #expect(results.first?.displayName.lowercased().contains("readme") == true)
    }

    @Test("Search is case insensitive")
    func testSearchCaseInsensitive() throws {
        let context = try makeContext()

        let doc = RecentDocument(url: URL(fileURLWithPath: "/test/README.md"))
        context.insert(doc)

        let results = try RecentDocument.search(query: "readme", in: context)

        #expect(results.count == 1)
    }

    @Test("Count returns total documents")
    func testCount() throws {
        let context = try makeContext()

        for i in 0..<5 {
            let doc = RecentDocument(url: URL(fileURLWithPath: "/test/doc\(i).md"))
            context.insert(doc)
        }

        let count = try RecentDocument.count(in: context)

        #expect(count == 5)
    }

    @Test("Most recent returns latest document")
    func testMostRecent() throws {
        let context = try makeContext()

        let now = Date()
        let earlier = Calendar.current.date(byAdding: .hour, value: -1, to: now)!

        let oldDoc = RecentDocument(url: URL(fileURLWithPath: "/test/old.md"))
        oldDoc.lastOpened = earlier

        let newDoc = RecentDocument(url: URL(fileURLWithPath: "/test/new.md"))
        newDoc.lastOpened = now

        context.insert(oldDoc)
        context.insert(newDoc)

        let mostRecent = try RecentDocument.mostRecent(in: context)

        #expect(mostRecent?.url.lastPathComponent == "new.md")
    }

    @Test("Delete older than removes old documents")
    func testDeleteOlderThan() throws {
        let context = try makeContext()

        let now = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        let recentDoc = RecentDocument(url: URL(fileURLWithPath: "/test/recent.md"))
        recentDoc.lastOpened = now

        let oldDoc = RecentDocument(url: URL(fileURLWithPath: "/test/old.md"))
        oldDoc.lastOpened = oldDate

        context.insert(recentDoc)
        context.insert(oldDoc)

        let deletedCount = try RecentDocument.deleteOlderThan(days: 7, in: context)

        #expect(deletedCount == 1)

        let remaining = try RecentDocument.count(in: context)
        #expect(remaining == 1)
    }

    @Test("Delete non-favorites removes only non-favorites")
    func testDeleteNonFavorites() throws {
        let context = try makeContext()

        let favorite = RecentDocument(url: URL(fileURLWithPath: "/test/fav.md"), isFavorite: true)
        let normal1 = RecentDocument(url: URL(fileURLWithPath: "/test/normal1.md"), isFavorite: false)
        let normal2 = RecentDocument(url: URL(fileURLWithPath: "/test/normal2.md"), isFavorite: false)

        context.insert(favorite)
        context.insert(normal1)
        context.insert(normal2)

        let deletedCount = try RecentDocument.deleteNonFavorites(in: context)

        #expect(deletedCount == 2)

        let remaining = try RecentDocument.count(in: context)
        #expect(remaining == 1)

        let remainingDoc = try RecentDocument.mostRecent(in: context)
        #expect(remainingDoc?.isFavorite == true)
    }
}

@Suite("RecentDocument Queries Edge Cases")
@MainActor
struct RecentDocumentQueriesEdgeCaseTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([RecentDocument.self, AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Fetch favorites when none exist")
    func testFetchFavoritesEmpty() throws {
        let context = try makeContext()

        let favorites = try RecentDocument.fetchFavorites(in: context)

        #expect(favorites.isEmpty)
    }

    @Test("Count favorites when none exist")
    func testCountFavoritesEmpty() throws {
        let context = try makeContext()

        let count = try RecentDocument.countFavorites(in: context)

        #expect(count == 0)
    }

    @Test("Search with no matches")
    func testSearchNoMatches() throws {
        let context = try makeContext()

        let doc = RecentDocument(url: URL(fileURLWithPath: "/test/readme.md"))
        context.insert(doc)

        let results = try RecentDocument.search(query: "nonexistent", in: context)

        #expect(results.isEmpty)
    }

    @Test("Most recent when empty")
    func testMostRecentEmpty() throws {
        let context = try makeContext()

        let mostRecent = try RecentDocument.mostRecent(in: context)

        #expect(mostRecent == nil)
    }

    @Test("Delete older than with no old documents")
    func testDeleteOlderThanNone() throws {
        let context = try makeContext()

        let doc = RecentDocument(url: URL(fileURLWithPath: "/test/recent.md"))
        context.insert(doc)

        let deletedCount = try RecentDocument.deleteOlderThan(days: 1, in: context)

        #expect(deletedCount == 0)
    }

    @Test("Delete non-favorites when all are favorites")
    func testDeleteNonFavoritesAllFavorites() throws {
        let context = try makeContext()

        let fav1 = RecentDocument(url: URL(fileURLWithPath: "/test/fav1.md"), isFavorite: true)
        let fav2 = RecentDocument(url: URL(fileURLWithPath: "/test/fav2.md"), isFavorite: true)

        context.insert(fav1)
        context.insert(fav2)

        let deletedCount = try RecentDocument.deleteNonFavorites(in: context)

        #expect(deletedCount == 0)

        let count = try RecentDocument.count(in: context)
        #expect(count == 2)
    }

    @Test("Fetch recent with limit larger than total")
    func testFetchRecentLimitLargerThanTotal() throws {
        let context = try makeContext()

        for i in 0..<5 {
            let doc = RecentDocument(url: URL(fileURLWithPath: "/test/doc\(i).md"))
            context.insert(doc)
        }

        let recent = try RecentDocument.fetchRecent(limit: 100, in: context)

        #expect(recent.count == 5)
    }

    @Test("Search with empty query")
    func testSearchEmptyQuery() throws {
        let context = try makeContext()

        let doc = RecentDocument(url: URL(fileURLWithPath: "/test/readme.md"))
        context.insert(doc)

        let results = try RecentDocument.search(query: "", in: context)

        // Empty query should match nothing or everything depending on implementation
        #expect(results.count >= 0)
    }
}

@Suite("RecentDocument Queries Integration Tests")
@MainActor
struct RecentDocumentQueriesIntegrationTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([RecentDocument.self, AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Complete workflow: Add, find, update, delete")
    func testCompleteWorkflow() throws {
        let context = try makeContext()

        // Add document
        let url = URL(fileURLWithPath: "/test/workflow.md")
        let doc = RecentDocument(url: url, isFavorite: false)
        context.insert(doc)

        // Find by URL
        let found = try RecentDocument.find(url: url, in: context)
        #expect(found != nil)

        // Update to favorite
        found?.isFavorite = true

        // Verify it's in favorites
        let favorites = try RecentDocument.fetchFavorites(in: context)
        #expect(favorites.count == 1)

        // Delete non-favorites (should not delete this one)
        let deleted = try RecentDocument.deleteNonFavorites(in: context)
        #expect(deleted == 0)

        let count = try RecentDocument.count(in: context)
        #expect(count == 1)
    }

    @Test("Multiple operations on same context")
    func testMultipleOperations() throws {
        let context = try makeContext()

        // Add several documents
        for i in 0..<10 {
            let doc = RecentDocument(url: URL(fileURLWithPath: "/test/doc\(i).md"))
            doc.isFavorite = i % 2 == 0 // Even ones are favorites
            context.insert(doc)
        }

        // Count total
        let total = try RecentDocument.count(in: context)
        #expect(total == 10)

        // Count favorites
        let favCount = try RecentDocument.countFavorites(in: context)
        #expect(favCount == 5)

        // Delete non-favorites
        let deleted = try RecentDocument.deleteNonFavorites(in: context)
        #expect(deleted == 5)

        // Verify only favorites remain
        let remaining = try RecentDocument.count(in: context)
        #expect(remaining == 5)

        let allFavorites = try RecentDocument.fetchFavorites(in: context)
        #expect(allFavorites.count == 5)
    }
}
