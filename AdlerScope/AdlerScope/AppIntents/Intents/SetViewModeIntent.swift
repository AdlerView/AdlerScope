//
//  SetViewModeIntent.swift
//  AdlerScope
//
//  App Intent to change the editor view mode
//  Supports Siri phrases like "Switch to preview mode in AdlerScope"
//

import AppIntents

/// Changes the editor view mode
struct SetViewModeIntent: AppIntent {

    static var title: LocalizedStringResource = "Set View Mode"
    static var description = IntentDescription(
        "Change the editor view mode (Editor, Preview, or Split)",
        categoryName: "View"
    )

    // MARK: - Parameters

    @Parameter(
        title: "View Mode",
        description: "The view mode to switch to"
    )
    var mode: ViewModeEnum

    // MARK: - Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Set view to \(\.$mode)")
    }

    static var openAppWhenRun: Bool { true }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
        NavigationService.shared.requestViewMode(mode.toViewMode)

        let dialog: IntentDialog
        switch mode {
        case .editorOnly:
            dialog = IntentDialog("Switched to editor only view")
        case .previewOnly:
            dialog = IntentDialog("Switched to preview only view")
        case .split:
            dialog = IntentDialog("Switched to split view")
        }

        return .result(dialog: dialog)
    }
}

// MARK: - Intent Donation

extension SetViewModeIntent {
    /// Donate this intent when user changes view mode in the app
    @MainActor
    static func donate(mode: ViewMode) async {
        let intent = SetViewModeIntent()
        intent.mode = ViewModeEnum(from: mode)

        do {
            try await intent.donate()
        } catch {
            print("Failed to donate SetViewModeIntent: \(error)")
        }
    }
}
