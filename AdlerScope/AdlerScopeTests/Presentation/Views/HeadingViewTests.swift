//
//  HeadingViewTests.swift
//  AdlerScopeTests
//
//  Integration tests for HeadingView
//

import Testing
import SwiftUI
import Markdown
@testable import AdlerScope

@Suite("HeadingView Integration Tests")
@MainActor
struct HeadingViewTests {

    @Test("All heading levels render without crashing")
    func testAllHeadingLevelsRender() {
        // Arrange
        let levels = [
            "# Level 1",
            "## Level 2",
            "### Level 3",
            "#### Level 4",
            "##### Level 5",
            "###### Level 6"
        ]

        // Act & Assert
        for (index, markdown) in levels.enumerated() {
            let document = Document(parsing: markdown)

            guard let heading = Array(document.children).first as? Heading else {
                Issue.record("Failed to parse heading at index \(index)")
                continue
            }

            let view = HeadingView(heading: heading, openInlineLinks: false)
            _ = view.body  // Smoke test: renders without crashing

            // Validate fixture is correct
            #expect(heading.level == index + 1)
        }
    }
}
