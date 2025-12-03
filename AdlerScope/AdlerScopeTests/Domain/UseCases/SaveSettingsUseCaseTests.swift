//
//  SaveSettingsUseCaseTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for SaveSettingsUseCase functionality
//

import Testing
import Foundation
@testable import AdlerScope

// MARK: - Tests

@Suite("SaveSettingsUseCase Tests")
struct SaveSettingsUseCaseTests {

    @MainActor
    @Test("Execute saves settings successfully")
    func testExecuteSavesSettings() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())

        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)
        try await useCase.execute(settings)

        #expect(mockRepo.saveCallCount == 1)
        #expect(mockRepo.lastSavedSettings != nil)
        #expect(mockRepo.lastSavedSettings?.editor.openInlineLink == true)
        #expect(mockRepo.lastSavedSettings?.editor.debug == false)
    }

    @MainActor
    @Test("Execute validates settings before saving")
    func testExecuteValidatesBeforeSaving() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())

        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: false,
                debug: true
            )
        )

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)
        try await useCase.execute(settings)

        #expect(mockRepo.saveCallCount == 1)
        #expect(mockRepo.lastSavedSettings != nil)
        // Settings should be validated (though current validation just returns same values)
        #expect(mockRepo.lastSavedSettings?.editor.openInlineLink == false)
        #expect(mockRepo.lastSavedSettings?.editor.debug == true)
    }

    @MainActor
    @Test("Execute throws when save fails")
    func testExecuteThrowsOnSaveFailure() async {
        let mockRepo = MockSettingsRepository()
        let expectedError = NSError(domain: "Test", code: 1, userInfo: nil)
        mockRepo.saveResult = .failure(expectedError)

        let settings = AppSettings.default

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

        var thrownError: Error?
        do {
            try await useCase.execute(settings)
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil)
        #expect(mockRepo.saveCallCount == 1)
    }

    @MainActor
    @Test("resetToDefaults calls repository reset")
    func testResetToDefaults() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.resetResult = .success(())

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)
        try await useCase.resetToDefaults()

        #expect(mockRepo.resetCallCount == 1)
    }

    @MainActor
    @Test("resetToDefaults throws when reset fails")
    func testResetToDefaultsThrowsOnFailure() async {
        let mockRepo = MockSettingsRepository()
        let expectedError = NSError(domain: "Test", code: 1, userInfo: nil)
        mockRepo.resetResult = .failure(expectedError)

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

        var thrownError: Error?
        do {
            try await useCase.resetToDefaults()
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil)
        #expect(mockRepo.resetCallCount == 1)
    }
}

@Suite("SaveSettingsUseCase Validation Tests")
struct SaveSettingsUseCaseValidationTests {

    @MainActor
    @Test("Execute preserves valid settings")
    func testExecutePreservesValidSettings() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())

        let validSettings = AppSettings(
            editor: EditorSettings(
                openInlineLink: false,
                debug: false
            )
        )

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)
        try await useCase.execute(validSettings)

        #expect(mockRepo.lastSavedSettings?.editor.openInlineLink == false)
        #expect(mockRepo.lastSavedSettings?.editor.debug == false)
    }

    @MainActor
    @Test("Execute handles all boolean combinations")
    func testExecuteHandlesBooleanCombinations() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())

        let combinations = [
            (openInlineLink: false, debug: false),
            (openInlineLink: false, debug: true),
            (openInlineLink: true, debug: false),
            (openInlineLink: true, debug: true)
        ]

        for (openInlineLink, debug) in combinations {
            let settings = AppSettings(
                editor: EditorSettings(
                    openInlineLink: openInlineLink,
                    debug: debug
                )
            )

            let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)
            try await useCase.execute(settings)

            #expect(mockRepo.lastSavedSettings?.editor.openInlineLink == openInlineLink)
            #expect(mockRepo.lastSavedSettings?.editor.debug == debug)
        }

        #expect(mockRepo.saveCallCount == 4)
    }
}

@Suite("SaveSettingsUseCase Error Handling Tests")
struct SaveSettingsUseCaseErrorHandlingTests {

    @MainActor
    @Test("Execute handles various error types")
    func testExecuteHandlesVariousErrors() async {
        struct CustomError: Error {}
        let errors: [Error] = [
            NSError(domain: "Test", code: 1, userInfo: nil),
            CustomError(),
            URLError(.cannotWriteToFile)
        ]

        for error in errors {
            let mockRepo = MockSettingsRepository()
            mockRepo.saveResult = .failure(error)

            let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

            var didThrow = false
            do {
                try await useCase.execute(AppSettings.default)
            } catch {
                didThrow = true
            }

            #expect(didThrow == true)
        }
    }

    @MainActor
    @Test("resetToDefaults handles various error types")
    func testResetHandlesVariousErrors() async {
        struct CustomError: Error {}
        let errors: [Error] = [
            NSError(domain: "Test", code: 1, userInfo: nil),
            CustomError(),
            URLError(.cannotWriteToFile)
        ]

        for error in errors {
            let mockRepo = MockSettingsRepository()
            mockRepo.resetResult = .failure(error)

            let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

            var didThrow = false
            do {
                try await useCase.resetToDefaults()
            } catch {
                didThrow = true
            }

            #expect(didThrow == true)
        }
    }
}

@Suite("SaveSettingsUseCase Integration Tests")
struct SaveSettingsUseCaseIntegrationTests {

    @MainActor
    @Test("Multiple saves preserve different settings")
    func testMultipleSaves() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

        let settings1 = AppSettings(editor: EditorSettings(openInlineLink: false, debug: false))
        try await useCase.execute(settings1)
        let saved1OpenInlineLink = mockRepo.lastSavedSettings?.editor.openInlineLink

        let settings2 = AppSettings(editor: EditorSettings(openInlineLink: true, debug: true))
        try await useCase.execute(settings2)
        let saved2OpenInlineLink = mockRepo.lastSavedSettings?.editor.openInlineLink

        #expect(mockRepo.saveCallCount == 2)
        #expect(saved1OpenInlineLink == false)
        #expect(saved2OpenInlineLink == true)
    }

    @MainActor
    @Test("Save and reset can be used together")
    func testSaveAndReset() async throws {
        let mockRepo = MockSettingsRepository()
        mockRepo.saveResult = .success(())
        mockRepo.resetResult = .success(())

        let useCase = SaveSettingsUseCase(settingsRepository: mockRepo)

        try await useCase.execute(AppSettings.default)
        #expect(mockRepo.saveCallCount == 1)

        try await useCase.resetToDefaults()
        #expect(mockRepo.resetCallCount == 1)
    }
}
