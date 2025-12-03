//
//  SidecarError.swift
//  AdlerScope
//
//  Error types for sidecar directory operations.
//

import Foundation

/// Errors that can occur during sidecar operations
enum SidecarError: LocalizedError {
    /// No sidecar directory has been configured
    case noSidecarConfigured

    /// The specified image was not found in the sidecar
    case imageNotFound(String)

    /// Failed to copy an image to the sidecar
    case copyFailed(String, underlying: Error?)

    /// Failed to create the sidecar directory
    case directoryCreationFailed(underlying: Error)

    /// The source file is not a valid image
    case invalidImageFormat(String)

    var errorDescription: String? {
        switch self {
        case .noSidecarConfigured:
            return "No sidecar directory configured. Save the document first."
        case .imageNotFound(let filename):
            return "Image not found: \(filename)"
        case .copyFailed(let filename, let underlying):
            if let error = underlying {
                return "Failed to copy image '\(filename)': \(error.localizedDescription)"
            }
            return "Failed to copy image: \(filename)"
        case .directoryCreationFailed(let underlying):
            return "Failed to create sidecar directory: \(underlying.localizedDescription)"
        case .invalidImageFormat(let filename):
            return "Invalid image format: \(filename)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noSidecarConfigured:
            return "Save the document to enable image insertion."
        case .imageNotFound:
            return "Check if the image file exists in the assets folder."
        case .copyFailed:
            return "Try copying the image again or check file permissions."
        case .directoryCreationFailed:
            return "Check write permissions for the document folder."
        case .invalidImageFormat:
            return "Use a supported image format (PNG, JPEG, GIF, TIFF, WebP)."
        }
    }
}
