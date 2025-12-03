//
//  CreateNewDocumentIntent.swift
//  AdlerScope
//
//  App Intent to create a new markdown document
//  Supports Siri phrases like "Create a new document in AdlerScope"
//

import AppIntents

/// Creates a new markdown document
struct CreateNewDocumentIntent: AppIntent {

    static var title: LocalizedStringResource = "Create New Document"
    static var description = IntentDescription(
        "Creates a new blank markdown document",
        categoryName: "Documents"
    )

    // MARK: - Parameters

    @Parameter(
        title: "Initial Content",
        description: "Optional initial content for the document",
        default: nil
    )
    var initialContent: String?

    // MARK: - Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Create new document")
    }

    static var openAppWhenRun: Bool { true }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        NavigationService.shared.requestNewDocument(initialContent: initialContent)
        return .result()
    }
}
