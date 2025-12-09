//
//  SettingsTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for Settings functionality
//  Tests EditorSettings, AppSettings, SettingsViewModel, and related use cases
//

import Testing
import Foundation
import SwiftData

@testable import AdlerScope

// MARK: - EditorSettings Tests

@Suite("EditorSettings Tests")
@MainActor
struct SettingsTests {

    @Test("Default values are correct")
    func testDefaultValues() {
        let settings = EditorSettings.default

        #expect(settings.openInlineLink == false)
        #expect(settings.debug == false)
    }

    @Test("Custom initialization works")
    func testCustomInitialization() {
        let settings = EditorSettings(
            openInlineLink: true,
            debug: true
        )

        #expect(settings.openInlineLink == true)
        #expect(settings.debug == true)
    }

    @Test("Equatable conformance works")
    func testEquatableConformance() {
        let settings1 = EditorSettings(openInlineLink: true, debug: false)
        let settings2 = EditorSettings(openInlineLink: true, debug: false)
        let settings3 = EditorSettings(openInlineLink: false, debug: true)

        #expect(settings1 == settings2)
        #expect(settings1 != settings3)
    }

    @Test("Validation returns self for valid settings")
    func testValidation() {
        let settings = EditorSettings(openInlineLink: true, debug: true)
        let validated = settings.validated()

        #expect(validated == settings)
    }

    @Test("Codable encoding works")
    func testCodableEncoding() throws {
        let settings = EditorSettings(openInlineLink: true, debug: true)
        let encoder = JSONEncoder()

        let data = try encoder.encode(settings)
        #expect(data.count > 0)
    }

    @Test("Codable decoding works")
    func testCodableDecoding() throws {
        let settings = EditorSettings(openInlineLink: true, debug: false)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(settings)
        let decoded = try decoder.decode(EditorSettings.self, from: data)

        #expect(decoded.openInlineLink == true)
        #expect(decoded.debug == false)
    }

    @Test("Round-trip encoding/decoding preserves data")
    func testRoundTripCodable() throws {
        let original = EditorSettings(openInlineLink: true, debug: true)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(EditorSettings.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - AppSettings Basic Tests

@Suite("AppSettings Basic Tests")
@MainActor
struct AppSettingsBasicTestsInSettings {

    @Test("Default values are correct")
    func testDefaultValues() {
        let settings = AppSettings.default

        #expect(settings.id == AppSettings.singletonID)
        #expect(settings.editor == EditorSettings.default)
    }

    @Test("Custom initialization works")
    func testCustomInitialization() {
        let customEditor = EditorSettings(openInlineLink: true, debug: true)
        let settings = AppSettings(editor: customEditor)

        #expect(settings.editor?.openInlineLink == true)
        #expect(settings.editor?.debug == true)
    }

    @Test("Singleton ID is consistent")
    func testSingletonID() {
        let id1 = AppSettings.singletonID
        let id2 = AppSettings.singletonID

        #expect(id1 == id2)
    }

    @Test("Validation delegates to editor validation")
    func testValidation() {
        let settings = AppSettings.default
        let validated = settings.validated()

        #expect(validated.editor == settings.editor?.validated())
    }

    @Test("Can modify editor settings")
    func testModifyEditorSettings() {
        let settings = AppSettings.default
        settings.editor = EditorSettings(openInlineLink: true, debug: true)

        #expect(settings.editor?.openInlineLink == true)
        #expect(settings.editor?.debug == true)
    }
}

// MARK: - SettingsViewModel Tests

@Suite("SettingsViewModel Basic Tests")
struct SettingsViewModelBasicTests {

    @Test("Initialization loads settings")
    @MainActor
    func testInitializationLoadsSettings() async {
        let customSettings = AppSettings(editor: EditorSettings(openInlineLink: true, debug: true))
        let mockRepo = MockSettingsRepository.with(customSettings)

        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Explicitly await load completion instead of relying on init's Task
        await viewModel.loadSettings()

        #expect(viewModel.settings.editor?.openInlineLink == true)
        #expect(viewModel.settings.editor?.debug == true)
    }

    @Test("Editor property provides access to editor settings")
    @MainActor
    func testEditorProperty() async {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Wait for initial load
        try? await Task.sleep(for: .milliseconds(100))

        viewModel.editor = EditorSettings(openInlineLink: true, debug: true)

        #expect(viewModel.settings.editor?.openInlineLink == true)
        #expect(viewModel.settings.editor?.debug == true)
    }

    @Test("Reset to defaults restores default settings")
    @MainActor
    func testResetToDefaults() async {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Wait for initial load
        try? await Task.sleep(for: .milliseconds(100))

        // Set custom settings
        viewModel.settings = AppSettings(editor: EditorSettings(openInlineLink: true, debug: true))

        // Reset to defaults
        await viewModel.resetToDefaults()

        #expect(viewModel.settings.editor == EditorSettings.default)
    }

    @Test("Validate settings returns validation issues")
    @MainActor
    func testValidateSettings() async {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Wait for initial load
        try? await Task.sleep(for: .milliseconds(100))

        let issues = await viewModel.validateSettings()

        // Should have no issues for default settings
        #expect(issues.isEmpty)
    }
}

// MARK: - Settings Integration Tests

@Suite("Settings Integration Tests")
@MainActor
struct SettingsIntegrationTests {

    @Test("Full settings workflow: load, modify, save, load")
    @MainActor
    func testFullSettingsWorkflow() async throws {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let loadUseCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let saveUseCase = SaveSettingsUseCase(settingsRepository: mockRepo)

        // 1. Load initial settings (should be defaults)
        let initial = await loadUseCase.execute()
        #expect(initial.editor == EditorSettings.default)

        // 2. Modify settings
        let modified = AppSettings(editor: EditorSettings(openInlineLink: true, debug: true))
        try await saveUseCase.execute(modified)

        // 3. Load again (should get modified settings)
        let reloaded = await loadUseCase.execute()
        #expect(reloaded.editor?.openInlineLink == true)
        #expect(reloaded.editor?.debug == true)

        // 4. Reset to defaults
        try await saveUseCase.resetToDefaults()

        // 5. Load again (should get defaults)
        let afterReset = await loadUseCase.execute()
        #expect(afterReset.editor == EditorSettings.default)
    }

    @Test("ViewModel auto-save behavior")
    @MainActor
    func testViewModelAutoSave() async throws {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Wait for initial load and any auto-save to complete
        try await Task.sleep(for: .milliseconds(100))

        // Wait for initial auto-save debounce to complete (if triggered)
        try await Task.sleep(for: .milliseconds(1100))

        // Reset counter after initial load and save
        mockRepo.saveCallCount = 0

        // Modify settings
        viewModel.settings = AppSettings(editor: EditorSettings(openInlineLink: true, debug: false))

        // Wait for auto-save debounce (1 second + buffer)
        try await Task.sleep(for: .milliseconds(1200))

        // Settings should be saved
        #expect(mockRepo.saveCallCount >= 1)
        #expect(mockRepo.storedSettings?.editor?.openInlineLink == true)
    }

    @Test("Multiple rapid changes debounce correctly")
    @MainActor
    func testAutoSaveDebouncing() async throws {
        let mockRepo = MockSettingsRepository.withNoSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Wait for initial load
        try await Task.sleep(for: .milliseconds(100))

        // Reset counter after initial load
        mockRepo.saveCallCount = 0

        // Make multiple rapid changes
        for i in 0..<5 {
            viewModel.settings = AppSettings(editor: EditorSettings(
                openInlineLink: i % 2 == 0,
                debug: i % 2 == 1
            ))
            try await Task.sleep(for: .milliseconds(100))
        }

        // Wait for debounce
        try await Task.sleep(for: .milliseconds(1200))

        // Should have debounced to fewer saves than changes
        // Note: Exact count may vary due to timing, but should be less than 5
        #expect(mockRepo.saveCallCount < 5)
    }
}

// MARK: - Edge Cases and Boundary Tests

@Suite("Settings Edge Cases")
@MainActor
struct SettingsEdgeCaseTests {

    @Test("Empty settings object is valid")
    func testEmptySettingsValid() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let isValid = await useCase.isValid(settings)

        #expect(isValid == true)
    }

    @Test("Settings with all booleans true is valid")
    func testAllBooleansTrueValid() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(editor: EditorSettings(openInlineLink: true, debug: true))

        let isValid = await useCase.isValid(settings)

        #expect(isValid == true)
    }

    @Test("Settings with all booleans false is valid")
    func testAllBooleansFalseValid() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(editor: EditorSettings(openInlineLink: false, debug: false))

        let isValid = await useCase.isValid(settings)

        #expect(isValid == true)
    }

    @Test("Singleton ID is a valid UUID")
    func testSingletonIDIsValidUUID() {
        let id = AppSettings.singletonID

        // Should be parseable as UUID string
        let uuidString = id.uuidString
        #expect(uuidString.count == 36) // Standard UUID string length
        #expect(uuidString.contains("-"))
    }
}

