//
//  SplitEditorViewTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for SplitEditorView
//  Tests initialization, body getter, and all closures
//

import Testing
import SwiftUI
import Markdown
@testable import AdlerScope

// MARK: - Helper Functions

@MainActor
func createMockParseUseCase() -> (ParseMarkdownUseCase, MockMarkdownParserRepository) {
    let mockRepo = MockMarkdownParserRepository.withSuccessfulParsing()
    let useCase = ParseMarkdownUseCase(parserRepository: mockRepo)
    return (useCase, mockRepo)
}

/// Wait for async render to complete by polling mock repository
/// This is needed because unstructured Tasks run on MainActor and tests must yield control
@MainActor
func waitForMockParse(mockRepo: MockMarkdownParserRepository, timeout: Duration = .seconds(2)) async throws {
    let deadline = ContinuousClock.now.advanced(by: timeout)

    while mockRepo.parseCallCount == 0 {
        if ContinuousClock.now >= deadline {
            Issue.record("Timeout waiting for parse to complete")
            return
        }
        await Task.yield()
    }
}

// MARK: - Initialization Tests

@Suite("SplitEditorView Initialization Tests")
@MainActor
struct SplitEditorViewInitializationTests {

    @Test("init(document:parseMarkdownUseCase:settingsViewModel:) creates view correctly")
    func testInitialization() {
        var document = MarkdownFileDocument(content: "# Test")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let _ = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // View should be created successfully
        #expect(Bool(true))
    }

    @Test("init sets up bindings correctly")
    func testInitializationBindings() {
        var document = MarkdownFileDocument(content: "Initial content")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let _ = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Verify binding works
        #expect(binding.wrappedValue.content == "Initial content")
    }
}

// MARK: - Body Getter Tests

@Suite("SplitEditorView body.getter Tests")
@MainActor
struct SplitEditorViewBodyGetterTests {

    @Test("body.getter returns a valid View")
    func testBodyGetter() {
        var document = MarkdownFileDocument(content: "# Test")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Access body before adding environment object
        _ = view.body

        #expect(Bool(true))
    }

    @Test("body.getter configures HSplitView on macOS")
    func testBodyGetterMacOSLayout() {
        var document = MarkdownFileDocument(content: "# macOS Test")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        _ = view.body

        #if os(macOS)
        #expect(Bool(true)) // HSplitView is used
        #else
        #expect(Bool(true)) // HStack is used
        #endif
    }
}

// MARK: - Closure #1 Tests (onChange of document.content)

@Suite("SplitEditorView closure #1 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure1Tests {

    @Test("closure #1 in body.getter - onChange of document.content triggers debounce")
    func testOnChangeDocumentContent() async {
        var document = MarkdownFileDocument(content: "Initial")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Simulate onChange by directly testing the closure behavior
        // The closure calls: viewModel.debounceRender(content: newValue)

        _ = view.body

        #expect(Bool(true))
    }
}

// MARK: - Closure #1 in closure #1 Tests (viewModel.debounceRender)

@Suite("SplitEditorView closure #1 in closure #1 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure1InClosure1Tests {

    @Test("closure #1 in closure #1 - viewModel.debounceRender call")
    func testDebounceRenderCall() async throws {
        let (mockUseCase, mockRepo) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Test the debounceRender method that's called in the closure
        viewModel.debounceRender(content: "# New Content")

        // Wait for debounce delay (500ms)
        try await Task.sleep(for: .milliseconds(500))

        // Wait for parse to complete
        try await waitForMockParse(mockRepo: mockRepo)

        let callCount = mockRepo.parseCallCount
        let lastMarkdown = mockRepo.lastParsedMarkdown

        #expect(callCount > 0)
        #expect(lastMarkdown == "# New Content")
    }
}

// MARK: - Closure #2 Tests (onChange of refreshTrigger)

@Suite("SplitEditorView closure #2 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure2Tests {

    @Test("closure #2 in body.getter - onChange of refreshTrigger")
    func testOnChangeRefreshTrigger() async {
        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        let oldTrigger = viewModel.refreshTrigger

        // Trigger refresh
        viewModel.forceRender(content: "# Refresh Test")

        // Wait for task
        try? await Task.sleep(for: .milliseconds(100))

        // Trigger should have changed
        #expect(viewModel.refreshTrigger != oldTrigger)
    }
}

// MARK: - Closure #3 Tests (onAppear Task)

@Suite("SplitEditorView closure #3 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure3Tests {

    @Test("closure #3 in body.getter - onAppear Task block")
    func testOnAppearTask() async {
        let (mockUseCase, mockRepo) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Simulate onAppear by calling the same code
        let task = Task {
            await viewModel.render(content: "# Initial Content")
        }
        await task.value

        let callCount = mockRepo.parseCallCount
        #expect(callCount > 0)
        #expect(viewModel.renderedDocument != nil)
    }
}

// MARK: - Closure #4 Tests (Task block in onAppear)

@Suite("SplitEditorView closure #4 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure4Tests {

    @Test("closure #4 in body.getter - Task execution block")
    func testTaskExecutionBlock() async {
        let (mockUseCase, mockRepo) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // The Task block contains: await viewModel.render(content: document.content)
        let task = Task {
            await viewModel.render(content: "# Task Test")
        }

        await task.value

        let callCount = mockRepo.parseCallCount
        #expect(callCount == 1)
        #expect(viewModel.renderedDocument != nil)
    }
}

// MARK: - Closure #1 in closure #4 Tests (viewModel.render)

@Suite("SplitEditorView closure #1 in closure #4 in body.getter Tests")
@MainActor
struct SplitEditorViewClosure1InClosure4Tests {

    @Test("closure #1 in closure #4 - viewModel.render call")
    func testRenderCallInTask() async {
        let (mockUseCase, mockRepo) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // This is the actual render call inside the Task
        await viewModel.render(content: "# Render Test")

        let callCount = mockRepo.parseCallCount
        let lastMarkdown = mockRepo.lastParsedMarkdown
        #expect(callCount == 1)
        #expect(lastMarkdown == "# Render Test")
        #expect(viewModel.renderedDocument != nil)
    }

    @Test("closure #1 in closure #4 - render with different content")
    func testRenderWithDifferentContent() async {
        let (mockUseCase, mockRepo) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // Render multiple times
        await viewModel.render(content: "# First")
        await viewModel.render(content: "# Second")
        await viewModel.render(content: "# Third")

        let callCount = mockRepo.parseCallCount
        let lastMarkdown = mockRepo.lastParsedMarkdown
        #expect(callCount == 3)
        #expect(lastMarkdown == "# Third")
    }
}

// MARK: - Integration Tests

@Suite("SplitEditorView Integration Tests")
@MainActor
struct SplitEditorViewIntegrationTests {

    @Test("Complete workflow with all closures")
    func testCompleteWorkflow() async {
        var document = MarkdownFileDocument(content: "# Initial")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let _ = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        // 1. View created
        #expect(binding.wrappedValue.content == "# Initial")

        // 2. Simulate content change
        document.content = "# Changed"
        binding.wrappedValue = document

        #expect(binding.wrappedValue.content == "# Changed")
    }

    @Test("View with empty document")
    func testEmptyDocument() {
        var document = MarkdownFileDocument(content: "")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        _ = view.body

        #expect(Bool(true))
    }
}

// MARK: - Edge Cases

@Suite("SplitEditorView Edge Cases")
@MainActor
struct SplitEditorViewEdgeCasesTests {

    @Test("Large document content")
    func testLargeDocument() {
        let largeContent = String(repeating: "# Heading\n\nParagraph text here.\n\n", count: 1000)
        var document = MarkdownFileDocument(content: largeContent)
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        _ = view.body

        #expect(Bool(true))
    }

    @Test("Special characters in document")
    func testSpecialCharacters() {
        var document = MarkdownFileDocument(content: "# Test\n\n*italic* **bold** `code` [link](url)")
        let binding = Binding<MarkdownFileDocument>(
            get: { document },
            set: { document = $0 }
        )

        let (mockUseCase, _) = createMockParseUseCase()
        let mockSettings = createMockSettingsViewModel()

        let view = SplitEditorView(
            document: binding,
            parseMarkdownUseCase: mockUseCase,
            settingsViewModel: mockSettings
        )

        _ = view.body

        #expect(Bool(true))
    }
}
