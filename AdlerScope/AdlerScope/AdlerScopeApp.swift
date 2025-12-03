//
//  AdlerScopeApp.swift
//  AdlerScope
//
//  Created by adler on 03.11.25.
//
//  DocumentGroup-based document architecture for native macOS document handling
//

import SwiftUI
import SwiftData

@main
struct AdlerScopeApp: App {
    // MARK: - App Delegate Adaptor

    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    // MARK: - SwiftData Model Container (for Settings only)

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AppSettings.self, RecentDocument.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Dependency Injection

    @State private var dependencyContainer = DependencyContainer.shared

    // MARK: - Global View Models (SwiftUI-managed lifecycle)

    /// SettingsViewModel is managed by SwiftUI via @State to ensure stable lifecycle.
    /// This prevents the EXC_BAD_ACCESS crash caused by FocusedValue holding references
    /// to deallocated instances when computed properties create new instances.
    /// Initialized eagerly to avoid showing loading states on document open.
    @State private var settingsViewModel: SettingsViewModel

    // MARK: - Initialization

    init() {
        let modelContext = sharedModelContainer.mainContext
        DependencyContainer.shared.configure(modelContext: modelContext)

        // Initialize SettingsViewModel eagerly - SwiftUI manages its lifecycle via @State
        // This is safe because we're creating a single instance that lives for the app's lifetime
        _settingsViewModel = State(initialValue: DependencyContainer.shared.makeSettingsViewModel())
    }

    // MARK: - App Scenes

    var body: some Scene {
        // DocumentGroup handles: File Open, Save, Autosave, Recent Documents, Undo/Redo
        DocumentGroup(newDocument: MarkdownFileDocument()) { configuration in
            DocumentEditorView(document: configuration.$document)
                .environment(\.dependencyContainer, dependencyContainer)
                .environment(settingsViewModel)
        }
        .commands {
            DocumentGroupCommands()
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif

        // Settings window (macOS only)
        #if os(macOS)
        Settings {
            AdlerScopeSettingsView()
                .environment(settingsViewModel)
                .modelContainer(sharedModelContainer)
        }
        #endif

        // About window (macOS only)
        #if os(macOS)
        Window("About AdlerScope", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        #endif
    }
}

// MARK: - DocumentGroup Commands

/// Simplified commands for DocumentGroup-based app
/// DocumentGroup automatically provides: New, Open, Save, Save As, Close, Recent Documents
struct DocumentGroupCommands: SwiftUI.Commands {
    // MARK: - Focused Values

    @FocusedValue(\.showEditor) var showEditor: (() -> Void)?
    @FocusedValue(\.showPreview) var showPreview: (() -> Void)?
    @FocusedValue(\.showSplitView) var showSplitView: (() -> Void)?
    @FocusedValue(\.swapPanes) var swapPanes: (() -> Void)?
    @FocusedValue(\.zoomIn) var zoomIn: (() -> Void)?
    @FocusedValue(\.zoomOut) var zoomOut: (() -> Void)?
    @FocusedValue(\.resetZoom) var resetZoom: (() -> Void)?

    // Import actions
    @FocusedValue(\.importFromPhotos) var importFromPhotos: (() -> Void)?

    // Format actions
    @FocusedValue(\.toggleBold) var toggleBold: (() -> Void)?
    @FocusedValue(\.toggleItalic) var toggleItalic: (() -> Void)?
    @FocusedValue(\.toggleStrikethrough) var toggleStrikethrough: (() -> Void)?
    @FocusedValue(\.toggleInlineCode) var toggleInlineCode: (() -> Void)?
    @FocusedValue(\.makeHeading1) var makeHeading1: (() -> Void)?
    @FocusedValue(\.makeHeading2) var makeHeading2: (() -> Void)?
    @FocusedValue(\.makeHeading3) var makeHeading3: (() -> Void)?
    @FocusedValue(\.makeBulletList) var makeBulletList: (() -> Void)?
    @FocusedValue(\.makeNumberedList) var makeNumberedList: (() -> Void)?
    @FocusedValue(\.makeBlockquote) var makeBlockquote: (() -> Void)?
    @FocusedValue(\.makeCodeBlock) var makeCodeBlock: (() -> Void)?

    @Environment(\.openWindow) var openWindow
    @Environment(\.openURL) var openURL

    var body: some SwiftUI.Commands {
        // Standard text editing commands
        TextEditingCommands()

        // File menu - Import
        CommandGroup(after: .importExport) {
            Button("Import from Photos...") { importFromPhotos?() }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(importFromPhotos == nil)
        }

        // Format menu
        CommandGroup(after: .textFormatting) {
            Menu("Emphasis") {
                Button("Bold") { toggleBold?() }
                    .keyboardShortcut("b", modifiers: .command)
                    .disabled(toggleBold == nil)

                Button("Italic") { toggleItalic?() }
                    .keyboardShortcut("i", modifiers: .command)
                    .disabled(toggleItalic == nil)

                Button("Strikethrough") { toggleStrikethrough?() }
                    .keyboardShortcut("x", modifiers: [.command, .shift])
                    .disabled(toggleStrikethrough == nil)

                Button("Inline Code") { toggleInlineCode?() }
                    .keyboardShortcut("`", modifiers: .command)
                    .disabled(toggleInlineCode == nil)
            }

            Divider()

            Menu("Headings") {
                Button("Heading 1") { makeHeading1?() }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                    .disabled(makeHeading1 == nil)

                Button("Heading 2") { makeHeading2?() }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                    .disabled(makeHeading2 == nil)

                Button("Heading 3") { makeHeading3?() }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                    .disabled(makeHeading3 == nil)
            }

            Divider()

            Menu("Lists") {
                Button("Bullet List") { makeBulletList?() }
                    .keyboardShortcut("8", modifiers: [.command, .shift])
                    .disabled(makeBulletList == nil)

                Button("Numbered List") { makeNumberedList?() }
                    .keyboardShortcut("7", modifiers: [.command, .shift])
                    .disabled(makeNumberedList == nil)
            }

            Divider()

            Button("Blockquote") { makeBlockquote?() }
                .keyboardShortcut("'", modifiers: [.command, .shift])
                .disabled(makeBlockquote == nil)

            Button("Code Block") { makeCodeBlock?() }
                .keyboardShortcut("`", modifiers: [.command, .shift])
                .disabled(makeCodeBlock == nil)
        }

        // Sidebar and toolbar
        SidebarCommands()
        ToolbarCommands()

        // View menu
        CommandGroup(after: .toolbar) {
            Menu("View Mode") {
                Button("Editor Only") { showEditor?() }
                    .keyboardShortcut("1", modifiers: .command)
                    .disabled(showEditor == nil)

                Button("Preview Only") { showPreview?() }
                    .keyboardShortcut("2", modifiers: .command)
                    .disabled(showPreview == nil)

                Button("Split View") { showSplitView?() }
                    .keyboardShortcut("3", modifiers: .command)
                    .disabled(showSplitView == nil)

                Divider()

                Button("Swap Panes") { swapPanes?() }
                    .keyboardShortcut("s", modifiers: [.command, .option])
                    .disabled(swapPanes == nil)
            }

            Divider()

            Button("Zoom In") { zoomIn?() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(zoomIn == nil)

            Button("Zoom Out") { zoomOut?() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(zoomOut == nil)

            Button("Actual Size") { resetZoom?() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(resetZoom == nil)
        }

        // About and Help
        CommandGroup(replacing: .appInfo) {
            Button("About AdlerScope") {
                openWindow(id: "about")
            }
        }

        CommandGroup(replacing: .help) {
            Button("AdlerScope Help") {
                if let url = URL(string: "https://github.com/adlerflow/AdlerScope") {
                    openURL(url)
                }
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}

