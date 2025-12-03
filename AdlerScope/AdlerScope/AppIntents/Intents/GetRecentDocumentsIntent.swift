//
//  GetRecentDocumentsIntent.swift
//  AdlerScope
//
//  App Intent to get a list of recent documents
//  Supports Siri phrases like "Show my recent documents in AdlerScope"
//

import AppIntents
import SwiftData

/// Returns a list of recent documents
struct GetRecentDocumentsIntent: AppIntent {

    static var title: LocalizedStringResource = "Get Recent Documents"
    static var description = IntentDescription(
        "Gets a list of recently opened documents",
        categoryName: "Documents"
    )

    // MARK: - Parameters

    @Parameter(
        title: "Limit",
        description: "Maximum number of documents to return",
        default: 10,
        inclusiveRange: (1, 50)
    )
    var limit: Int

    @Parameter(
        title: "Favorites Only",
        description: "Only return favorite documents",
        default: false
    )
    var favoritesOnly: Bool

    // MARK: - Summary

    static var parameterSummary: some ParameterSummary {
        When(\.$favoritesOnly, .equalTo, true) {
            Summary("Get \(\.$limit) favorite documents")
        } otherwise: {
            Summary("Get \(\.$limit) recent documents")
        }
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[RecentDocumentEntity]> & ProvidesDialog {
        let container = try getModelContainer()
        let context = ModelContext(container)

        let documents: [RecentDocument]

        if favoritesOnly {
            documents = try RecentDocument.fetchFavorites(in: context)
        } else {
            documents = try RecentDocument.fetchRecent(limit: limit, in: context)
        }

        let entities = Array(documents.prefix(limit).map { RecentDocumentEntity(from: $0) })

        let dialog: IntentDialog
        if entities.isEmpty {
            dialog = IntentDialog("No documents found")
        } else if entities.count == 1 {
            dialog = IntentDialog("Found 1 document: \(entities[0].displayName)")
        } else {
            dialog = IntentDialog("Found \(entities.count) documents")
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
