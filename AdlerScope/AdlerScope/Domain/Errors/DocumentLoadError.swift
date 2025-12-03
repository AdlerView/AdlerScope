//
//  DocumentLoadError.swift
//  AdlerScope
//
//  Errors that can occur during document loading and saving
//

import Foundation

enum DocumentLoadError: Error, LocalizedError {
    case fileNotAccessible(URL)
    case encodingFailed
    case bookmarkResolutionFailed
    case saveFailed(Error)
    case documentNotFound
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotAccessible(let url):
            return "Cannot access file at \(url.lastPathComponent)"
        case .encodingFailed:
            return "Failed to encode file content as UTF-8"
        case .bookmarkResolutionFailed:
            return "Security-scoped bookmark resolution failed"
        case .saveFailed:
            return "Failed to save document"
        case .documentNotFound:
            return "Document not found"
        case .unknown:
            return "An unexpected error occurred"
        }
    }

    var failureReason: String? {
        switch self {
        case .fileNotAccessible(let url):
            return "The file at \(url.path) could not be accessed. It may have been moved or deleted."
        case .encodingFailed:
            return "The file contains characters that cannot be read as UTF-8 text."
        case .bookmarkResolutionFailed:
            return "The security bookmark for this file is no longer valid."
        case .saveFailed(let error):
            return "Save operation failed: \(error.localizedDescription)"
        case .documentNotFound:
            return "The document could not be found in the database."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotAccessible:
            return "Check if the file exists and you have permission to access it."
        case .encodingFailed:
            return "The file may contain non-UTF-8 characters. Try opening it with a different editor."
        case .bookmarkResolutionFailed:
            return "Remove the document from recents and open it again."
        case .saveFailed:
            return "Try saving to a different location or check available disk space."
        case .documentNotFound:
            return "The document may have been removed. Try opening the file again."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}
