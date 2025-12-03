//
//  iCloudDocumentManager.swift
//  AdlerScope
//
//  Manages iCloud Documents container access and document discovery
//  Handles file coordination, downloads, and metadata queries
//

import Foundation
import OSLog

/// Represents the download status of an iCloud document
enum iCloudDocumentStatus: Equatable {
    case local
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case uploading
    case error(String)

    var isAvailableLocally: Bool {
        switch self {
        case .local, .downloaded:
            return true
        default:
            return false
        }
    }
}

/// Represents an iCloud document with its metadata
struct iCloudDocument: Identifiable, Equatable {
    let id: URL
    let url: URL
    let filename: String
    let fileSize: Int64
    let modificationDate: Date?
    let status: iCloudDocumentStatus
    let isDirectory: Bool

    static func == (lhs: iCloudDocument, rhs: iCloudDocument) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.modificationDate == rhs.modificationDate
    }
}

/// Manager for iCloud Documents container operations
@Observable
@MainActor
class ICloudDocumentManager {
    // MARK: - Constants

    static let containerIdentifier = "iCloud.com.AdlerScope"

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "iCloudDocumentManager")

    /// Whether iCloud is available on this device
    private(set) var isICloudAvailable: Bool = false

    /// The URL to the ubiquity container, if available
    private(set) var ubiquityContainerURL: URL?

    /// The URL to the Documents folder within the ubiquity container
    var documentsURL: URL? {
        ubiquityContainerURL?.appendingPathComponent("Documents", isDirectory: true)
    }

    /// Currently discovered iCloud documents
    private(set) var documents: [iCloudDocument] = []

    /// Active metadata query for document discovery
    private var metadataQuery: NSMetadataQuery?

    /// Observation tokens for query notifications
    private var queryObservers: [NSObjectProtocol] = []

    // MARK: - Initialization

    init() {
        logger.info("iCloudDocumentManager initialized")
    }

    // MARK: - Container Access

    /// Checks iCloud availability and retrieves the container URL
    /// Must be called before any other iCloud operations
    func setupContainer() async {
        logger.debug("Setting up iCloud container...")

        // Capture container identifier before async context
        let containerID = Self.containerIdentifier

        // Check container URL on background queue (can block)
        let containerURL = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let url = FileManager.default.url(forUbiquityContainerIdentifier: containerID)
                continuation.resume(returning: url)
            }
        }

        await MainActor.run {
            self.ubiquityContainerURL = containerURL
            self.isICloudAvailable = containerURL != nil

            if let url = containerURL {
                self.logger.info("iCloud container available at: \(url.path)")
                self.ensureDocumentsDirectoryExists()
            } else {
                self.logger.warning("iCloud is not available")
            }
        }
    }

    /// Ensures the Documents directory exists in the ubiquity container
    private func ensureDocumentsDirectoryExists() {
        guard let documentsURL = documentsURL else { return }

        do {
            if !FileManager.default.fileExists(atPath: documentsURL.path) {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
                logger.info("Created Documents directory in iCloud container")
            }
        } catch {
            logger.error("Failed to create Documents directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Metadata Query

    /// Starts monitoring for iCloud documents using NSMetadataQuery
    func startMetadataQuery() {
        guard isICloudAvailable else {
            logger.warning("Cannot start metadata query - iCloud not available")
            return
        }

        stopMetadataQuery()

        logger.debug("Starting metadata query for iCloud documents...")

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]

        // Search for markdown and text files
        query.predicate = NSPredicate(format: "%K LIKE '*.md' OR %K LIKE '*.markdown' OR %K LIKE '*.txt' OR %K LIKE '*.rmd' OR %K LIKE '*.qmd'",
                                       NSMetadataItemFSNameKey, NSMetadataItemFSNameKey, NSMetadataItemFSNameKey,
                                       NSMetadataItemFSNameKey, NSMetadataItemFSNameKey)

        // Sort by modification date
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey, ascending: false)]

        // Observe query notifications
        let gatheringObserver = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                strongSelf.handleQueryResults()
            }
        }

        let updateObserver = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                strongSelf.handleQueryResults()
            }
        }

        queryObservers = [gatheringObserver, updateObserver]
        metadataQuery = query

        query.start()
        logger.info("Metadata query started")
    }

    /// Stops the metadata query
    func stopMetadataQuery() {
        metadataQuery?.stop()
        metadataQuery = nil

        for observer in queryObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        queryObservers = []

        logger.debug("Metadata query stopped")
    }

    /// Handles metadata query results
    private func handleQueryResults() {
        guard let query = metadataQuery else { return }

        query.disableUpdates()
        defer { query.enableUpdates() }

        var discoveredDocuments: [iCloudDocument] = []

        for i in 0..<query.resultCount {
            guard let item = query.result(at: i) as? NSMetadataItem else { continue }

            if let document = parseMetadataItem(item) {
                discoveredDocuments.append(document)
            }
        }

        self.documents = discoveredDocuments
        logger.debug("Found \(discoveredDocuments.count) iCloud documents")
    }

    /// Parses an NSMetadataItem into an iCloudDocument
    private func parseMetadataItem(_ item: NSMetadataItem) -> iCloudDocument? {
        guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else {
            return nil
        }

        let filename = item.value(forAttribute: NSMetadataItemFSNameKey) as? String ?? url.lastPathComponent
        let fileSize = item.value(forAttribute: NSMetadataItemFSSizeKey) as? Int64 ?? 0
        let modDate = item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date
        let isDirectory = item.value(forAttribute: NSMetadataItemContentTypeKey) as? String == "public.folder"

        // Determine download status
        let downloadStatus = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
        let isDownloading = item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? Bool ?? false
        let isUploading = item.value(forAttribute: NSMetadataUbiquitousItemIsUploadingKey) as? Bool ?? false
        let downloadPercent = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double ?? 0

        let status: iCloudDocumentStatus
        if isUploading {
            status = .uploading
        } else if isDownloading {
            status = .downloading(progress: downloadPercent / 100.0)
        } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent {
            status = .downloaded
        } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
            status = .notDownloaded
        } else {
            status = .local
        }

        return iCloudDocument(
            id: url,
            url: url,
            filename: filename,
            fileSize: fileSize,
            modificationDate: modDate,
            status: status,
            isDirectory: isDirectory
        )
    }

    // MARK: - Download Operations

    /// Initiates download of a document that is not yet available locally
    /// - Parameter url: The URL of the document to download
    func startDownload(at url: URL) async throws {
        logger.debug("Starting download for: \(url.lastPathComponent)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Download initiated for: \(url.lastPathComponent)")
    }

    /// Removes the local copy of a document to free storage space
    /// The document will still be available in iCloud
    /// - Parameter url: The URL of the document to evict
    func evictLocalCopy(at url: URL) async throws {
        logger.debug("Evicting local copy: \(url.lastPathComponent)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try FileManager.default.evictUbiquitousItem(at: url)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Evicted local copy: \(url.lastPathComponent)")
    }

    // MARK: - File Coordination

    /// Reads a document using file coordination for safe iCloud access
    /// - Parameter url: The URL of the document to read
    /// - Returns: The document data
    func readDocument(at url: URL) async throws -> Data {
        logger.debug("Reading document with coordination: \(url.lastPathComponent)")

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = NSFileCoordinator()
            var error: NSError?

            coordinator.coordinate(readingItemAt: url, options: [], error: &error) { coordinatedURL in
                do {
                    let data = try Data(contentsOf: coordinatedURL)
                    continuation.resume(returning: data)
                } catch let readError {
                    continuation.resume(throwing: readError)
                }
            }

            if let error = error {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Writes data to a document using file coordination for safe iCloud access
    /// - Parameters:
    ///   - data: The data to write
    ///   - url: The destination URL
    func writeDocument(_ data: Data, to url: URL) async throws {
        logger.debug("Writing document with coordination: \(url.lastPathComponent)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var error: NSError?

            coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { coordinatedURL in
                do {
                    try data.write(to: coordinatedURL, options: .atomic)
                    continuation.resume()
                } catch let writeError {
                    continuation.resume(throwing: writeError)
                }
            }

            if let error = error {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Document written: \(url.lastPathComponent)")
    }

    // MARK: - Document Operations

    /// Moves a local document to the iCloud Documents folder
    /// - Parameters:
    ///   - localURL: The local URL of the document
    ///   - filename: The filename to use in iCloud (optional, uses original if nil)
    /// - Returns: The new iCloud URL
    func moveToCloud(from localURL: URL, filename: String? = nil) async throws -> URL {
        guard let documentsURL = documentsURL else {
            throw iCloudError.containerNotAvailable
        }

        let destinationFilename = filename ?? localURL.lastPathComponent
        let destinationURL = documentsURL.appendingPathComponent(destinationFilename)

        logger.debug("Moving to iCloud: \(localURL.lastPathComponent) -> \(destinationFilename)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try FileManager.default.setUbiquitous(true, itemAt: localURL, destinationURL: destinationURL)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Moved to iCloud: \(destinationFilename)")
        return destinationURL
    }

    /// Moves an iCloud document to local storage
    /// - Parameters:
    ///   - cloudURL: The iCloud URL of the document
    ///   - localURL: The destination local URL
    func moveToLocal(from cloudURL: URL, to localURL: URL) async throws {
        logger.debug("Moving to local: \(cloudURL.lastPathComponent)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try FileManager.default.setUbiquitous(false, itemAt: cloudURL, destinationURL: localURL)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Moved to local: \(localURL.lastPathComponent)")
    }

    /// Deletes a document from iCloud
    /// - Parameter url: The URL of the document to delete
    func deleteDocument(at url: URL) async throws {
        logger.debug("Deleting iCloud document: \(url.lastPathComponent)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var error: NSError?

            coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &error) { coordinatedURL in
                do {
                    try FileManager.default.removeItem(at: coordinatedURL)
                    continuation.resume()
                } catch let deleteError {
                    continuation.resume(throwing: deleteError)
                }
            }

            if let error = error {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Deleted iCloud document: \(url.lastPathComponent)")
    }
}

// MARK: - Errors

enum iCloudError: LocalizedError {
    case containerNotAvailable
    case documentNotFound
    case downloadFailed(String)
    case uploadFailed(String)
    case coordinationFailed(String)

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "iCloud container is not available. Please ensure you are signed in to iCloud."
        case .documentNotFound:
            return "The document could not be found in iCloud."
        case .downloadFailed(let reason):
            return "Failed to download document: \(reason)"
        case .uploadFailed(let reason):
            return "Failed to upload document: \(reason)"
        case .coordinationFailed(let reason):
            return "File coordination failed: \(reason)"
        }
    }
}
