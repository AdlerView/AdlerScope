//
//  RenderingManager.swift
//  AdlerScope
//
//  Core rendering logic for markdown content
//  Handles debouncing, parsing, and render coordination
//

import SwiftUI
import Observation
import Markdown
import OSLog

private let logger = Logger(subsystem: "org.advision.AdlerScope", category: "RenderingManager")

/// Manages markdown rendering with debouncing and caching
@Observable
final class RenderingManager {
    // MARK: - State

    /// Rendered markdown document (parsed AST)
    var renderedDocument: Document?

    /// Whether rendering is in progress
    var isRendering = false

    /// Force refresh trigger
    var refreshTrigger: UUID = UUID()

    // MARK: - Dependencies

    private let parseMarkdownUseCase: ParseMarkdownUseCase
    private let settingsViewModel: SettingsViewModel

    // MARK: - Private Properties

    private var debounceTask: Task<Void, Never>?
    private let debounceDelay: Duration = .milliseconds(500)

    // MARK: - Initialization

    init(
        parseMarkdownUseCase: ParseMarkdownUseCase,
        settingsViewModel: SettingsViewModel
    ) {
        self.parseMarkdownUseCase = parseMarkdownUseCase
        self.settingsViewModel = settingsViewModel
    }

    // MARK: - Rendering

    /// Renders markdown content with debouncing (always enabled)
    /// - Parameter content: Raw markdown string
    func debounceRender(content: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: debounceDelay)
            if !Task.isCancelled {
                await render(content: content)
            }
        }
    }

    /// Renders markdown content immediately (no debouncing)
    /// - Parameter content: Raw markdown string
    func render(content: String) async {
        #if DEBUG
        // Debug logging only when debug mode is enabled
        if settingsViewModel.settings.editor?.debug == true {
            logger.debug("Rendering markdown (\(content.count) characters)")
        }
        #endif

        isRendering = true

        defer { isRendering = false }

        do {
            let document = try await parseMarkdownUseCase.execute(
                markdown: content
            )
            renderedDocument = document

            // Info logging only when debug mode is enabled
            if settingsViewModel.settings.editor?.debug == true {
                logger.info("Render completed successfully")
            }

        } catch {
            // Error logs always show (critical information)
            logger.error("Parse error: \(error.localizedDescription)")
            renderedDocument = nil
        }
    }

    /// Forces immediate render (cancels debounce)
    /// - Parameter content: Raw markdown string
    func forceRender(content: String) {
        debounceTask?.cancel()
        refreshTrigger = UUID()

        Task { @MainActor in
            await render(content: content)
        }
    }

    /// Triggers manual refresh
    func refreshPreview(content: String) {
        forceRender(content: content)
    }

    /// Cancels any pending render operation
    func cancelPendingRender() {
        debounceTask?.cancel()
    }

    // MARK: - Cleanup

    deinit {
        debounceTask?.cancel()
    }
}
