//
//  RecentDocumentEntity.swift
//  AdlerScope
//
//  AppEntity wrapper for RecentDocument SwiftData model
//  Exposes recent documents to Siri and Shortcuts
//

import AppIntents
import SwiftData
import Foundation

/// AppEntity wrapper for RecentDocument SwiftData model
struct RecentDocumentEntity: AppEntity, Identifiable {
    // MARK: - AppEntity Protocol

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: "Recent Document",
            numericFormat: "\(placeholder: .int) documents"
        )
    }

    static var defaultQuery = RecentDocumentQuery()

    // MARK: - Properties

    let id: UUID
    let url: URL
    let displayName: String
    let lastOpened: Date
    let isFavorite: Bool
    let fileSize: Int64?

    // MARK: - Display Representation

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: isFavorite ? "Favorite" : nil,
            image: .init(systemName: isFavorite ? "star.fill" : "doc.text")
        )
    }

    // MARK: - Initialization from SwiftData Model

    init(from recentDocument: RecentDocument) {
        self.id = recentDocument.id
        self.url = recentDocument.url
        self.displayName = recentDocument.displayName
        self.lastOpened = recentDocument.lastOpened
        self.isFavorite = recentDocument.isFavorite
        self.fileSize = recentDocument.fileSize
    }

    // For manual initialization (testing, previews)
    init(
        id: UUID = UUID(),
        url: URL,
        displayName: String,
        lastOpened: Date = Date(),
        isFavorite: Bool = false,
        fileSize: Int64? = nil
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName
        self.lastOpened = lastOpened
        self.isFavorite = isFavorite
        self.fileSize = fileSize
    }
}
