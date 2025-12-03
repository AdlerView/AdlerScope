import Foundation
import SwiftData

/// Top-level application settings aggregator
/// Combines all setting categories into a single cohesive entity
/// Persisted using SwiftData (singleton pattern - only one instance exists)
@Model
final class AppSettings {
    // MARK: - Identity

    /// Unique identifier (always same ID for singleton pattern)
    var id: UUID = AppSettings.singletonID

    // MARK: - Properties

    /// Editor behavior and UI settings
    var editor: EditorSettings?

    // MARK: - Initialization

    init(
        id: UUID = AppSettings.singletonID,
        editor: EditorSettings
    ) {
        self.id = id
        self.editor = editor
    }

    // MARK: - Singleton Pattern

    /// Fixed UUID for singleton settings instance
    static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Defaults

    /// Returns a new AppSettings instance with default values
    /// Note: Returns a new instance each time to avoid shared state issues
    static var `default`: AppSettings {
        AppSettings(editor: .default)
    }

    // MARK: - Validation

    /// Validates all settings categories
    /// - Returns: Validated settings with corrections applied
    nonisolated func validated() -> AppSettings {
        let editorToValidate = editor ?? EditorSettings(openInlineLink: false, debug: false)
        return AppSettings(
            id: id,
            editor: editorToValidate.validated()
        )
    }

    /// Updates settings with validated values in-place
    @MainActor
    func applyValidation() {
        editor = (editor ?? EditorSettings.default).validated()
    }
}
