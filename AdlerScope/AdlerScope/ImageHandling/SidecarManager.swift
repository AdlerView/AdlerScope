//
//  SidecarManager.swift
//  AdlerScope
//
//  Manages the sidecar directory (Document.assets/) for storing images
//  associated with a markdown document.
//
//  Sidecar Model:
//  - MyNote.md → MyNote.assets/ (companion directory)
//  - Images stored with relative paths in markdown: ![alt](image.png)
//

import Foundation
import Observation
import UniformTypeIdentifiers

/// Manages the sidecar directory for a markdown document
@Observable
@MainActor
final class SidecarManager {
    // MARK: - Properties

    /// URL to the sidecar directory (e.g., MyNote.assets/)
    private(set) var sidecarURL: URL?

    /// Manifest of images in the sidecar: filename → full URL
    private(set) var imageManifest: [String: URL] = [:]

    /// URL of the parent document
    private(set) var documentURL: URL?

    /// Parent directory URL (for security-scoped access)
    private var parentDirectoryURL: URL?

    /// Whether security-scoped access is active
    private var isAccessingSecurityScope = false

    /// Whether the sidecar directory exists
    var sidecarExists: Bool {
        guard let url = sidecarURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    deinit {
        // Note: deinit won't be called on MainActor, but we track the state
        // The actual cleanup happens in reset()
    }

    // MARK: - Configuration

    /// Configures the sidecar manager for a document
    /// - Parameter documentURL: The URL of the markdown document
    func configure(for documentURL: URL) {
        // Stop any previous security-scoped access
        stopSecurityScopedAccess()

        self.documentURL = documentURL

        let baseName = documentURL.deletingPathExtension().lastPathComponent
        let parentDir = documentURL.deletingLastPathComponent()
        self.parentDirectoryURL = parentDir

        // Start security-scoped access on the parent directory
        // This allows reading sibling files/directories like .assets/
        startSecurityScopedAccess()

        // Try naming conventions in order of preference
        let candidates = [
            "\(baseName).assets",
            "_\(baseName)_assets",
            ".\(baseName).assets"
        ]

        // Check if any existing sidecar directory exists
        for name in candidates {
            let url = parentDir.appendingPathComponent(name, isDirectory: true)
            if FileManager.default.fileExists(atPath: url.path) {
                sidecarURL = url
                loadManifest()
                return
            }
        }

        // No sidecar exists yet – use default naming convention
        // Will be created on first image insert
        sidecarURL = parentDir.appendingPathComponent("\(baseName).assets", isDirectory: true)
        imageManifest = [:]
    }

    /// Resets the manager state
    func reset() {
        stopSecurityScopedAccess()
        sidecarURL = nil
        documentURL = nil
        parentDirectoryURL = nil
        imageManifest = [:]
    }

    // MARK: - Security-Scoped Access

    /// Starts security-scoped access on the parent directory
    private func startSecurityScopedAccess() {
        // Try the document URL first (it has security scope from DocumentGroup)
        if let docURL = documentURL {
            _ = docURL.startAccessingSecurityScopedResource()
        }

        // Also try the parent directory
        if let parentURL = parentDirectoryURL {
            isAccessingSecurityScope = parentURL.startAccessingSecurityScopedResource()
        }
    }

    /// Stops security-scoped access
    private func stopSecurityScopedAccess() {
        if isAccessingSecurityScope, let parentURL = parentDirectoryURL {
            parentURL.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
        if let docURL = documentURL {
            docURL.stopAccessingSecurityScopedResource()
        }
    }

    // MARK: - Manifest Management

    /// Scans the sidecar directory and populates the image manifest
    private func loadManifest() {
        guard let sidecarURL else {
            imageManifest = [:]
            return
        }

        guard FileManager.default.fileExists(atPath: sidecarURL.path) else {
            imageManifest = [:]
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: sidecarURL,
                includingPropertiesForKeys: [.isRegularFileKey, .typeIdentifierKey],
                options: [.skipsHiddenFiles]
            )

            // Filter to only image files
            let imageFiles = contents.filter { url in
                guard let values = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
                      let typeIdentifier = values.typeIdentifier,
                      let utType = UTType(typeIdentifier) else {
                    return false
                }
                return utType.conforms(to: .image)
            }

            imageManifest = Dictionary(uniqueKeysWithValues: imageFiles.map {
                ($0.lastPathComponent, $0)
            })
        } catch {
            imageManifest = [:]
        }
    }

    /// Refreshes the manifest from disk
    func refreshManifest() {
        loadManifest()
    }

    // MARK: - Image Operations

    /// Adds an image to the sidecar directory
    /// - Parameters:
    ///   - sourceURL: The source URL of the image to add
    ///   - preferredName: Optional preferred filename (will be sanitized)
    /// - Returns: The filename used in the sidecar (for markdown syntax)
    /// - Throws: SidecarError if the operation fails
    func addImage(from sourceURL: URL, preferredName: String? = nil) throws -> String {
        guard let sidecarURL else {
            throw SidecarError.noSidecarConfigured
        }

        // Validate source is an image
        guard let values = try? sourceURL.resourceValues(forKeys: [.typeIdentifierKey]),
              let typeIdentifier = values.typeIdentifier,
              let utType = UTType(typeIdentifier),
              utType.conforms(to: .image) else {
            throw SidecarError.invalidImageFormat(sourceURL.lastPathComponent)
        }

        // Create sidecar directory if needed
        if !FileManager.default.fileExists(atPath: sidecarURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: sidecarURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw SidecarError.directoryCreationFailed(underlying: error)
            }
        }

        // Determine filename
        let baseName = preferredName ?? sourceURL.lastPathComponent
        let sanitizedName = sanitizeFilename(baseName)
        let filename = uniqueFilename(for: sanitizedName)
        let destURL = sidecarURL.appendingPathComponent(filename)

        // Copy image to sidecar
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            imageManifest[filename] = destURL
            return filename
        } catch {
            throw SidecarError.copyFailed(filename, underlying: error)
        }
    }

    /// Adds image data to the sidecar directory
    /// - Parameters:
    ///   - data: The image data
    ///   - preferredName: Preferred filename (must include extension)
    /// - Returns: The filename used in the sidecar
    /// - Throws: SidecarError if the operation fails
    func addImageData(_ data: Data, preferredName: String) throws -> String {
        guard let sidecarURL else {
            throw SidecarError.noSidecarConfigured
        }

        // Create sidecar directory if needed
        if !FileManager.default.fileExists(atPath: sidecarURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: sidecarURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw SidecarError.directoryCreationFailed(underlying: error)
            }
        }

        let sanitizedName = sanitizeFilename(preferredName)
        let filename = uniqueFilename(for: sanitizedName)
        let destURL = sidecarURL.appendingPathComponent(filename)

        do {
            try data.write(to: destURL)
            imageManifest[filename] = destURL
            return filename
        } catch {
            throw SidecarError.copyFailed(filename, underlying: error)
        }
    }

    /// Resolves a filename to its full URL
    /// - Parameter filename: The image filename
    /// - Returns: The full URL if the image exists, nil otherwise
    func resolveImage(filename: String) -> URL? {
        imageManifest[filename]
    }

    /// Checks if an image exists in the sidecar
    /// - Parameter filename: The image filename
    /// - Returns: true if the image exists
    func imageExists(filename: String) -> Bool {
        imageManifest[filename] != nil
    }

    // MARK: - Filename Utilities

    /// Generates a unique filename, incrementing if necessary
    /// - Parameter base: The base filename
    /// - Returns: A unique filename
    private func uniqueFilename(for base: String) -> String {
        var filename = base
        var counter = 1

        while imageManifest[filename] != nil {
            let ext = (base as NSString).pathExtension
            let name = (base as NSString).deletingPathExtension
            filename = "\(name)-\(counter).\(ext)"
            counter += 1
        }

        return filename
    }

    /// Sanitizes a filename for safe filesystem use
    /// - Parameter filename: The original filename
    /// - Returns: A sanitized filename
    private func sanitizeFilename(_ filename: String) -> String {
        // Replace problematic characters with underscores
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        var sanitized = filename.components(separatedBy: invalidCharacters).joined(separator: "_")

        // Ensure filename is not empty
        if sanitized.isEmpty || sanitized == "." || sanitized == ".." {
            sanitized = "image"
        }

        // Ensure extension exists for common image types
        let ext = (sanitized as NSString).pathExtension.lowercased()
        if ext.isEmpty {
            sanitized += ".png"
        }

        return sanitized
    }

    // MARK: - Static Helpers

    /// Computes the sidecar URL for a given document URL
    /// - Parameter documentURL: The document URL
    /// - Returns: The sidecar URL
    static func sidecarURL(for documentURL: URL) -> URL {
        let baseName = documentURL.deletingPathExtension().lastPathComponent
        return documentURL.deletingLastPathComponent()
            .appendingPathComponent("\(baseName).assets", isDirectory: true)
    }
}
