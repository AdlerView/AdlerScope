import Foundation

/// Repository protocol for settings persistence
/// Defines contract for loading and saving app settings
/// SwiftData implementation requires @MainActor isolation
@MainActor
protocol SettingsRepository {
    /// Loads settings from persistent storage
    /// - Returns: Loaded settings, or nil if no saved settings exist
    /// - Throws: If loading fails due to I/O or decoding errors
    func load() async throws -> AppSettings?

    /// Saves settings to persistent storage
    /// - Parameter settings: Settings to persist
    /// - Throws: If saving fails due to I/O or encoding errors
    func save(_ settings: AppSettings) async throws

    /// Resets settings to factory defaults
    /// - Throws: If reset operation fails
    func resetToDefaults() async throws

    /// Checks if saved settings exist
    /// - Returns: True if settings file/data exists
    func hasSettings() async -> Bool
}
