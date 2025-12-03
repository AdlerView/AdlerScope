import Foundation

/// Editor behavior and UI settings
/// Thread-safe value type for concurrent access
struct EditorSettings: Sendable, Equatable {
    // MARK: - Properties

    /// Open inline links in external browser
    var openInlineLink: Bool

    /// Enable debug mode for diagnostics
    var debug: Bool

    // MARK: - Defaults

    static let `default` = EditorSettings(
        openInlineLink: false,
        debug: false
    )

    // MARK: - Validation

    /// Validates editor settings
    /// - Returns: Validated settings with corrections applied
    nonisolated func validated() -> EditorSettings {
        // All current settings are valid (simple booleans)
        // Could add validation rules in future (e.g., performance constraints)
        return self
    }
}

// MARK: - Codable Conformance

extension EditorSettings: Codable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(openInlineLink, forKey: .openInlineLink)
        try container.encode(debug, forKey: .debug)
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.openInlineLink = try container.decode(Bool.self, forKey: .openInlineLink)
        self.debug = try container.decode(Bool.self, forKey: .debug)
    }

    enum CodingKeys: String, CodingKey {
        case openInlineLink
        case debug
    }
}
