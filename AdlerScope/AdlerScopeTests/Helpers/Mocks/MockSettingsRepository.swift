//
//  MockSettingsRepository.swift
//  AdlerScopeTests
//
//  Centralized mock implementation of SettingsRepository for all tests
//  Combines best features from all previous mock variants
//

import Foundation
@testable import AdlerScope

/// Comprehensive mock implementation of SettingsRepository for testing
/// Supports both success and failure scenarios with detailed tracking
///
/// ## Usage in Tests
/// Tag your test suites with `.tags(.mock, .repository)` when using this mock:
/// ```swift
/// @Suite("My Settings Tests", .tags(.mock, .repository))
/// struct MySettingsTests {
///     let mockRepo = MockSettingsRepository.withDefaultSettings()
///     // ...
/// }
/// ```
@MainActor
final class MockSettingsRepository: SettingsRepository {
    // MARK: - Test Data

    /// Settings to return from load()
    var storedSettings: AppSettings?

    /// Last settings passed to save()
    var lastSavedSettings: AppSettings?

    // MARK: - Result Configuration

    /// Result to return from load() - if set, takes precedence over storedSettings
    /// - Note: Leave nil to use storedSettings directly (default behavior)
    var loadResult: Result<AppSettings?, Error>?

    /// Result to return from save() - if set, determines success or failure
    /// - Note: Leave nil for automatic success behavior (default)
    var saveResult: Result<Void, Error>?

    /// Result to return from resetToDefaults() - if set, determines success or failure
    /// - Note: Leave nil for automatic success behavior (default)
    var resetResult: Result<Void, Error>?

    /// Value to return from hasSettings() - defaults to false
    var hasSettingsValue: Bool = false

    // MARK: - Call Tracking

    /// Number of times load() was called
    var loadCallCount = 0

    /// Number of times save() was called
    var saveCallCount = 0

    /// Number of times resetToDefaults() was called
    var resetCallCount = 0

    /// Number of times hasSettings() was called
    var hasSettingsCallCount = 0

    // MARK: - Initialization

    init(
        storedSettings: AppSettings? = nil,
        hasSettingsValue: Bool = false
    ) {
        self.storedSettings = storedSettings
        self.hasSettingsValue = hasSettingsValue
    }

    // MARK: - SettingsRepository Protocol

    func load() async throws -> AppSettings? {
        loadCallCount += 1

        if let result = loadResult {
            switch result {
            case .success(let settings):
                return settings
            case .failure(let error):
                throw error
            }
        }

        return storedSettings
    }

    func save(_ settings: AppSettings) async throws {
        saveCallCount += 1

        // Only update state on success
        if let result = saveResult {
            switch result {
            case .success:
                storedSettings = settings
                lastSavedSettings = settings
            case .failure(let error):
                throw error
            }
        } else {
            storedSettings = settings
            lastSavedSettings = settings
        }
    }

    func resetToDefaults() async throws {
        resetCallCount += 1

        if let result = resetResult {
            switch result {
            case .success:
                storedSettings = .default
            case .failure(let error):
                throw error
            }
        } else {
            storedSettings = .default
        }
    }

    func hasSettings() async -> Bool {
        hasSettingsCallCount += 1
        return hasSettingsValue
    }

    // MARK: - Test Helpers

    /// Reset only tracking counts and transient state (preserves configuration)
    /// Use this between test iterations when you want to keep the mock's setup
    func resetTracking() {
        loadCallCount = 0
        saveCallCount = 0
        resetCallCount = 0
        hasSettingsCallCount = 0
        lastSavedSettings = nil
    }

    /// Reset all state to initial values (including configuration)
    /// Use this for complete cleanup between unrelated tests
    func reset() {
        resetTracking()
        storedSettings = nil
        loadResult = nil
        saveResult = nil
        resetResult = nil
        hasSettingsValue = false
    }
}

// MARK: - Convenience Factory Methods

extension MockSettingsRepository {
    /// Creates a mock that returns default settings
    static func withDefaultSettings() -> MockSettingsRepository {
        MockSettingsRepository(storedSettings: .default, hasSettingsValue: true)
    }

    /// Creates a mock that returns nil (no settings)
    static func withNoSettings() -> MockSettingsRepository {
        MockSettingsRepository(storedSettings: nil, hasSettingsValue: false)
    }

    /// Creates a mock with custom settings
    static func with(_ settings: AppSettings) -> MockSettingsRepository {
        MockSettingsRepository(storedSettings: settings, hasSettingsValue: true)
    }

    /// Creates a mock that throws errors on all operations
    static func withErrors(_ error: Error = NSError(domain: "test", code: -1)) -> MockSettingsRepository {
        let mock = MockSettingsRepository()
        mock.loadResult = .failure(error)
        mock.saveResult = .failure(error)
        mock.resetResult = .failure(error)
        return mock
    }

    /// Creates a mock that succeeds on load but fails on save
    static func withSaveError(_ error: Error = NSError(domain: "test", code: -1)) -> MockSettingsRepository {
        let mock = MockSettingsRepository.withDefaultSettings()
        mock.saveResult = .failure(error)
        return mock
    }

    /// Creates a mock that succeeds on load but fails on reset
    static func withResetError(_ error: Error = NSError(domain: "test", code: -1)) -> MockSettingsRepository {
        let mock = MockSettingsRepository.withDefaultSettings()
        mock.resetResult = .failure(error)
        return mock
    }
}
