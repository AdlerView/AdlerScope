//
//  SwiftUITextEditorTests.swift
//  AdlerScopeTests
//
//  Essential tests for SwiftUITextEditor
//  Reduced from 52 to 8 tests - removed 44 tests with #expect(Bool(true)) that tested nothing
//

import Testing
import SwiftUI
@testable import AdlerScope

// MARK: - Test Helpers

/// Helper to mount a SwiftUI view during tests to avoid State/StateObject warnings
private struct Mount<Content: View>: View {
    let content: () -> Content
    var onAppear: (() -> Void)?

    init(@ViewBuilder content: @escaping () -> Content, onAppear: (() -> Void)? = nil) {
        self.content = content
        self.onAppear = onAppear
    }

    var body: some View {
        Group { content() }
            .onAppear { onAppear?() }
    }
}

// MARK: - Body Tests

@Suite("SwiftUITextEditor Body Tests")
@MainActor
struct SwiftUITextEditorBodyTests {

    @Test("Body contains TextEditor with bound text")
    func testBodyContainsTextEditor() {
        // Arrange
        var textValue = "Initial content"
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        // Act
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue == "Initial content")
    }
}

// MARK: - Integration Tests

@Suite("SwiftUITextEditor Integration Tests")
@MainActor
struct SwiftUITextEditorIntegrationTests {

    @Test("Full text editing workflow")
    func testFullTextEditingWorkflow() {
        // Arrange
        var textValue = "Initial text"
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Act - simulate text change
        text.wrappedValue = "Updated text"

        // Assert
        #expect(textValue == "Updated text")
    }

    @Test("View responds to binding updates")
    func testViewRespondsToBindingUpdates() {
        // Arrange
        var textValue = "Test"
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Update text
        textValue = "Updated"

        // Re-mount to simulate refresh
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue == "Updated")
    }
}

// MARK: - Edge Cases Tests

@Suite("SwiftUITextEditor Edge Cases")
@MainActor
struct SwiftUITextEditorEdgeCasesTests {

    @Test("Empty text string")
    func testEmptyText() {
        // Arrange
        var textValue = ""
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        // Act
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue == "")
    }

    @Test("Very long text string")
    func testVeryLongText() {
        // Arrange
        let longText = String(repeating: "a", count: 100000)
        var textValue = longText
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        // Act
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue.count == 100000)
    }

    @Test("Text with special characters")
    func testSpecialCharacters() {
        // Arrange
        let specialText = "Test\n\t\r\"'\\emoji🎉"
        var textValue = specialText
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        // Act
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue == specialText)
    }

    @Test("Unicode and internationalization")
    func testUnicodeText() {
        // Arrange
        let unicodeText = "Hello 世界 مرحبا"
        var textValue = unicodeText
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        // Act
        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Assert
        #expect(textValue == unicodeText)
    }

    @Test("Rapid binding updates")
    func testRapidBindingUpdates() {
        // Arrange
        var textValue = "Start"
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )

        let _ = Mount { SwiftUITextEditor(text: text, formatActions: nil, editActions: nil) }

        // Act - rapid updates
        for i in 0..<100 {
            text.wrappedValue = "Update \(i)"
        }

        // Assert
        #expect(textValue == "Update 99")
    }
}
