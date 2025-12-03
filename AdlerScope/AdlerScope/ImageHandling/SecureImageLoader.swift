#if os(macOS)
//
//  SecureImageLoader.swift
//  AdlerScope
//
//  Actor for sandbox-safe asynchronous image loading.
//  Handles security-scoped resource access and caching.
//

import AppKit
import Foundation

/// Result of an image load operation
enum ImageLoadResult: Sendable {
    /// Image loaded successfully
    case success(NSImage)

    /// Image file is missing
    case missing(altText: String)

    /// Image file is corrupt or invalid
    case corrupt(altText: String)

    /// Image is currently loading
    case loading
}

/// Actor for sandbox-safe asynchronous image loading with caching
actor SecureImageLoader {
    // MARK: - Properties

    /// In-memory cache of loaded images
    private var cache: [URL: NSImage] = [:]

    /// Security-scoped bookmarks for accessing files outside the sandbox
    private var securityBookmarks: [URL: Data] = [:]

    /// Maximum cache size (number of images)
    private let maxCacheSize: Int

    // MARK: - Initialization

    init(maxCacheSize: Int = 100) {
        self.maxCacheSize = maxCacheSize
    }

    // MARK: - Image Loading

    /// Loads an image from a URL with sandbox safety
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - altText: Alternative text for error states
    ///   - documentURL: Optional document URL to determine if security scope is needed
    /// - Returns: The load result
    func loadImage(from url: URL, altText: String, documentURL: URL?) async -> ImageLoadResult {
        // Check cache first
        if let cached = cache[url] {
            return .success(cached)
        }

        // Determine if we need security scope (file outside document directory)
        let needsScope = requiresSecurityScope(url: url, documentURL: documentURL)
        var accessGranted = false
        var resolvedURL = url

        if needsScope {
            // Try to resolve from stored bookmark
            if let bookmark = securityBookmarks[url] {
                var isStale = false
                if let resolved = try? URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ) {
                    resolvedURL = resolved
                    accessGranted = resolved.startAccessingSecurityScopedResource()

                    // Refresh stale bookmark
                    if isStale, accessGranted {
                        storeBookmark(for: resolved)
                    }
                }
            }

            if !accessGranted {
                // Cannot access file without security scope
                return .missing(altText: altText)
            }
        }

        defer {
            if needsScope && accessGranted {
                resolvedURL.stopAccessingSecurityScopedResource()
            }
        }

        // Check file exists
        guard FileManager.default.fileExists(atPath: resolvedURL.path) else {
            return .missing(altText: altText)
        }

        // Load image
        guard let image = NSImage(contentsOf: resolvedURL), image.isValid else {
            return .corrupt(altText: altText)
        }

        // Cache the image
        addToCache(url: url, image: image)

        return .success(image)
    }

    /// Loads an image synchronously (for use from MainActor context)
    /// - Parameters:
    ///   - url: The URL of the image
    ///   - altText: Alternative text for error states
    /// - Returns: The load result
    func loadImageSync(from url: URL, altText: String) -> ImageLoadResult {
        // Check cache
        if let cached = cache[url] {
            return .success(cached)
        }

        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .missing(altText: altText)
        }

        // Load image
        guard let image = NSImage(contentsOf: url), image.isValid else {
            return .corrupt(altText: altText)
        }

        // Cache
        addToCache(url: url, image: image)

        return .success(image)
    }

    // MARK: - Cache Management

    /// Adds an image to the cache, evicting old entries if needed
    private func addToCache(url: URL, image: NSImage) {
        // Simple FIFO eviction when cache is full
        if cache.count >= maxCacheSize {
            // Remove oldest entry (first key)
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
        }
        cache[url] = image
    }

    /// Clears the entire image cache
    func clearCache() {
        cache.removeAll()
    }

    /// Removes a specific image from the cache
    func evict(url: URL) {
        cache.removeValue(forKey: url)
    }

    /// Returns the current cache size
    var cacheCount: Int {
        cache.count
    }

    // MARK: - Security Bookmarks

    /// Stores a security-scoped bookmark for a URL
    /// - Parameter url: The URL to bookmark
    func storeBookmark(for url: URL) {
        guard url.isFileURL else { return }

        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            securityBookmarks[url] = data
        } catch {
            // Silently fail - bookmarks are optional optimization
        }
    }

    /// Removes a security bookmark
    func removeBookmark(for url: URL) {
        securityBookmarks.removeValue(forKey: url)
    }

    /// Clears all security bookmarks
    func clearBookmarks() {
        securityBookmarks.removeAll()
    }

    // MARK: - Helpers

    /// Determines if a URL requires security scope to access
    /// - Parameters:
    ///   - url: The URL to check
    ///   - documentURL: The document URL for context
    /// - Returns: true if security scope is required
    private func requiresSecurityScope(url: URL, documentURL: URL?) -> Bool {
        guard url.isFileURL else { return false }
        guard let docURL = documentURL else { return true }

        let docDir = docURL.deletingLastPathComponent()

        // Check if URL is within document directory (including sidecar)
        return !url.path.hasPrefix(docDir.path)
    }
}

#endif
