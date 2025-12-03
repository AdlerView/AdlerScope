//
//  iCloudDocumentEntity.swift
//  AdlerScope
//
//  AppEntity wrapper for iCloudDocument struct
//  Exposes iCloud documents to Siri and Shortcuts
//

import AppIntents
import Foundation

/// AppEntity wrapper for iCloudDocument struct
struct iCloudDocumentEntity: AppEntity, Identifiable {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: "iCloud Document",
            numericFormat: "\(placeholder: .int) iCloud documents"
        )
    }

    static var defaultQuery = iCloudDocumentQuery()

    // MARK: - Properties

    /// String identifier derived from URL path
    let id: String
    let url: URL
    let filename: String
    let fileSize: Int64
    let modificationDate: Date?
    let isDownloaded: Bool

    // MARK: - Display

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(filename)",
            subtitle: isDownloaded ? "Downloaded" : "In iCloud",
            image: .init(systemName: isDownloaded ? "doc.fill" : "icloud")
        )
    }

    // MARK: - Initialization

    init(from iCloudDoc: iCloudDocument) {
        self.id = iCloudDoc.url.absoluteString
        self.url = iCloudDoc.url
        self.filename = iCloudDoc.filename
        self.fileSize = iCloudDoc.fileSize
        self.modificationDate = iCloudDoc.modificationDate
        self.isDownloaded = iCloudDoc.status.isAvailableLocally
    }

    // For manual initialization (testing, previews)
    init(
        url: URL,
        filename: String,
        fileSize: Int64 = 0,
        modificationDate: Date? = nil,
        isDownloaded: Bool = false
    ) {
        self.id = url.absoluteString
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.modificationDate = modificationDate
        self.isDownloaded = isDownloaded
    }
}
