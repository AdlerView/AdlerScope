import Foundation
import OSLog

/// Use case for loading app settings from persistent storage
/// Thread-safe actor that handles settings loading with validation
actor LoadSettingsUseCase {
    // MARK: - Dependencies

    private let settingsRepository: SettingsRepository

    // MARK: - Initialization

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    // MARK: - Business Logic

    /// Loads settings from storage with validation
    /// Returns default settings if none exist or loading fails
    /// - Returns: Validated settings (either loaded or default)
    func execute() async -> AppSettings {
        do {
            // Try to load saved settings
            guard let loadedSettings = try await settingsRepository.load() else {
                await os_log("No saved settings found, using defaults", log: .settings, type: .info)
                return .default
            }

            // Validate loaded settings
            let validatedSettings = loadedSettings.validated()

            // Log if validation changed anything (note: AppSettings is now a class, so identity comparison)
            #if DEBUG
            await os_log("Settings loaded successfully", log: .settings, type: .debug)
            #endif

            return validatedSettings
        } catch {
            await os_log("Failed to load settings: %{public}@", log: .settings, type: .error, String(describing: error))
            await os_log("Using default settings", log: .settings, type: .info)
            return .default
        }
    }

    /// Checks if saved settings exist
    /// - Returns: True if settings file exists
    func hasSettings() async -> Bool {
        await settingsRepository.hasSettings()
    }
}

