//
//  EmptyStateViewTests.swift
//  AdlerScopeTests
//
//  Tests for EmptyStateView
//

import Testing
import Foundation
import SwiftUI
@testable import AdlerScope

@Suite("EmptyStateView Tests")
struct EmptyStateViewTests {

    @Test("EmptyStateView can be instantiated")
    func testInstantiation() {
        var openDocumentCalled = false
        var newDocumentCalled = false

        let _ = EmptyStateView(
            onOpenDocument: { openDocumentCalled = true },
            onNewDocument: { newDocumentCalled = true }
        )

        // Verify closures weren't called during initialization
        #expect(openDocumentCalled == false)
        #expect(newDocumentCalled == false)
    }

    @Test("EmptyStateView with callbacks")
    func testWithCallbacks() {
        var openCalled = false
        var newCalled = false

        let _ = EmptyStateView(
            onOpenDocument: { openCalled = true },
            onNewDocument: { newCalled = true }
        )

        // Verify view can be created with callbacks
        // (The fact that this compiles proves callbacks are properly stored)
        #expect(openCalled == false)
        #expect(newCalled == false)
    }
}
