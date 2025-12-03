//
//  iCloudDocumentQuery.swift
//  AdlerScope
//
//  EntityQuery for searching and finding iCloud documents
//  Used by Siri and Shortcuts to resolve iCloud document parameters
//

import AppIntents
import Foundation

/// EntityQuery for iCloud documents
struct iCloudDocumentQuery: EntityQuery {

    // MARK: - Fetch by IDs

    @MainActor
    func entities(for identifiers: [String]) async throws -> [iCloudDocumentEntity] {
        let manager = DependencyContainer.shared.iCloudDocumentManager
        let idSet = Set(identifiers)

        let matching = manager.documents.filter { idSet.contains($0.url.absoluteString) }
        return matching.map { iCloudDocumentEntity(from: $0) }
    }

    // MARK: - Suggested Entities

    @MainActor
    func suggestedEntities() async throws -> [iCloudDocumentEntity] {
        let manager = DependencyContainer.shared.iCloudDocumentManager

        // Return downloaded documents first, then others
        let sorted = manager.documents.sorted { a, b in
            if a.status.isAvailableLocally != b.status.isAvailableLocally {
                return a.status.isAvailableLocally
            }
            return (a.modificationDate ?? .distantPast) > (b.modificationDate ?? .distantPast)
        }

        return sorted.prefix(10).map { iCloudDocumentEntity(from: $0) }
    }
}

// MARK: - EntityStringQuery Conformance

extension iCloudDocumentQuery: EntityStringQuery {
    /// Provides string-based search capability
    @MainActor
    func entities(matching string: String) async throws -> [iCloudDocumentEntity] {
        let manager = DependencyContainer.shared.iCloudDocumentManager

        // Filter by filename
        let filtered = manager.documents.filter {
            $0.filename.localizedCaseInsensitiveContains(string)
        }

        return filtered.map { iCloudDocumentEntity(from: $0) }
    }
}
