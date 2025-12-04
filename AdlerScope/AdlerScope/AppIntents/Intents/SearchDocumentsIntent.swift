//
//  SearchDocumentsIntent.swift
//  AdlerScope
//
//  App Intent to search for documents by name
//  Supports Siri phrases like "Search for [query] in AdlerScope"
//

import AppIntents
import SwiftData
import OSLog

/// Searches for documents by name
struct SearchDocumentsIntent: AppIntent {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "SearchDocumentsIntent")

    static var title: LocalizedStringResource = "Search Documents"
    static var description = IntentDescription(
        "Search for markdown documents by name",
        categoryName: "Documents"
    )

    // MARK: - Parameters

    @Parameter(
        title: "Search Query",
        description: "Text to search for in document names"
    )
    var query: String

    @Parameter(
        title: "Include Favorites Only",
        description: "Only search in favorite documents",
        default: false
    )
    var favoritesOnly: Bool

    // MARK: - Summary

    static var parameterSummary: some ParameterSummary {
        When(\.$favoritesOnly, .equalTo, true) {
            Summary("Search favorites for \(\.$query)")
        } otherwise: {
            Summary("Search for \(\.$query)")
        }
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[RecentDocumentEntity]> & ProvidesDialog {
        let container = try getModelContainer()
        let context = ModelContext(container)

        var results: [RecentDocument]

        if favoritesOnly {
            let favorites = try RecentDocument.fetchFavorites(in: context)
            results = favorites.filter {
                $0.displayName.localizedCaseInsensitiveContains(query)
            }
        } else {
            results = try RecentDocument.search(query: query, in: context)
        }

        let entities = results.map { RecentDocumentEntity(from: $0) }

        let dialog: IntentDialog
        if entities.isEmpty {
            dialog = IntentDialog("No documents found matching \"\(query)\"")
        } else if entities.count == 1 {
            dialog = IntentDialog("Found 1 document: \(entities[0].displayName)")
        } else {
            dialog = IntentDialog("Found \(entities.count) documents matching \"\(query)\"")
        }

        return .result(value: entities, dialog: dialog)
    }

    // MARK: - Helper

    private func getModelContainer() throws -> ModelContainer {
        let schema = Schema([AppSettings.self, RecentDocument.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

// MARK: - Intent Donation

extension SearchDocumentsIntent {
    /// Donate this intent when user performs a search in the app
    @MainActor
    static func donate(query: String) async {
        let intent = SearchDocumentsIntent()
        intent.query = query
        intent.favoritesOnly = false

        do {
            try await intent.donate()
        } catch {
            Self.logger.error("Failed to donate SearchDocumentsIntent: \(error, privacy: .public)")
        }
    }
}
