//
//  ViewModeEnum.swift
//  AdlerScope
//
//  AppEnum wrapper for ViewMode
//  Exposes view mode options to Siri and Shortcuts
//

import AppIntents

/// AppEnum wrapper for ViewMode
enum ViewModeEnum: String, AppEnum {
    case editorOnly = "editor"
    case previewOnly = "preview"
    case split = "split"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "View Mode")
    }

    static var caseDisplayRepresentations: [ViewModeEnum: DisplayRepresentation] {
        [
            .editorOnly: DisplayRepresentation(
                title: "Editor Only",
                subtitle: "Show only the markdown editor",
                image: .init(systemName: "doc.text")
            ),
            .previewOnly: DisplayRepresentation(
                title: "Preview Only",
                subtitle: "Show only the rendered preview",
                image: .init(systemName: "eye")
            ),
            .split: DisplayRepresentation(
                title: "Split View",
                subtitle: "Show editor and preview side by side",
                image: .init(systemName: "rectangle.split.2x1")
            )
        ]
    }

    /// Convert to domain ViewMode
    var toViewMode: ViewMode {
        switch self {
        case .editorOnly: return .editorOnly
        case .previewOnly: return .previewOnly
        case .split: return .split
        }
    }

    /// Create from domain ViewMode
    init(from viewMode: ViewMode) {
        switch viewMode {
        case .editorOnly: self = .editorOnly
        case .previewOnly: self = .previewOnly
        case .split: self = .split
        }
    }
}
