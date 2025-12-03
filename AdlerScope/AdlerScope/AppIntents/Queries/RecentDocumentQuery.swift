//
//  RecentDocumentQuery.swift
//  AdlerScope
//
//  EntityQuery for searching and finding RecentDocuments
//  Used by Siri and Shortcuts to resolve document parameters
//

import AppIntents
import SwiftData
import Foundation

/// EntityQuery for searching and finding RecentDocuments
struct RecentDocumentQuery: EntityQuery {

    // MARK: - String Search

    @MainActor
    func entities(matching string: String) async throws -> [RecentDocumentEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)

        let documents = try RecentDocument.search(query: string, in: context)
        return documents.map { RecentDocumentEntity(from: $0) }
    }

    // MARK: - Fetch by IDs

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [RecentDocumentEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)

        var results: [RecentDocumentEntity] = []

        for id in identifiers {
            let descriptor = FetchDescriptor<RecentDocument>(
                predicate: #Predicate<RecentDocument> { $0.id == id }
            )
            if let document = try context.fetch(descriptor).first {
                results.append(RecentDocumentEntity(from: document))
            }
        }

        return results
    }

    // MARK: - Suggested Entities

    @MainActor
    func suggestedEntities() async throws -> [RecentDocumentEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)

        // Return recent + favorites
        let recents = try RecentDocument.fetchRecent(limit: 5, in: context)
        let favorites = try RecentDocument.fetchFavorites(in: context)

        // Combine and deduplicate
        var seen = Set<UUID>()
        var combined: [RecentDocument] = []

        for doc in favorites + recents {
            if !seen.contains(doc.id) {
                seen.insert(doc.id)
                combined.append(doc)
            }
        }

        return combined.prefix(10).map { RecentDocumentEntity(from: $0) }
    }

    // MARK: - Helper

    private func getModelContainer() throws -> ModelContainer {
        let schema = Schema([AppSettings.self, RecentDocument.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

// MARK: - EntityStringQuery Conformance

extension RecentDocumentQuery: EntityStringQuery {
    /// Provides string-based search capability
    @MainActor
    func entities(matching string: String) async throws -> IntentItemCollection<RecentDocumentEntity> {
        let container = try getModelContainer()
        let context = ModelContext(container)

        let documents = try RecentDocument.search(query: string, in: context)
        let entities = documents.map { RecentDocumentEntity(from: $0) }

        return IntentItemCollection(items: entities)
    }
}
