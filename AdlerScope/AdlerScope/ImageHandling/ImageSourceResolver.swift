#if os(macOS)
//
//  ImageSourceResolver.swift
//  AdlerScope
//
//  Resolves image source strings to typed ImageSource values.
//  Handles path resolution for absolute paths, relative paths,
//  sidecar images, and remote URLs.
//
//  CommonMark Compliance:
//  - Supports angle-bracketed URLs: <url with spaces>
//  - Processes backslash escapes: \) → )
//  - Plain filenames resolve document-relative first, sidecar as fallback
//

import Foundation

/// Resolves image source strings from markdown to typed ImageSource values
///
/// Resolution priority:
/// 1. Remote URLs (http://, https://)
/// 2. Absolute paths (/)
/// 3. Explicit relative paths (./, ../)
/// 4. Plain filenames: document-relative if file exists, otherwise sidecar
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
        // Parse according to CommonMark rules (strips angle brackets, processes escapes)
        let normalized = CommonMarkURLParser.parse(source)

        // Empty source
        guard !normalized.isEmpty else {
            return .sidecar(filename: "", resolvedURL: nil)
        }

        // 1. Remote URL (http:// or https://)
        if isRemoteURL(normalized) {
            if let url = URL(string: normalized) {
                return .remote(url)
            }
            // Invalid URL - fall through to sidecar as fallback
        }

        // 2. Absolute path (starts with /)
        if normalized.hasPrefix("/") {
            let url = URL(fileURLWithPath: normalized).standardized
            return .absolute(url)
        }

        // 3. Explicit relative path (starts with ./ or ../)
        if normalized.hasPrefix("./") || normalized.hasPrefix("../") {
            if let documentURL = documentURL {
                let baseDir = documentURL.deletingLastPathComponent()
                let resolvedURL = baseDir.appendingPathComponent(normalized).standardized
                return .documentRelative(resolvedURL)
            }
            // No document URL - can't resolve relative path, fall through to plain filename
        }

        // 4. Plain filename - CommonMark-compliant resolution
        return resolvePlainFilename(normalized, documentURL: documentURL, sidecarManager: sidecarManager)
    }

    // MARK: - Private Resolution Methods

    /// Resolves plain filenames with CommonMark-compliant priority
    ///
    /// Priority order:
    /// 1. Document-relative (if file exists in document directory)
    /// 2. Sidecar (if file exists in sidecar directory)
    /// 3. Document-relative (for error reporting, even if not found)
    @MainActor
    private func resolvePlainFilename(
        _ filename: String,
        documentURL: URL?,
        sidecarManager: SidecarManager?
    ) -> ImageSource {
        // Security: Reject filenames with path traversal attempts
        if containsPathTraversal(filename) {
            return .sidecar(filename: filename, resolvedURL: nil)
        }

        // Try document-relative first (CommonMark compliant)
        if let documentURL = documentURL {
            let baseDir = documentURL.deletingLastPathComponent()
            let documentRelativeURL = baseDir.appendingPathComponent(filename).standardized

            // Security: Ensure resolved URL is within document directory
            if documentRelativeURL.path.hasPrefix(baseDir.path) {
                if FileManager.default.fileExists(atPath: documentRelativeURL.path) {
                    return .documentRelative(documentRelativeURL)
                }
            }
        }

        // Try sidecar (backward compatibility)
        if let sidecarManager = sidecarManager {
            // Check manifest first
            if let sidecarURL = sidecarManager.resolveImage(filename: filename) {
                return .sidecar(filename: filename, resolvedURL: sidecarURL)
            }

            // Check direct path in sidecar directory
            if let sidecarDir = sidecarManager.sidecarURL {
                let directURL = sidecarDir.appendingPathComponent(filename).standardized

                // Security: Verify resolved URL is still within sidecar directory
                if directURL.path.hasPrefix(sidecarDir.path) {
                    if FileManager.default.fileExists(atPath: directURL.path) {
                        return .sidecar(filename: filename, resolvedURL: directURL)
                    }
                }
            }
        }

        // Default: document-relative (for error reporting, even if file not found)
        if let documentURL = documentURL {
            let baseDir = documentURL.deletingLastPathComponent()
            let resolvedURL = baseDir.appendingPathComponent(filename).standardized
            return .documentRelative(resolvedURL)
        }

        // No document context - fall back to sidecar
        return .sidecar(filename: filename, resolvedURL: nil)
    }

    // MARK: - Private Helpers

    /// Checks if a source string is a remote URL
    private func isRemoteURL(_ source: String) -> Bool {
        let lowercased = source.lowercased()
        return lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://")
    }

    /// Checks if a filename contains path traversal sequences
    /// - Parameter filename: The filename to check
    /// - Returns: true if the filename contains suspicious path traversal sequences
    private func containsPathTraversal(_ filename: String) -> Bool {
        // Reject common path traversal patterns
        let dangerousPatterns = [
            "..",           // Parent directory traversal
            "//",           // Double slash
            "\\",           // Backslash (Windows-style)
            "\0",           // Null byte
        ]

        for pattern in dangerousPatterns {
            if filename.contains(pattern) {
                return true
            }
        }

        // Also reject absolute paths that start with /
        if filename.hasPrefix("/") {
            return true
        }

        return false
    }
}

#endif
