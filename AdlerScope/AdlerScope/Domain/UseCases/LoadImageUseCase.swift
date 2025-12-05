#if os(macOS)
//
//  LoadImageUseCase.swift
//  AdlerScope
//
//  Use case for loading images from any source type.
//  Coordinates source resolution with SecureImageLoader.
//

import Foundation
import AppKit

/// Use case for loading images from any source type (local files, sidecar, remote URLs)
actor LoadImageUseCase {

    // MARK: - Dependencies

    private let imageLoader: SecureImageLoader
    private let sourceResolver: ImageSourceResolver

    // MARK: - Initialization

    init(imageLoader: SecureImageLoader) {
        self.imageLoader = imageLoader
        self.sourceResolver = ImageSourceResolver()
    }

    // MARK: - Public Methods

    /// Loads an image from a source string
    /// - Parameters:
    ///   - source: Image source from markdown (path or URL)
    ///   - altText: Alternative text for accessibility and error states
    ///   - documentURL: Optional document URL for relative path resolution
    ///   - sidecarManager: Optional sidecar manager for sidecar image resolution
    ///   - onProgress: Optional progress callback for remote downloads (0.0 to 1.0)
    /// - Returns: ImageLoadResult indicating success or failure
    func execute(
        source: String,
        altText: String,
        documentURL: URL?,
        sidecarManager: SidecarManager?,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async -> ImageLoadResult {
        // Resolve source string to typed ImageSource (must be on MainActor for SidecarManager)
        let imageSource = await MainActor.run {
            sourceResolver.resolve(
                source: source,
                documentURL: documentURL,
                sidecarManager: sidecarManager
            )
        }

        // Delegate to SecureImageLoader
        return await imageLoader.load(
            source: imageSource,
            altText: altText,
            documentURL: documentURL,
            onProgress: onProgress
        )
    }
}

#endif
