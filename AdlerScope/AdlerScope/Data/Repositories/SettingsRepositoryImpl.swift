import Foundation
import SwiftData

/// Concrete implementation of SettingsRepository using SwiftData
/// Stores settings in SwiftData ModelContainer (singleton pattern)
@MainActor
final class SettingsRepositoryImpl: SettingsRepository {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - SettingsRepository

    func load() async throws -> AppSettings? {
        // Query for singleton settings instance
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.id == singletonID }
        )

        let results = try modelContext.fetch(descriptor)
        return results.first
    }

    func save(_ settings: AppSettings) async throws {
        // Query for existing settings
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.id == singletonID }
        )

        let results = try modelContext.fetch(descriptor)

        if let existing = results.first {
            // Update existing settings in-place
            existing.editor = settings.editor
        } else {
            // Insert new settings with singleton ID
            let newSettings = AppSettings(
                id: AppSettings.singletonID,
                editor: settings.editor ?? .default
            )
            modelContext.insert(newSettings)
        }

        try modelContext.save()
    }

    func resetToDefaults() async throws {
        // Query for existing settings
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.id == singletonID }
        )

        let results = try modelContext.fetch(descriptor)

        if let existing = results.first {
            // Delete existing settings (will be recreated with defaults on next load)
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    func hasSettings() async -> Bool {
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.id == singletonID }
        )

        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
}
