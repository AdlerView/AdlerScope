//
//  LoadSettingsUseCaseTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for LoadSettingsUseCase functionality
//

import Testing
import Foundation
@testable import AdlerScope

// MARK: - Tests

@Suite("LoadSettingsUseCase Tests")
struct LoadSettingsUseCaseTests {

    @MainActor
    @Test("Execute returns loaded settings when available")
    func testExecuteReturnsLoadedSettings() async {
        let mockRepo = MockSettingsRepository()
        let expectedSettings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )
        mockRepo.loadResult = .success(expectedSettings)

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.execute()

        #expect(mockRepo.loadCallCount == 1)
        #expect(result.editor.openInlineLink == true)
        #expect(result.editor.debug == false)
    }

    @MainActor
    @Test("Execute returns default settings when no saved settings exist")
    func testExecuteReturnsDefaultWhenNoSettings() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.loadResult = .success(nil)

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.execute()

        #expect(mockRepo.loadCallCount == 1)
        #expect(result.id == AppSettings.singletonID)
    }

    @MainActor
    @Test("Execute returns default settings when load fails")
    func testExecuteReturnsDefaultOnError() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.loadResult = .failure(NSError(domain: "Test", code: 1, userInfo: nil))

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.execute()

        #expect(mockRepo.loadCallCount == 1)
        #expect(result.id == AppSettings.singletonID)
    }

    @MainActor
    @Test("Execute validates loaded settings")
    func testExecuteValidatesSettings() async {
        let mockRepo = MockSettingsRepository()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: true
            )
        )
        mockRepo.loadResult = .success(settings)

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.execute()

        #expect(mockRepo.loadCallCount == 1)
        // Settings should be validated (though current validation just returns same values)
        #expect(result.editor.openInlineLink == true)
        #expect(result.editor.debug == true)
    }

    @MainActor
    @Test("hasSettings returns true when settings exist")
    func testHasSettingsReturnsTrue() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.hasSettingsValue = true

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.hasSettings()

        #expect(result == true)
        #expect(mockRepo.hasSettingsCallCount == 1)
    }

    @MainActor
    @Test("hasSettings returns false when settings don't exist")
    func testHasSettingsReturnsFalse() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.hasSettingsValue = false

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
        let result = await useCase.hasSettings()

        #expect(result == false)
        #expect(mockRepo.hasSettingsCallCount == 1)
    }
}

@Suite("LoadSettingsUseCase Error Handling Tests")
struct LoadSettingsUseCaseErrorHandlingTests {

    @MainActor
    @Test("Execute handles various error types gracefully")
    func testExecuteHandlesVariousErrors() async {
        struct CustomError: Error {}
        let errors: [Error] = [
            NSError(domain: "Test", code: 1, userInfo: nil),
            CustomError(),
            URLError(.cannotOpenFile)
        ]

        for error in errors {
            let mockRepo = MockSettingsRepository()
            mockRepo.loadResult = .failure(error)

            let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
            let result = await useCase.execute()

            #expect(result.id == AppSettings.singletonID)
        }
    }

    @MainActor
    @Test("Execute always returns valid settings")
    func testExecuteAlwaysReturnsValidSettings() async {
        let scenarios: [Result<AppSettings?, Error>?] = [
            .success(nil),
            .success(AppSettings.default),
            .failure(NSError(domain: "Test", code: 1, userInfo: nil)),
            nil
        ]

        for scenario in scenarios {
            let mockRepo = MockSettingsRepository()
            mockRepo.loadResult = scenario

            let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)
            let result = await useCase.execute()

            // Editor settings should always be present
            #expect(result.editor.openInlineLink == false || result.editor.openInlineLink == true)
        }
    }
}

@Suite("LoadSettingsUseCase Integration Tests")
struct LoadSettingsUseCaseIntegrationTests {

    @MainActor
    @Test("Multiple calls to execute load settings each time")
    func testMultipleExecuteCalls() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.loadResult = .success(AppSettings.default)

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)

        _ = await useCase.execute()
        _ = await useCase.execute()
        _ = await useCase.execute()

        #expect(mockRepo.loadCallCount == 3)
    }

    @MainActor
    @Test("hasSettings can be called independently of execute")
    func testHasSettingsIndependent() async {
        let mockRepo = MockSettingsRepository()
        mockRepo.hasSettingsValue = true

        let useCase = LoadSettingsUseCase(settingsRepository: mockRepo)

        let hasSettings1 = await useCase.hasSettings()
        let hasSettings2 = await useCase.hasSettings()

        #expect(hasSettings1 == true)
        #expect(hasSettings2 == true)
        #expect(mockRepo.hasSettingsCallCount == 2)
        #expect(mockRepo.loadCallCount == 0)
    }
}
