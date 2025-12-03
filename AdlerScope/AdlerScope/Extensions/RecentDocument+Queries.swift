//
//  RecentDocument+Queries.swift
//  AdlerScope
//
//  SwiftData query extensions using FetchDescriptor and #Predicate
//  Based on BackyardBirds patterns
//

import SwiftData
import Foundation

extension RecentDocument {

    // MARK: - Find Queries

    /// Find a document by URL using FetchDescriptor
    static func find(url: URL, in context: ModelContext) throws -> RecentDocument? {
        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { $0.url == url }
        )
        return try context.fetch(descriptor).first
    }

    /// Find a document by ID
    static func find(id: PersistentIdentifier, in context: ModelContext) throws -> RecentDocument? {
        return context.model(for: id) as? RecentDocument
    }

    // MARK: - Favorites Queries

    /// Fetch all favorite documents, sorted by last opened
    static func fetchFavorites(in context: ModelContext) throws -> [RecentDocument] {
        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { $0.isFavorite },
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Count favorite documents
    static func countFavorites(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { $0.isFavorite }
        )
        return try context.fetchCount(descriptor)
    }

    // MARK: - Recent Documents Queries

    /// Fetch recent documents with optional limit
    static func fetchRecent(limit: Int = 20, in context: ModelContext) throws -> [RecentDocument] {
        var descriptor = FetchDescriptor<RecentDocument>(
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    /// Fetch documents modified within the last N days
    static func fetchRecentlyModified(days: Int = 7, in context: ModelContext) throws -> [RecentDocument] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { $0.lastOpened >= cutoffDate },
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Search Queries

    /// Search documents by display name
    static func search(query: String, in context: ModelContext) throws -> [RecentDocument] {
        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { document in
                document.displayName.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Statistics

    /// Count all documents
    static func count(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<RecentDocument>()
        return try context.fetchCount(descriptor)
    }

    /// Get the most recently opened document
    static func mostRecent(in context: ModelContext) throws -> RecentDocument? {
        var descriptor = FetchDescriptor<RecentDocument>(
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Cleanup

    /// Delete documents older than N days
    @discardableResult
    static func deleteOlderThan(days: Int, in context: ModelContext) throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { $0.lastOpened < cutoffDate }
        )

        let oldDocuments = try context.fetch(descriptor)
        oldDocuments.forEach { context.delete($0) }
        return oldDocuments.count
    }

    /// Delete all non-favorite documents
    @discardableResult
    static func deleteNonFavorites(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<RecentDocument>(
            predicate: #Predicate<RecentDocument> { !$0.isFavorite }
        )

        let nonFavorites = try context.fetch(descriptor)
        nonFavorites.forEach { context.delete($0) }
        return nonFavorites.count
    }
}

// MARK: - Async Variants
//
// Note: Async variants removed due to Swift 6 Sendable requirements.
// SwiftData PersistentModels are not Sendable by design.
// Use the synchronous query methods directly within @MainActor context.
