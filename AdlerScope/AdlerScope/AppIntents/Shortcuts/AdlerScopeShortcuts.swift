//
//  AdlerScopeShortcuts.swift
//  AdlerScope
//
//  AppShortcutsProvider for AdlerScope
//  Defines discoverable shortcuts with Siri phrases
//

import AppIntents

/// Provides discoverable Shortcuts for AdlerScope
struct AdlerScopeShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {

        // MARK: - Open Document Shortcut

        AppShortcut(
            intent: OpenDocumentIntent(),
            phrases: [
                "Open \(\.$document) in \(.applicationName)",
                "Open my document \(\.$document) with \(.applicationName)",
                "Edit \(\.$document) in \(.applicationName)"
            ],
            shortTitle: "Open Document",
            systemImageName: "doc.text"
        )

        // MARK: - Create New Document Shortcut

        AppShortcut(
            intent: CreateNewDocumentIntent(),
            phrases: [
                "Create a new document in \(.applicationName)",
                "New markdown file in \(.applicationName)",
                "Start a new note in \(.applicationName)"
            ],
            shortTitle: "New Document",
            systemImageName: "doc.badge.plus"
        )

        // MARK: - Search Documents Shortcut
        // Note: String parameters cannot be interpolated in phrases

        AppShortcut(
            intent: SearchDocumentsIntent(),
            phrases: [
                "Search documents in \(.applicationName)",
                "Find documents in \(.applicationName)",
                "Search in \(.applicationName)"
            ],
            shortTitle: "Search Documents",
            systemImageName: "magnifyingglass"
        )

        // MARK: - Get Recent Documents Shortcut

        AppShortcut(
            intent: GetRecentDocumentsIntent(),
            phrases: [
                "Show my recent documents in \(.applicationName)",
                "What have I been working on in \(.applicationName)",
                "List recent \(.applicationName) files"
            ],
            shortTitle: "Recent Documents",
            systemImageName: "clock"
        )

        // MARK: - Set View Mode Shortcut

        AppShortcut(
            intent: SetViewModeIntent(),
            phrases: [
                "Switch to \(\.$mode) view in \(.applicationName)",
                "Show \(\.$mode) mode in \(.applicationName)",
                "Change \(.applicationName) to \(\.$mode) view"
            ],
            shortTitle: "Set View Mode",
            systemImageName: "rectangle.split.2x1"
        )
    }
}
