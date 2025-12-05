#if os(macOS)
//
//  SecureImageLoader.swift
//  AdlerScope
//
//  Actor for sandbox-safe asynchronous image loading.
//  Handles security-scoped resource access, caching, and remote downloads.
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

    // MARK: - Singleton

    /// Shared instance for app-wide image loading
    static let shared = SecureImageLoader(maxCacheSize: 100, maxRemoteCacheSize: 50)

    // MARK: - Properties

    /// In-memory cache of loaded local images
    private var cache: [URL: NSImage] = [:]

    /// In-memory cache for remote images (HTTP/HTTPS)
    private var remoteCache: [URL: NSImage] = [:]

    /// Active download tasks to prevent duplicate downloads
    private var activeDownloads: [URL: Task<ImageLoadResult, Never>] = [:]

    /// Security-scoped bookmarks for accessing files outside the sandbox
    private var securityBookmarks: [URL: Data] = [:]

    /// Maximum cache size for local images
    private let maxCacheSize: Int

    /// Maximum cache size for remote images
    private let maxRemoteCacheSize: Int

    /// URLSession for HTTP downloads (memory-only cache)
    private let urlSession: URLSession

    // MARK: - Initialization

    init(maxCacheSize: Int = 100, maxRemoteCacheSize: Int = 50) {
        self.maxCacheSize = maxCacheSize
        self.maxRemoteCacheSize = maxRemoteCacheSize

        // Configure URLSession with no disk cache (memory-only)
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - ImageSource-based Loading (NEW)

    /// Loads an image from an ImageSource
    /// - Parameters:
    ///   - source: The typed image source
    ///   - altText: Alternative text for error states
    ///   - documentURL: Optional document URL for security scope determination
    ///   - onProgress: Optional progress callback for remote downloads (0.0 to 1.0)
    /// - Returns: The load result
    func load(
        source: ImageSource,
        altText: String,
        documentURL: URL?,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async -> ImageLoadResult {
        switch source {
        case .absolute(let url):
            return await loadLocal(url: url, altText: altText, documentURL: documentURL)

        case .documentRelative(let url):
            return await loadLocal(url: url, altText: altText, documentURL: documentURL)

        case .sidecar(_, let resolvedURL):
            guard let url = resolvedURL else {
                return .missing(altText: altText)
            }
            return await loadLocal(url: url, altText: altText, documentURL: documentURL)

        case .remote(let url):
            return await loadRemote(url: url, altText: altText, onProgress: onProgress)
        }
    }

    // MARK: - Local Image Loading

    /// Loads a local image from a file URL
    /// - Parameters:
    ///   - url: The file URL of the image
    ///   - altText: Alternative text for error states
    ///   - documentURL: Optional document URL to determine if security scope is needed
    /// - Returns: The load result
    private func loadLocal(url: URL, altText: String, documentURL: URL?) async -> ImageLoadResult {
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

            // Try starting security scope directly on the URL
            if !accessGranted {
                accessGranted = url.startAccessingSecurityScopedResource()
                if accessGranted {
                    resolvedURL = url
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

    // MARK: - Remote Image Loading (NEW)

    /// Loads a remote image from an HTTP/HTTPS URL
    /// - Parameters:
    ///   - url: Remote image URL
    ///   - altText: Alternative text for error states
    ///   - onProgress: Optional progress callback (0.0 to 1.0)
    /// - Returns: The load result
    private func loadRemote(
        url: URL,
        altText: String,
        onProgress: (@Sendable (Double) -> Void)?
    ) async -> ImageLoadResult {
        // Check remote cache first
        if let cached = remoteCache[url] {
            onProgress?(1.0)
            return .success(cached)
        }

        // Check if download is already in progress
        if let existingTask = activeDownloads[url] {
            return await existingTask.value
        }

        // Create new download task
        let downloadTask = Task<ImageLoadResult, Never> { [weak self] in
            guard let self = self else {
                return .missing(altText: altText)
            }

            do {
                // Download with progress tracking
                let (data, response) = try await self.downloadWithProgress(
                    url: url,
                    onProgress: onProgress
                )

                // Validate response
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await self.removeActiveDownload(url: url)
                    return .missing(altText: altText)
                }

                // Validate content type if available
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                   !contentType.hasPrefix("image/") {
                    await self.removeActiveDownload(url: url)
                    return .corrupt(altText: altText)
                }

                // Create image from data
                guard let image = NSImage(data: data), image.isValid else {
                    await self.removeActiveDownload(url: url)
                    return .corrupt(altText: altText)
                }

                // Cache in memory
                await self.addToRemoteCache(url: url, image: image)

                // Remove from active downloads
                await self.removeActiveDownload(url: url)

                // Report completion
                onProgress?(1.0)

                return .success(image)

            } catch {
                await self.removeActiveDownload(url: url)
                return .missing(altText: altText)
            }
        }

        activeDownloads[url] = downloadTask
        return await downloadTask.value
    }

    /// Downloads data from URL with progress tracking
    private func downloadWithProgress(
        url: URL,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws -> (Data, URLResponse) {
        // Use simple data(from:) if no progress tracking needed
        guard onProgress != nil else {
            return try await urlSession.data(from: url)
        }

        // Use bytes(from:) for progress tracking
        let (bytes, response) = try await urlSession.bytes(from: url)

        let expectedLength = response.expectedContentLength
        var data = Data()
        var receivedLength: Int64 = 0

        if expectedLength > 0 {
            data.reserveCapacity(Int(expectedLength))
        }

        for try await byte in bytes {
            data.append(byte)
            receivedLength += 1

            // Report progress periodically (every 1KB or so)
            if receivedLength % 1024 == 0 && expectedLength > 0 {
                let progress = Double(receivedLength) / Double(expectedLength)
                onProgress?(min(progress, 0.99)) // Cap at 99% until fully complete
            }
        }

        return (data, response)
    }

    /// Removes a URL from active downloads
    private func removeActiveDownload(url: URL) {
        activeDownloads.removeValue(forKey: url)
    }

    // MARK: - Legacy Image Loading (kept for backwards compatibility)

    /// Loads an image from a URL with sandbox safety
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - altText: Alternative text for error states
    ///   - documentURL: Optional document URL to determine if security scope is needed
    /// - Returns: The load result
    func loadImage(from url: URL, altText: String, documentURL: URL?) async -> ImageLoadResult {
        return await loadLocal(url: url, altText: altText, documentURL: documentURL)
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

    /// Adds an image to the local cache, evicting old entries if needed
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

    /// Adds an image to the remote cache, evicting old entries if needed
    private func addToRemoteCache(url: URL, image: NSImage) {
        // Simple FIFO eviction when cache is full
        if remoteCache.count >= maxRemoteCacheSize {
            if let firstKey = remoteCache.keys.first {
                remoteCache.removeValue(forKey: firstKey)
            }
        }
        remoteCache[url] = image
    }

    /// Clears the entire local image cache
    func clearCache() {
        cache.removeAll()
    }

    /// Clears the remote image cache
    func clearRemoteCache() {
        remoteCache.removeAll()
    }

    /// Clears all caches (local and remote)
    func clearAllCaches() {
        cache.removeAll()
        remoteCache.removeAll()
    }

    /// Cancels all active downloads
    func cancelAllDownloads() {
        for (_, task) in activeDownloads {
            task.cancel()
        }
        activeDownloads.removeAll()
    }

    /// Removes a specific image from the cache
    func evict(url: URL) {
        cache.removeValue(forKey: url)
        remoteCache.removeValue(forKey: url)
    }

    /// Returns the current local cache size
    var cacheCount: Int {
        cache.count
    }

    /// Returns the current remote cache size
    var remoteCacheCount: Int {
        remoteCache.count
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
