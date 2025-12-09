//
//  ViewMenuActions.swift
//  AdlerScope
//
//  View menu business logic:
//  - View mode switching (Editor Only, Preview Only, Split View)
//  - Pane swapping
//  - Document structure and word count panels
//  - Line numbers and invisibles visibility
//  - Typewriter and focus modes
//  - Preview themes
//  - Zoom controls (Zoom In, Zoom Out, Actual Size)
//

#if os(macOS)
import SwiftUI
import Observation
#else
import SwiftUI
import Observation
#endif

/// View mode options for the markdown editor
enum ViewMode: String, Codable, CaseIterable {
    case editorOnly
    case previewOnly
    case split
}

/// Preview theme options
enum PreviewTheme: String, Codable, CaseIterable {
    case `default` = "default"
    case github = "github"
    case academic = "academic"
    case minimal = "minimal"
}

/// Handles all View menu actions
@Observable
final class ViewMenuActions {
    // MARK: - View Mode State

    /// Current view mode (editor only, preview only, or split)
    var viewMode: ViewMode = .split

    /// Whether panes are swapped in split view (editor on right, preview on left)
    var swapPanes = false

    // MARK: - Panel Visibility State

    /// Whether document structure panel is visible
    var showDocumentStructure = false

    /// Whether word count is visible
    var showWordCount = false

    /// Whether line numbers are shown in editor
    var showLineNumbers = true

    /// Whether invisible characters are shown
    var showInvisibles = false

    // MARK: - Editor Mode State

    /// Whether typewriter mode is enabled (keeps cursor centered)
    var typewriterMode = false

    /// Whether focus mode is enabled (dims non-current paragraph)
    var focusMode = false

    // MARK: - Preview Theme State

    /// Current preview theme
    var previewTheme: PreviewTheme = .default

    // MARK: - Zoom Manager

    #if os(macOS)
    /// Zoom manager for trackpad gestures and font scaling
    let zoomManager = ZoomManager()
    #endif

    // MARK: - View Mode Switching

    /// Sets view mode to editor only
    func showEditorOnly() {
        viewMode = .editorOnly
        donateViewModeIntent(.editorOnly)
    }

    /// Sets view mode to preview only
    func showPreviewOnly() {
        viewMode = .previewOnly
        donateViewModeIntent(.previewOnly)
    }

    /// Sets view mode to split view
    func showSplitView() {
        viewMode = .split
        donateViewModeIntent(.split)
    }

    /// Donate view mode intent for Siri suggestions
    private func donateViewModeIntent(_ mode: ViewMode) {
        Task {
            await SetViewModeIntent.donate(mode: mode)
        }
    }

    /// Toggles pane order in split view
    func toggleSwapPanes() {
        swapPanes.toggle()
    }

    // MARK: - Panel Toggles

    /// Toggles document structure panel visibility
    func toggleDocumentStructure() {
        showDocumentStructure.toggle()
    }

    /// Toggles word count visibility
    func toggleWordCount() {
        showWordCount.toggle()
    }

    /// Toggles line numbers visibility
    func toggleLineNumbers() {
        showLineNumbers.toggle()
    }

    /// Toggles invisible characters visibility
    func toggleInvisibles() {
        showInvisibles.toggle()
    }

    // MARK: - Editor Modes

    /// Toggles typewriter mode (cursor stays centered vertically)
    func toggleTypewriterMode() {
        typewriterMode.toggle()
    }

    /// Toggles focus mode (dims paragraphs except current)
    func toggleFocusMode() {
        focusMode.toggle()
    }

    // MARK: - Preview Theme

    /// Sets preview theme to default
    func setPreviewThemeDefault() {
        previewTheme = .default
    }

    /// Sets preview theme to GitHub style
    func setPreviewThemeGitHub() {
        previewTheme = .github
    }

    /// Sets preview theme to Academic style
    func setPreviewThemeAcademic() {
        previewTheme = .academic
    }

    /// Sets preview theme to Minimal style
    func setPreviewThemeMinimal() {
        previewTheme = .minimal
    }

    // MARK: - Zoom Controls

    #if os(macOS)
    /// Increases zoom level by 10% (max 300%)
    func zoomIn() {
        zoomManager.zoomIn()
    }

    /// Decreases zoom level by 10% (min 50%)
    func zoomOut() {
        zoomManager.zoomOut()
    }

    /// Resets zoom to 100% (actual size)
    func resetZoom() {
        zoomManager.resetZoom()
    }

    // MARK: - Computed Properties

    /// Human-readable zoom percentage
    var zoomPercentage: Int {
        zoomManager.zoomPercentage
    }

    /// Current zoom level (for external access)
    /// Returns visualZoomLevel for smooth preview updates during gestures
    var zoomLevel: CGFloat {
        zoomManager.visualZoomLevel
    }
    #else
    /// Increases zoom level by 10% (max 300%)
    func zoomIn() {
        // iOS placeholder
    }

    /// Decreases zoom level by 10% (min 50%)
    func zoomOut() {
        // iOS placeholder
    }

    /// Resets zoom to 100% (actual size)
    func resetZoom() {
        // iOS placeholder
    }

    /// Human-readable zoom percentage
    var zoomPercentage: Int {
        100
    }

    /// Current zoom level (for external access)
    var zoomLevel: CGFloat {
        1.0
    }
    #endif
}
