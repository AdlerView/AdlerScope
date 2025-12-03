//
//  SplitEditorViewModel.swift
//  AdlerScope
//
//  ViewModel for SplitEditorView
//  Refactored to use composition pattern with MenuBar business logic
//

import SwiftUI
import Observation
import Markdown

/// ViewModel for split editor view (Editor | Preview) coordination
/// Composes business logic from MenuBar modules
@Observable
final class SplitEditorViewModel {
    // MARK: - Composed Managers

    /// Core rendering logic
    private let renderingManager: RenderingManager

    /// View menu actions (public for focused values)
    let viewActions: ViewMenuActions

    /// Format menu actions (public for focused values)
    let formatActions: FormatMenuActions

    /// Edit menu actions (public for focused values)
    let editActions: EditMenuActions

    // MARK: - State (Delegated to Managers)

    /// Rendered markdown document (from RenderingManager)
    var renderedDocument: Document? {
        renderingManager.renderedDocument
    }

    /// Force refresh trigger (from RenderingManager)
    var refreshTrigger: UUID {
        renderingManager.refreshTrigger
    }

    /// Whether rendering is in progress (from RenderingManager)
    var isRendering: Bool {
        renderingManager.isRendering
    }

    /// Current view mode (from ViewMenuActions)
    var viewMode: ViewMode {
        viewActions.viewMode
    }

    /// Whether panes are swapped (from ViewMenuActions)
    var swapPanes: Bool {
        viewActions.swapPanes
    }

    /// Current zoom level (from ViewMenuActions)
    var zoomLevel: CGFloat {
        viewActions.zoomLevel
    }

    // MARK: - Initialization

    init(
        parseMarkdownUseCase: ParseMarkdownUseCase,
        settingsViewModel: SettingsViewModel
    ) {
        self.renderingManager = RenderingManager(
            parseMarkdownUseCase: parseMarkdownUseCase,
            settingsViewModel: settingsViewModel
        )
        self.viewActions = ViewMenuActions()
        self.formatActions = FormatMenuActions()
        self.editActions = EditMenuActions()
    }

    // MARK: - Rendering (Delegate to RenderingManager)

    /// Renders markdown content with debouncing
    func debounceRender(content: String) {
        renderingManager.debounceRender(content: content)
    }

    /// Renders markdown content immediately
    func render(content: String) async {
        await renderingManager.render(content: content)
    }

    /// Forces immediate render (cancels debounce)
    func forceRender(content: String) {
        renderingManager.forceRender(content: content)
    }

    /// Triggers manual refresh
    func refreshPreview(content: String) {
        renderingManager.refreshPreview(content: content)
    }

    /// Cancels pending render
    func cancelPendingRender() {
        renderingManager.cancelPendingRender()
    }

    // MARK: - View Mode Switching (Delegate to ViewMenuActions)

    /// Sets view mode to editor only
    func showEditorOnly() {
        viewActions.showEditorOnly()
    }

    /// Sets view mode to preview only
    func showPreviewOnly() {
        viewActions.showPreviewOnly()
    }

    /// Sets view mode to split view
    func showSplitView() {
        viewActions.showSplitView()
    }

    /// Toggles pane order in split view
    func toggleSwapPanes() {
        viewActions.toggleSwapPanes()
    }

    // MARK: - Zoom Controls (Delegate to ViewMenuActions)

    /// Increases zoom level
    func zoomIn() {
        viewActions.zoomIn()
    }

    /// Decreases zoom level
    func zoomOut() {
        viewActions.zoomOut()
    }

    /// Resets zoom to 100%
    func resetZoom() {
        viewActions.resetZoom()
    }
}
