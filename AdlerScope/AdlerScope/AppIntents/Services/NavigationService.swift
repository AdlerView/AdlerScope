//
//  NavigationService.swift
//  AdlerScope
//
//  Mediator service between App Intents and SwiftUI views
//  App Intents modify this service; Views observe and react to changes
//

import Foundation
import Observation

/// Navigation actions that can be triggered by App Intents
enum NavigationAction: Equatable {
    case openDocument(url: URL)
    case openDocumentByID(id: UUID)
    case createNewDocument(initialContent: String?)
    case setViewMode(ViewMode)
    case showSearch(query: String?)
    case none
}

/// Singleton service mediating between AppIntents and SwiftUI views
/// AppIntents modify this service; Views observe and react to changes
@Observable
@MainActor
final class NavigationService {
    // MARK: - Singleton

    static let shared = NavigationService()

    private init() {}

    // MARK: - Navigation State

    /// The pending navigation action (consumed by views)
    var pendingAction: NavigationAction = .none

    /// Timestamp of last action (for deduplication)
    private var lastActionTimestamp: Date = .distantPast

    // MARK: - Intent Actions

    /// Request to open a document by URL
    func requestOpenDocument(url: URL) {
        pendingAction = .openDocument(url: url)
        lastActionTimestamp = Date()
    }

    /// Request to open a document by UUID
    func requestOpenDocument(id: UUID) {
        pendingAction = .openDocumentByID(id: id)
        lastActionTimestamp = Date()
    }

    /// Request to create a new document
    func requestNewDocument(initialContent: String? = nil) {
        pendingAction = .createNewDocument(initialContent: initialContent)
        lastActionTimestamp = Date()
    }

    /// Request view mode change
    func requestViewMode(_ mode: ViewMode) {
        pendingAction = .setViewMode(mode)
        lastActionTimestamp = Date()
    }

    /// Request to show search with optional query
    func requestSearch(query: String? = nil) {
        pendingAction = .showSearch(query: query)
        lastActionTimestamp = Date()
    }

    /// Clear the pending action (called by view after handling)
    func clearPendingAction() {
        pendingAction = .none
    }
}
