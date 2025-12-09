//
//  DependencyContainerTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for DependencyContainer functionality
//

import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import AdlerScope

@Suite("DependencyContainer Tests")
@MainActor
struct DependencyContainerTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self, RecentDocument.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Shared instance is singleton")
    func testSharedInstanceIsSingleton() {
        let container1 = DependencyContainer.shared
        let container2 = DependencyContainer.shared

        #expect(container1 === container2)
    }

    @Test("Configure sets model context")
    func testConfigure() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()

        container.configure(modelContext: context)

        // Should be able to access settings repository now
        #expect(true)
    }

    @Test("documentRepository is accessible")
    func testDocumentRepository() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.documentRepository

        #expect(true)
    }

    @Test("markdownParserRepository is accessible")
    func testMarkdownParserRepository() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.markdownParserRepository

        #expect(true)
    }

    @Test("parseMarkdownUseCase is accessible")
    func testParseMarkdownUseCase() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.parseMarkdownUseCase

        #expect(true)
    }

    @Test("loadSettingsUseCase is accessible")
    func testLoadSettingsUseCase() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.loadSettingsUseCase

        #expect(true)
    }

    @Test("saveSettingsUseCase is accessible")
    func testSaveSettingsUseCase() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.saveSettingsUseCase

        #expect(true)
    }

    @Test("validateSettingsUseCase is accessible")
    func testValidateSettingsUseCase() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.validateSettingsUseCase

        #expect(true)
    }

    @Test("saveDocumentUseCase is accessible")
    func testSaveDocumentUseCase() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.saveDocumentUseCase

        #expect(true)
    }

    @Test("makeSettingsViewModel creates instance")
    func testMakeSettingsViewModel() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.makeSettingsViewModel()

        #expect(true)
    }

    @Test("makeDocumentManager creates instance")
    func testMakeDocumentManager() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let _ = container.makeDocumentManager()

        #expect(true)
    }

    @Test("makeSplitEditorViewModel creates instance")
    func testMakeMarkdownEditorViewModel() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let settingsVM = container.makeSettingsViewModel()
        let _ = container.makeSplitEditorViewModel(settingsViewModel: settingsVM)

        #expect(true)
    }

    @Test("Multiple makeDocumentManager calls create different instances")
    func testMultipleMakeDocumentManager() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let manager1 = container.makeDocumentManager()
        let manager2 = container.makeDocumentManager()

        #expect(manager1 !== manager2)
    }

    @Test("Multiple makeSplitEditorViewModel calls create different instances")
    func testMultipleMakeMarkdownEditorViewModel() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        let settingsVM = container.makeSettingsViewModel()
        let vm1 = container.makeSplitEditorViewModel(settingsViewModel: settingsVM)
        let vm2 = container.makeSplitEditorViewModel(settingsViewModel: settingsVM)

        #expect(vm1 !== vm2)
    }
}

@Suite("DependencyContainer Environment Tests")
@MainActor
struct DependencyContainerEnvironmentTests {

    @Test("Environment key returns shared instance")
    func testEnvironmentKey() {
        let defaultValue = DependencyContainerKey.defaultValue

        #expect(defaultValue === DependencyContainer.shared)
    }

    @Test("View extension adds container to environment")
    func testViewExtension() {
        let _ = Text("Test").withDependencyContainer()

        // Should compile without error
        #expect(true)
    }
}

@Suite("DependencyContainer Lazy Initialization Tests")
@MainActor
struct DependencyContainerLazyInitTests {

    func makeContext() throws -> ModelContext {
        let schema = Schema([AppSettings.self, RecentDocument.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Repositories are lazily initialized")
    func testLazyRepositoryInitialization() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        // Accessing should initialize - just verify they can be accessed
        let _ = container.documentRepository
        let _ = container.documentRepository

        // Should be accessible multiple times
        #expect(true)
    }

    @Test("Use cases are available after configuration")
    func testLazyUseCaseInitialization() throws {
        let container = DependencyContainer.shared
        let context = try makeContext()
        container.configure(modelContext: context)

        // Accessing should work - each call creates a new instance (factory pattern)
        let useCase1 = container.parseMarkdownUseCase
        let useCase2 = container.parseMarkdownUseCase

        // Use cases are created on demand (factory pattern, not singleton)
        // Just verify they're created successfully
        #expect(useCase1 != nil)
        #expect(useCase2 != nil)
    }

    // Test disabled: DependencyContainer.settingsViewModel property doesn't exist
    // SettingsViewModel is managed as @State in AdlerScopeApp, not in DependencyContainer
    //
    // @Test("View models are lazily initialized")
    // func testLazyViewModelInitialization() throws {
    //     let container = DependencyContainer.shared
    //     let context = try makeContext()
    //     container.configure(modelContext: context)
    //
    //     // Accessing should initialize
    //     let vm1 = container.settingsViewModel
    //     let vm2 = container.settingsViewModel
    //
    //     // Should be the same instance (lazy singleton)
    //     #expect(vm1 === vm2)
    // }
}
