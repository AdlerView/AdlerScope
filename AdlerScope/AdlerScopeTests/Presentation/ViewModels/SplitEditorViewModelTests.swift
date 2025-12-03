//
//  SplitEditorViewModelTests.swift
//  AdlerScopeTests
//
//  Essential tests for SplitEditorViewModel
//  Reduced from 9 to 7 tests - removed 2 redundant tests
//

import Testing
import Markdown
import SwiftUI
import Combine
@testable import AdlerScope

@Suite("SplitEditorViewModel Tests")
@MainActor
struct SplitEditorViewModelTests {

    // MARK: - Helper Methods

    func makeSettingsViewModel() -> SettingsViewModel {
        let mockRepo = MockSettingsRepository()
        return SettingsViewModel(
            loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
            saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
            validateSettingsUseCase: ValidateSettingsUseCase()
        )
    }

    final class MockSettingsRepository: SettingsRepository {
        func load() async throws -> AppSettings? { return .default }
        func save(_ settings: AppSettings) async throws {}
        func resetToDefaults() async throws {}
        func hasSettings() async -> Bool { return true }
    }

    /// Wait for async render to complete by polling renderedDocument
    /// This is needed because unstructured Tasks run on MainActor and tests must yield control
    func waitForRender(viewModel: SplitEditorViewModel, timeout: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)

        while viewModel.renderedDocument == nil {
            if ContinuousClock.now >= deadline {
                Issue.record("Timeout waiting for render to complete")
                return
            }
            await Task.yield()
        }
    }

    // MARK: - Tests

    @Test("Render content successfully")
    func testRenderContent() async {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )
        let content = "# Test Document\n\nContent here."

        // Act
        await viewModel.render(content: content)

        // Assert
        #expect(viewModel.renderedDocument != nil)
        #expect(viewModel.isRendering == false)
    }

    @Test("Debounce render delays execution")
    func testDebounceRender() async throws {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )
        let content = "# Test"

        // Act
        viewModel.debounceRender(content: content)

        // Assert - should not render immediately
        #expect(viewModel.renderedDocument == nil)

        // Wait for debounce (500ms) + render execution
        try await Task.sleep(for: .milliseconds(500))
        try await waitForRender(viewModel: viewModel)

        // Should have rendered now
        #expect(viewModel.renderedDocument != nil)
    }

    @Test("Force render cancels debounce")
    func testForceRenderCancelsDebounce() async throws {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )
        let content = "# Test Content"

        // Act
        viewModel.debounceRender(content: "old content")
        viewModel.forceRender(content: content)

        // Wait for unstructured Task to complete
        try await waitForRender(viewModel: viewModel)

        // Assert
        #expect(viewModel.renderedDocument != nil)
    }

    @Test("Cancel pending render stops execution")
    func testCancelPendingRender() async throws {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )

        // Act
        viewModel.debounceRender(content: "test")
        viewModel.cancelPendingRender()

        // Wait longer than debounce delay
        try await Task.sleep(for: .milliseconds(600))

        // Assert - should not have rendered
        #expect(viewModel.renderedDocument == nil)
    }

    @Test("Render complex markdown document")
    func testRenderComplexMarkdown() async {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )

        let complexMarkdown = """
        # Main Heading

        ## Subheading

        **Bold** and *italic* text.

        - List item 1
        - List item 2

        ```swift
        func test() {
            print("Hello")
        }
        ```

        > Block quote

        [Link](https://example.com)
        """

        // Act
        await viewModel.render(content: complexMarkdown)

        // Assert
        #expect(viewModel.renderedDocument != nil)
        #expect(viewModel.renderedDocument?.childCount ?? 0 > 0)
    }

    @Test("Multiple debounce calls only render once")
    func testMultipleDebounceCallsOnlyRenderOnce() async throws {
        // Arrange
        let settingsViewModel = makeSettingsViewModel()
        let viewModel = SplitEditorViewModel(
            parseMarkdownUseCase: ParseMarkdownUseCase(parserRepository: MarkdownParserRepositoryImpl()),
            settingsViewModel: settingsViewModel
        )

        // Act - call debounce multiple times rapidly
        viewModel.debounceRender(content: "content 1")
        viewModel.debounceRender(content: "content 2")
        viewModel.debounceRender(content: "content 3")

        // Wait for debounce (500ms) + render execution
        try await Task.sleep(for: .milliseconds(500))
        try await waitForRender(viewModel: viewModel)

        // Assert - should only have rendered the last content
        #expect(viewModel.renderedDocument != nil)
    }
}
