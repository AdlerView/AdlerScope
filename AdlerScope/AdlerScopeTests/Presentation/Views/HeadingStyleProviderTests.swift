//
//  HeadingStyleProviderTests.swift
//  AdlerScopeTests
//
//  Tests for HeadingStyleProvider business logic
//

import Testing
import SwiftUI
@testable import AdlerScope

@Suite("HeadingStyleProvider Tests")
struct HeadingStyleProviderTests {

    @Test("verticalPaddingForLevel returns correct padding for all levels")
    func testVerticalPaddingForLevel() {
        // Arrange
        let provider = HeadingStyleProvider()

        // Act & Assert - Test all padding mappings
        #expect(provider.verticalPaddingForLevel(1) == 8)
        #expect(provider.verticalPaddingForLevel(2) == 6)
        #expect(provider.verticalPaddingForLevel(3) == 4)
        #expect(provider.verticalPaddingForLevel(4) == 4)
        #expect(provider.verticalPaddingForLevel(5) == 2)
        #expect(provider.verticalPaddingForLevel(6) == 2)

        // Test default case (level > 6)
        #expect(provider.verticalPaddingForLevel(7) == 2)
        #expect(provider.verticalPaddingForLevel(100) == 2)

        // Test edge case (level < 1)
        #expect(provider.verticalPaddingForLevel(0) == 2)
        #expect(provider.verticalPaddingForLevel(-1) == 2)
    }

    @Test("fontForLevel returns a Font for all valid levels")
    func testFontForLevelDoesNotCrash() {
        // Arrange
        let provider = HeadingStyleProvider()

        // Act - Call function for all levels, ensure no crash
        // (Font is not Equatable, so we can only test that it returns without crashing)
        _ = provider.fontForLevel(1)
        _ = provider.fontForLevel(2)
        _ = provider.fontForLevel(3)
        _ = provider.fontForLevel(4)
        _ = provider.fontForLevel(5)
        _ = provider.fontForLevel(6)

        // Test default case (level > 6)
        _ = provider.fontForLevel(7)
        _ = provider.fontForLevel(100)

        // Test edge case (level < 1)
        _ = provider.fontForLevel(0)
        _ = provider.fontForLevel(-1)

        // Assert - If we got here without crashing, test passes
        #expect(Bool(true))
    }
}
