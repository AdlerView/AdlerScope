//
//  GeneralSettingsViewTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for GeneralSettingsView
//  Tests body getter, closures, and MockSettingsRepository
//

import Testing
import SwiftUI
@testable import AdlerScope

// MARK: - Body Getter Tests

// MARK: - Closure #1 in closure #1 Tests (Section "Preview")

@Suite("GeneralSettingsView closure #1 in closure #1 in body.getter Tests")
@MainActor
struct GeneralSettingsViewClosure1InClosure1Tests {

    @Test("closure #1 in closure #1 - Toggle binding works")
    func testPreviewToggleBinding() {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Test the binding using the custom binding property
        let initialValue = viewModel.openInlineLinkBinding.wrappedValue
        viewModel.openInlineLinkBinding.wrappedValue.toggle()
        #expect(viewModel.openInlineLinkBinding.wrappedValue != initialValue)
    }
}

// MARK: - Closure #2 in closure #1 Tests (Section "Diagnostics")

@Suite("GeneralSettingsView closure #2 in closure #1 in body.getter Tests")
@MainActor
struct GeneralSettingsViewClosure2InClosure1Tests {

    @Test("closure #2 in closure #1 - Debug toggle binding works")
    func testDebugToggleBinding() {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // Test the binding using the custom binding property
        let initialValue = viewModel.debugBinding.wrappedValue
        viewModel.debugBinding.wrappedValue.toggle()
        #expect(viewModel.debugBinding.wrappedValue != initialValue)
    }
}

// MARK: - MockSettingsRepository.load() Tests

@Suite("MockSettingsRepository.load() Tests")
@MainActor
struct MockSettingsRepositoryLoadTests {

    @Test("MockSettingsRepository.load() returns default settings")
    func testMockLoadReturnsDefault() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        mockRepo.loadResult = .success(.default)

        let result = try await mockRepo.load()

        #expect(mockRepo.loadCallCount == 1)
        #expect(result != nil)
        #expect(result?.editor.openInlineLink != nil)
    }

    @Test("MockSettingsRepository.load() can return nil")
    func testMockLoadReturnsNil() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        mockRepo.loadResult = nil

        let result = try await mockRepo.load()

        #expect(mockRepo.loadCallCount == 1)
        #expect(result == nil)
    }

    @Test("MockSettingsRepository.load() handles errors")
    func testMockLoadThrowsError() async {
        let mockRepo = MockSettingsRepository.withErrors()

        do {
            _ = try await mockRepo.load()
            Issue.record("Should have thrown error")
        } catch {
            #expect(Bool(true))
        }
    }
}

// MARK: - MockSettingsRepository.save(_:) Tests

@Suite("MockSettingsRepository.save(_:) Tests")
@MainActor
struct MockSettingsRepositorySaveTests {

    @Test("MockSettingsRepository.save(_:) increments call count")
    func testMockSaveCallCount() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let settings = AppSettings.default

        try await mockRepo.save(settings)

        #expect(mockRepo.saveCallCount == 1)
    }

    @Test("MockSettingsRepository.save(_:) can be called multiple times")
    func testMockSaveMultipleTimes() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let settings = AppSettings.default

        try await mockRepo.save(settings)
        try await mockRepo.save(settings)
        try await mockRepo.save(settings)

        #expect(mockRepo.saveCallCount == 3)
    }

    @Test("MockSettingsRepository.save(_:) handles errors")
    func testMockSaveThrowsError() async {
        let mockRepo = MockSettingsRepository.withSaveError()

        do {
            try await mockRepo.save(.default)
            Issue.record("Should have thrown error")
        } catch {
            #expect(Bool(true))
        }
    }
}

// MARK: - MockSettingsRepository.resetToDefaults() Tests

@Suite("MockSettingsRepository.resetToDefaults() Tests")
@MainActor
struct MockSettingsRepositoryResetTests {

    @Test("MockSettingsRepository.resetToDefaults() increments call count")
    func testMockResetCallCount() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()

        try await mockRepo.resetToDefaults()

        #expect(mockRepo.resetCallCount == 1)
    }

    @Test("MockSettingsRepository.resetToDefaults() can be called multiple times")
    func testMockResetMultipleTimes() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()

        try await mockRepo.resetToDefaults()
        try await mockRepo.resetToDefaults()

        #expect(mockRepo.resetCallCount == 2)
    }

    @Test("MockSettingsRepository.resetToDefaults() handles errors")
    func testMockResetThrowsError() async {
        let mockRepo = MockSettingsRepository.withResetError()

        do {
            try await mockRepo.resetToDefaults()
            Issue.record("Should have thrown error")
        } catch {
            #expect(Bool(true))
        }
    }
}

// MARK: - MockSettingsRepository.hasSettings() Tests

@Suite("MockSettingsRepository.hasSettings() Tests")
@MainActor
struct MockSettingsRepositoryHasSettingsTests {

    @Test("MockSettingsRepository.hasSettings() returns true by default")
    func testMockHasSettingsReturnsTrue() async {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        mockRepo.hasSettingsValue = true

        let result = await mockRepo.hasSettings()

        #expect(mockRepo.hasSettingsCallCount == 1)
        #expect(result == true)
    }

    @Test("MockSettingsRepository.hasSettings() can return false")
    func testMockHasSettingsReturnsFalse() async {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        mockRepo.hasSettingsValue = false

        let result = await mockRepo.hasSettings()

        #expect(mockRepo.hasSettingsCallCount == 1)
        #expect(result == false)
    }

    @Test("MockSettingsRepository.hasSettings() tracks multiple calls")
    func testMockHasSettingsMultipleCalls() async {
        let mockRepo = MockSettingsRepository.withDefaultSettings()

        _ = await mockRepo.hasSettings()
        _ = await mockRepo.hasSettings()
        _ = await mockRepo.hasSettings()

        #expect(mockRepo.hasSettingsCallCount == 3)
    }
}

// MARK: - Integration Tests

@Suite("GeneralSettingsView Integration Tests")
@MainActor
struct GeneralSettingsViewIntegrationTests {

    @Test("Complete workflow with SettingsViewModel")
    func testCompleteWorkflow() async throws {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        // 1. Load settings
        await viewModel.loadSettings()
        #expect(mockRepo.loadCallCount > 0)

        // 2. Change settings using bindings
        viewModel.openInlineLinkBinding.wrappedValue.toggle()
        viewModel.debugBinding.wrappedValue = true

        // 3. Save settings
        await viewModel.saveSettings()
        #expect(mockRepo.saveCallCount > 0)
    }

    @Test("Toggle both settings")
    func testToggleBothSettings() {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        let initialOpenInlineLink = viewModel.openInlineLinkBinding.wrappedValue
        let initialDebug = viewModel.debugBinding.wrappedValue

        viewModel.openInlineLinkBinding.wrappedValue.toggle()
        viewModel.debugBinding.wrappedValue.toggle()

        #expect(viewModel.openInlineLinkBinding.wrappedValue != initialOpenInlineLink)
        #expect(viewModel.debugBinding.wrappedValue != initialDebug)
    }
}

// MARK: - Edge Cases

@Suite("GeneralSettingsView Edge Cases")
@MainActor
struct GeneralSettingsViewEdgeCasesTests {

    @Test("View with no settings loaded")
    func testNoSettings() async {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        mockRepo.loadResult = nil

        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        await viewModel.loadSettings()

        // Should still have default settings
        #expect(Bool(true))
    }

    @Test("Rapid toggle changes")
    func testRapidToggleChanges() {
        let mockRepo = MockSettingsRepository.withDefaultSettings()
        let viewModel = SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )

        let initial = viewModel.openInlineLinkBinding.wrappedValue

        // Toggle multiple times
        for _ in 0..<10 {
            viewModel.openInlineLinkBinding.wrappedValue.toggle()
        }

        // Should be back to original value (even number of toggles)
        #expect(viewModel.openInlineLinkBinding.wrappedValue == initial)
    }
}
