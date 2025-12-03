//
//  TestHelpers.swift
//  AdlerScopeTests
//
//  Common helper functions for tests
//

import Foundation
@testable import AdlerScope

// MARK: - SettingsViewModel Helpers

/// Creates a mock SettingsViewModel with default settings for testing
@MainActor
func createMockSettingsViewModel() -> SettingsViewModel {
    let mockRepo = MockSettingsRepository.withDefaultSettings()
    return SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )
}
