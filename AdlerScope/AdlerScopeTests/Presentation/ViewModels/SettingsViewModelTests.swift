//
//  SettingsViewModelTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for SettingsViewModel
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    // MARK: - Tests

    @Test("Load settings on initialization")
    @MainActor
    func testLoadSettingsOnInit() async {
        // Arrange
        let mockRepo = MockSettingsRepository.withDefaultSettings()

        let loadUseCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let saveUseCase = SaveSettingsUseCase(settingsRepository: mockRepo)
        let validateUseCase = ValidateSettingsUseCase()

        // Act
        _ = SettingsViewModel(
            loadSettingsUseCase: loadUseCase,
            saveSettingsUseCase: saveUseCase,
            validateSettingsUseCase: validateUseCase
        )

        // Wait for async load
        try? await Task.sleep(for: .milliseconds(100))

        // Assert
        #expect(mockRepo.loadCallCount >= 1)
    }

    @Test("Save settings successfully")
    @MainActor
    func testSaveSettings() async {
        // Arrange
        let mockRepo = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Act
        await viewModel.saveSettings()

        // Assert
        #expect(mockRepo.saveCallCount >= 1)
    }

    @Test("Reset to defaults")
    @MainActor
    func testResetToDefaults() async {
        // Arrange
        let mockRepo = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Act
        await viewModel.resetToDefaults()

        // Assert
        #expect(mockRepo.resetCallCount == 1)
        #expect(viewModel.settings.editor == EditorSettings.default)
    }

    @Test("Validate settings")
    @MainActor
    func testValidateSettings() async {
        // Arrange
        let mockRepo = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Act
        let issues = await viewModel.validateSettings()

        // Assert
        #expect(issues.isEmpty == true)
    }

    @Test("Editor accessor gets and sets editor settings")
    @MainActor
    func testEditorAccessor() {
        // Arrange
        let mockRepo = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Act
        var newEditor = EditorSettings.default
        newEditor.debug = true
        viewModel.editor = newEditor

        // Assert
        #expect(viewModel.editor.debug == true)
    }

    @Test("Load settings handles error gracefully")
    @MainActor
    func testLoadSettingsHandlesError() async {
        // Arrange
        let mockRepo = MockSettingsRepository.withErrors()

        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Act
        await viewModel.loadSettings()

        // Assert - should fall back to default settings (compare values, not instances)
        #expect(viewModel.settings.editor == AppSettings.default.editor)
    }
}
