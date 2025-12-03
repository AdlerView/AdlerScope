//
//  ImageReference.swift
//  AdlerScope
//
//  Data model for image references in markdown documents.
//  Used for tracking images in the sidecar directory.
//

import Foundation

/// Represents an image reference in a markdown document
struct ImageReference: Equatable, Sendable {
    /// The filename in the sidecar directory (e.g., "screenshot.png")
    let filename: String

    /// Alternative text for accessibility
    let altText: String

    /// Resolved URL to the image file (nil if not yet resolved or missing)
    let resolvedURL: URL?

    /// Creates a new image reference
    /// - Parameters:
    ///   - filename: The image filename in the sidecar directory
    ///   - altText: Alternative text for accessibility
    ///   - resolvedURL: Optional resolved file URL
    init(filename: String, altText: String = "", resolvedURL: URL? = nil) {
        self.filename = filename
        self.altText = altText
        self.resolvedURL = resolvedURL
    }

    /// Generates markdown syntax for this image reference
    var markdownSyntax: String {
        "![\(altText)](\(filename))"
    }
}
