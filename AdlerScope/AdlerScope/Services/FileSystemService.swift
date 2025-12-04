//
//  FileSystemService.swift
//  AdlerScope
//
//  Platform abstraction layer for file system operations
//  Handles security-scoped bookmarks and file I/O
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "org.advision.AdlerScope", category: "FileSystem")

final class FileSystemService {
    static let shared = FileSystemService()

    nonisolated private init() {}

    // MARK: - Document Loading

    func loadDocument(from url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access security-scoped resource: \(url.path)")
            throw DocumentLoadError.fileNotAccessible(url)
        }

        defer {
            url.stopAccessingSecurityScopedResource()
            #if DEBUG
            logger.debug("Stopped accessing security-scoped resource")
            #endif
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            logger.info("Loaded file: \(url.lastPathComponent) (\(content.count) chars)")
            return content
        } catch {
            logger.error("Failed to read file: \(error.localizedDescription)")
            throw DocumentLoadError.encodingFailed
        }
    }

    // MARK: - Document Saving

    func saveDocument(content: String, to url: URL) async throws {
        // File I/O on background thread
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access for saving: \(url.path)")
            throw DocumentLoadError.fileNotAccessible(url)
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            logger.info("Saved file: \(url.lastPathComponent)")
        } catch {
            logger.error("Failed to save: \(error.localizedDescription)")
            throw DocumentLoadError.saveFailed(error)
        }
    }

    // MARK: - File Validation

    func validateMarkdownFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }

        let allowedExtensions = ["md", "markdown", "txt", "rmd", "qmd"]
        return allowedExtensions.contains(url.pathExtension.lowercased())
    }

    // MARK: - File Information

    func fileMetadata(at url: URL) -> FileMetadata? {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Cannot access file for metadata: \(url.path)")
            return nil
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return FileMetadata(
                fileSize: attributes[.size] as? Int64 ?? 0,
                modifiedDate: attributes[.modificationDate] as? Date ?? Date(),
                createdDate: attributes[.creationDate] as? Date ?? Date()
            )
        } catch {
            logger.error("Failed to get metadata: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - FileMetadata

struct FileMetadata: Sendable {
    let fileSize: Int64
    let modifiedDate: Date
    let createdDate: Date

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
