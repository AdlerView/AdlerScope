//
//  SettingsRepositoryImplTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for SettingsRepositoryImpl functionality
//

import Testing
import Foundation
import SwiftData
@testable import AdlerScope

@Suite("SettingsRepositoryImpl Tests")
@MainActor
struct SettingsRepositoryImplTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Load returns nil when no settings exist")
    func testLoadNoSettings() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let settings = try await repository.load()

        #expect(settings == nil)
    }

    @Test("Save creates new settings when none exist")
    func testSaveCreatesNewSettings() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )

        try await repository.save(settings)

        let loaded = try await repository.load()
        #expect(loaded != nil)
        #expect(loaded?.editor?.openInlineLink == true)
        #expect(loaded?.editor?.debug == false)
    }

    @Test("Save updates existing settings")
    func testSaveUpdatesExistingSettings() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // Save initial settings
        let settings1 = AppSettings(
            editor: EditorSettings(
                openInlineLink: false,
                debug: false
            )
        )
        try await repository.save(settings1)

        // Save updated settings
        let settings2 = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: true
            )
        )
        try await repository.save(settings2)

        // Load and verify
        let loaded = try await repository.load()
        #expect(loaded?.editor?.openInlineLink == true)
        #expect(loaded?.editor?.debug == true)
    }

    @Test("Save preserves singleton ID")
    func testSavePreservesSingletonID() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let settings = AppSettings.default
        try await repository.save(settings)

        let loaded = try await repository.load()
        #expect(loaded?.id == AppSettings.singletonID)
    }

    @Test("hasSettings returns false when no settings exist")
    func testHasSettingsReturnsFalse() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let hasSettings = await repository.hasSettings()

        #expect(hasSettings == false)
    }

    @Test("hasSettings returns true after save")
    func testHasSettingsReturnsTrue() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        try await repository.save(AppSettings.default)

        let hasSettings = await repository.hasSettings()

        #expect(hasSettings == true)
    }

    @Test("resetToDefaults deletes existing settings")
    func testResetToDefaults() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // Save settings
        try await repository.save(AppSettings.default)
        #expect(await repository.hasSettings() == true)

        // Reset
        try await repository.resetToDefaults()

        // Verify settings are gone
        #expect(await repository.hasSettings() == false)
        let loaded = try await repository.load()
        #expect(loaded == nil)
    }

    @Test("resetToDefaults on empty repository doesn't throw")
    func testResetToDefaultsEmpty() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // Should not throw even if no settings exist
        try await repository.resetToDefaults()

        #expect(await repository.hasSettings() == false)
    }
}

@Suite("SettingsRepositoryImpl Integration Tests")
@MainActor
struct SettingsRepositoryImplIntegrationTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Complete workflow: save, load, update, reset")
    func testCompleteWorkflow() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // 1. Verify no settings initially
        #expect(await repository.hasSettings() == false)

        // 2. Save settings
        let settings1 = AppSettings(
            editor: EditorSettings(openInlineLink: false, debug: false)
        )
        try await repository.save(settings1)
        #expect(await repository.hasSettings() == true)

        // 3. Load settings
        let loaded1 = try await repository.load()
        #expect(loaded1?.editor?.openInlineLink == false)

        // 4. Update settings
        let settings2 = AppSettings(
            editor: EditorSettings(openInlineLink: true, debug: true)
        )
        try await repository.save(settings2)

        // 5. Load updated settings
        let loaded2 = try await repository.load()
        #expect(loaded2?.editor?.openInlineLink == true)

        // 6. Reset to defaults
        try await repository.resetToDefaults()
        #expect(await repository.hasSettings() == false)
    }

    @Test("Multiple save operations maintain singleton pattern")
    func testMultipleSavesSingletonPattern() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // Save multiple times with different values
        for i in 0..<5 {
            let settings = AppSettings(
                editor: EditorSettings(openInlineLink: i % 2 == 0, debug: i % 2 == 1)
            )
            try await repository.save(settings)
        }

        // Should only have one settings instance
        let descriptor = FetchDescriptor<AppSettings>()
        let allSettings = try context.fetch(descriptor)
        #expect(allSettings.count == 1)

        // Last save should be persisted
        let loaded = try await repository.load()
        #expect(loaded?.editor?.openInlineLink == true) // i=4, 4%2==0 is true
        #expect(loaded?.editor?.debug == false) // i=4, 4%2==1 is false
    }

    @Test("hasSettings is consistent with load")
    func testHasSettingsConsistentWithLoad() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        // No settings
        #expect(await repository.hasSettings() == false)
        let loaded1 = try await repository.load()
        #expect(loaded1 == nil)

        // Save settings
        try await repository.save(AppSettings.default)

        // Has settings
        #expect(await repository.hasSettings() == true)
        let loaded2 = try await repository.load()
        #expect(loaded2 != nil)

        // Reset
        try await repository.resetToDefaults()

        // No settings again
        #expect(await repository.hasSettings() == false)
        let loaded3 = try await repository.load()
        #expect(loaded3 == nil)
    }
}

@Suite("SettingsRepositoryImpl Edge Cases")
@MainActor
struct SettingsRepositoryImplEdgeCaseTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Save with custom ID uses singleton ID")
    func testSaveWithCustomID() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let customID = UUID()
        let settings = AppSettings(
            id: customID,
            editor: EditorSettings.default
        )

        try await repository.save(settings)

        let loaded = try await repository.load()
        // Should be saved with singleton ID, not custom ID
        #expect(loaded?.id == AppSettings.singletonID)
    }

    @Test("Load after reset returns nil")
    func testLoadAfterReset() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        try await repository.save(AppSettings.default)
        try await repository.resetToDefaults()

        let loaded = try await repository.load()
        #expect(loaded == nil)
    }

    @Test("Multiple resets don't throw")
    func testMultipleResets() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        try await repository.save(AppSettings.default)

        try await repository.resetToDefaults()
        try await repository.resetToDefaults()
        try await repository.resetToDefaults()

        #expect(await repository.hasSettings() == false)
    }

    @Test("Save immediately after reset")
    func testSaveAfterReset() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        try await repository.save(AppSettings.default)
        try await repository.resetToDefaults()

        let newSettings = AppSettings(
            editor: EditorSettings(openInlineLink: true, debug: true)
        )
        try await repository.save(newSettings)

        let loaded = try await repository.load()
        #expect(loaded?.editor?.openInlineLink == true)
        #expect(loaded?.editor?.debug == true)
    }
}

@Suite("SettingsRepositoryImpl Persistence Tests")
@MainActor
struct SettingsRepositoryImplPersistenceTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Settings persist across repository instances")
    func testSettingsPersistAcrossInstances() async throws {
        let context = try makeContext()

        let repo1 = SettingsRepositoryImpl(modelContext: context)
        let settings = AppSettings(
            editor: EditorSettings(openInlineLink: true, debug: false)
        )
        try await repo1.save(settings)

        let repo2 = SettingsRepositoryImpl(modelContext: context)
        let loaded = try await repo2.load()

        #expect(loaded?.editor?.openInlineLink == true)
        #expect(loaded?.editor?.debug == false)
    }

    @Test("Editor settings are deeply persisted")
    func testEditorSettingsPersisted() async throws {
        let context = try makeContext()
        let repository = SettingsRepositoryImpl(modelContext: context)

        let editor = EditorSettings(
            openInlineLink: false,
            debug: true
        )
        let settings = AppSettings(editor: editor)

        try await repository.save(settings)
        let loaded = try await repository.load()

        #expect(loaded?.editor?.openInlineLink == false)
        #expect(loaded?.editor?.debug == true)
    }
}
