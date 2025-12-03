//
//  AlertError.swift
//  AdlerScope
//
//  User-facing error presentation model
//  Works with SwiftUI Alert modifier using Identifiable
//

import Foundation
import SwiftUI

/// Error model for presenting user-facing alerts
struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?

    init(title: String, message: String, recoverySuggestion: String? = nil) {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }

    /// Create AlertError from LocalizedError
    init(from error: LocalizedError) {
        self.init(
            title: error.errorDescription ?? "Error",
            message: error.failureReason ?? error.localizedDescription,
            recoverySuggestion: error.recoverySuggestion
        )
    }

    /// Create AlertError from DocumentLoadError
    init(from error: DocumentLoadError) {
        self.init(
            title: error.errorDescription ?? "Error",
            message: error.failureReason ?? "",
            recoverySuggestion: error.recoverySuggestion
        )
    }

    /// Create AlertError from generic Error
    init(from error: Error) {
        if let localizedError = error as? LocalizedError {
            self.init(from: localizedError)
        } else {
            self.init(
                title: "Error",
                message: error.localizedDescription,
                recoverySuggestion: nil
            )
        }
    }
}

// MARK: - Common Errors

extension AlertError {

    static func fileNotFound(_ filename: String) -> AlertError {
        AlertError(
            title: "File Not Found",
            message: "The file \"\(filename)\" could not be found.",
            recoverySuggestion: "The file may have been moved or deleted. Remove it from recents and try opening it again."
        )
    }

    static func accessDenied(_ filename: String) -> AlertError {
        AlertError(
            title: "Access Denied",
            message: "You don't have permission to access \"\(filename)\".",
            recoverySuggestion: "Check the file permissions and ensure you have read access."
        )
    }

    static func saveFailed(_ filename: String, reason: String? = nil) -> AlertError {
        let message = reason != nil
            ? "Failed to save \"\(filename)\": \(reason!)"
            : "Failed to save \"\(filename)\"."

        return AlertError(
            title: "Save Failed",
            message: message,
            recoverySuggestion: "Try saving to a different location or check available disk space."
        )
    }

    static func encodingError() -> AlertError {
        AlertError(
            title: "Encoding Error",
            message: "The file contains characters that cannot be read as UTF-8 text.",
            recoverySuggestion: "The file may be corrupted or use a different text encoding."
        )
    }

    static func databaseError(_ operation: String) -> AlertError {
        AlertError(
            title: "Database Error",
            message: "Failed to \(operation).",
            recoverySuggestion: "Please try again. If the problem persists, restart the application."
        )
    }
}

// MARK: - View Extension

extension View {
    /// Present an alert for AlertError
    func alert(error: Binding<AlertError?>) -> some View {
        alert(item: error) { error in
            if let suggestion = error.recoverySuggestion {
                Alert(
                    title: Text(error.title),
                    message: Text("\(error.message)\n\n\(suggestion)"),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    /// Present a dismissible alert with custom actions
    func alert(
        error: Binding<AlertError?>,
        primaryAction: @escaping () -> Void,
        primaryLabel: String = "Retry"
    ) -> some View {
        alert(item: error) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                primaryButton: .default(Text(primaryLabel)) {
                    primaryAction()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
