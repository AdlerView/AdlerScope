#if os(macOS)
//
//  ImageSourceResolver.swift
//  AdlerScope
//
//  Resolves image source strings to typed ImageSource values.
//  Handles path resolution for absolute paths, relative paths,
//  sidecar images, and remote URLs.
//

import Foundation

/// Resolves image source strings from markdown to typed ImageSource values
struct ImageSourceResolver: Sendable {

    // MARK: - Public Methods

    /// Resolves a source string to an ImageSource
    /// - Parameters:
    ///   - source: Image source from markdown (![alt](source))
    ///   - documentURL: Optional document URL for relative path resolution
    ///   - sidecarManager: Optional sidecar manager for sidecar image resolution
    /// - Returns: Resolved ImageSource
    @MainActor
    func resolve(
        source: String,
        documentURL: URL?,
        sidecarManager: SidecarManager?
    ) -> ImageSource {
        let trimmed = source.trimmingCharacters(in: .whitespaces)

        // 1. Remote URL (http:// or https://)
        if isRemoteURL(trimmed) {
            if let url = URL(string: trimmed) {
                return .remote(url)
            }
            // Invalid URL - fall through to sidecar as fallback
        }

        // 2. Absolute path (starts with /)
        if trimmed.hasPrefix("/") {
            let url = URL(fileURLWithPath: trimmed).standardized
            if FileManager.default.fileExists(atPath: url.path) {
                return .absolute(url)
            }
            // File doesn't exist, but still return as absolute for error reporting
            return .absolute(url)
        }

        // 3. Relative path (starts with ./ or ../)
        if trimmed.hasPrefix("./") || trimmed.hasPrefix("../") {
            if let documentURL = documentURL {
                let baseDir = documentURL.deletingLastPathComponent()
                let resolvedURL = baseDir.appendingPathComponent(trimmed).standardized
                return .documentRelative(resolvedURL)
            }
            // No document URL - can't resolve relative path, fall through to sidecar
        }

        // 4. Sidecar image (default - just a filename or relative path within sidecar)
        let resolvedURL = sidecarManager?.resolveImage(filename: trimmed)

        // Also check if it exists directly in sidecar directory
        if resolvedURL == nil, let sidecarURL = sidecarManager?.sidecarURL {
            let directURL = sidecarURL.appendingPathComponent(trimmed)
            if FileManager.default.fileExists(atPath: directURL.path) {
                return .sidecar(filename: trimmed, resolvedURL: directURL)
            }
        }

        return .sidecar(filename: trimmed, resolvedURL: resolvedURL)
    }

    // MARK: - Private Helpers

    /// Checks if a source string is a remote URL
    private func isRemoteURL(_ source: String) -> Bool {
        source.lowercased().hasPrefix("http://") || source.lowercased().hasPrefix("https://")
    }
}

#endif
