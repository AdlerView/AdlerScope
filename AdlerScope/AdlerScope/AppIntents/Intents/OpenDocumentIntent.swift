//
//  OpenDocumentIntent.swift
//  AdlerScope
//
//  App Intent to open a markdown document
//  Supports Siri phrases like "Open [document] in AdlerScope"
//

import AppIntents
import SwiftData

/// Opens a markdown document in AdlerScope
struct OpenDocumentIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Document"
    static var description = IntentDescription(
        "Opens a markdown document in AdlerScope",
        categoryName: "Documents"
    )

    // MARK: - Parameters

    @Parameter(
        title: "Document",
        description: "The document to open"
    )
    var document: RecentDocumentEntity

    // MARK: - Intent Configuration

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$document)")
    }

    static var openAppWhenRun: Bool { true }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // Use NavigationService to trigger document opening
        NavigationService.shared.requestOpenDocument(id: document.id)

        return .result()
    }
}

// MARK: - Intent Donation

extension OpenDocumentIntent {
    /// Donate this intent when user opens a document directly in the app
    @MainActor
    static func donate(for document: RecentDocument) async {
        let intent = OpenDocumentIntent()
        intent.document = RecentDocumentEntity(from: document)

        do {
            try await intent.donate()
        } catch {
            print("Failed to donate OpenDocumentIntent: \(error)")
        }
    }
}
