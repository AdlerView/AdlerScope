//
//  EditorSettingsTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for EditorSettings
//

import Testing
@testable import AdlerScope
import Foundation

@Suite("EditorSettings Tests")
struct EditorSettingsTests {

    @Test("Default settings have expected values")
    func testDefaultSettings() {
        // Arrange & Act
        let settings = EditorSettings.default

        // Assert
        #expect(settings.openInlineLink == false)
        #expect(settings.debug == false)
    }

    @Test("Validated returns same settings for valid input")
    func testValidatedPreservesValidSettings() {
        // Arrange
        let settings = EditorSettings.default

        // Act
        let validated = settings.validated()

        // Assert
        #expect(validated.openInlineLink == settings.openInlineLink)
        #expect(validated.debug == settings.debug)
    }

    @Test("Custom settings can be created")
    func testCustomSettings() {
        // Arrange & Act
        let settings = EditorSettings(openInlineLink: true, debug: true)

        // Assert
        #expect(settings.openInlineLink == true)
        #expect(settings.debug == true)
    }

    @Test("Codable encoding and decoding")
    func testCodableEncodingDecoding() throws {
        // Arrange
        let settings = EditorSettings(openInlineLink: true, debug: true)

        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EditorSettings.self, from: data)

        // Assert
        #expect(decoded.openInlineLink == settings.openInlineLink)
        #expect(decoded.debug == settings.debug)
    }

    @Test("Sendable conformance allows cross-actor usage")
    func testSendableConformance() async {
        // Arrange
        let settings = await EditorSettings.default

        // Act - pass to actor
        await TestActor().processSettings(settings)

        // Assert
        #expect(true)
    }

    actor TestActor {
        func processSettings(_ settings: EditorSettings) {
            // Proves Sendable conformance
        }
    }
}
