//
//  ImageSource.swift
//  AdlerScope
//
//  Represents different types of image sources in markdown documents.
//  Used for type-safe handling of absolute paths, relative paths,
//  sidecar images, and remote URLs.
//

import Foundation

/// Represents a resolved image source with type information
enum ImageSource: Sendable, Equatable {
    /// Absolute file path (e.g., /Users/home/Documents/image.png)
    case absolute(URL)

    /// Path relative to the document (e.g., ./images/photo.png, ../shared/image.png)
    case documentRelative(URL)

    /// Sidecar image (e.g., photo.png in MyNote.assets/)
    case sidecar(filename: String, resolvedURL: URL?)

    /// Remote HTTP/HTTPS URL
    case remote(URL)

    // MARK: - Computed Properties

    /// Human-readable display path for error messages
    var displayPath: String {
        switch self {
        case .absolute(let url):
            return url.path
        case .documentRelative(let url):
            return url.path
        case .sidecar(let filename, _):
            return filename
        case .remote(let url):
            return url.absoluteString
        }
    }

    /// Whether this source type requires security-scoped access
    var requiresSecurityScope: Bool {
        switch self {
        case .absolute, .documentRelative:
            return true
        case .sidecar, .remote:
            return false
        }
    }

    /// Whether this is a remote (HTTP/HTTPS) source
    var isRemote: Bool {
        if case .remote = self {
            return true
        }
        return false
    }

    /// The resolved URL if available
    var resolvedURL: URL? {
        switch self {
        case .absolute(let url), .documentRelative(let url), .remote(let url):
            return url
        case .sidecar(_, let url):
            return url
        }
    }
}
