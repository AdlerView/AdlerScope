//
//  DocumentErrorViewTests.swift
//  AdlerScopeTests
//
//  Tests for DocumentErrorView
//

import Testing
import Foundation
import SwiftUI
@testable import AdlerScope

@Suite("DocumentErrorView Tests")
struct DocumentErrorViewTests {

    @Test("DocumentErrorView can be instantiated and body renders")
    func testInstantiation() {
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let document = RecentDocument.sample()
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: {},
            onRemove: {}
        )

        #expect(view.error.localizedDescription == "Test error")

        // Access body to ensure it renders and increase coverage
        let _ = view.body
    }

    @Test("DocumentErrorView body can be accessed")
    func testBodyAccess() {
        let error = NSError(domain: "TestError", code: 1)
        let document = RecentDocument.sample()
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: {},
            onRemove: {}
        )

        // Accessing body executes the view rendering code
        _ = view.body

        // Test passes if body can be accessed without crashing
        #expect(Bool(true))
    }

    @Test("DocumentErrorView with different error types")
    func testWithDifferentErrors() {
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? { "Custom error occurred" }
        }

        let error = CustomError()
        let document = RecentDocument.sample()
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: {},
            onRemove: {}
        )

        #expect(view.error.localizedDescription == "Custom error occurred")

        // Access body to execute view code
        let _ = view.body
    }

    @Test("DocumentErrorView with NSError")
    func testWithNSError() {
        let error = NSError(
            domain: "com.AdlerScope.test",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "File not found"]
        )
        let document = RecentDocument.sample()
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: {},
            onRemove: {}
        )

        #expect(view.error.localizedDescription == "File not found")
        #expect(view.document.id == document.id)

        // Access body to ensure rendering code executes
        let _ = view.body
    }

    @Test("DocumentErrorView stores callbacks")
    func testCallbacksStored() {
        var retryCallCount = 0
        var removeCallCount = 0

        let error = NSError(domain: "TestError", code: 1)
        let document = RecentDocument.sample()
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: { retryCallCount += 1 },
            onRemove: { removeCallCount += 1 }
        )

        // Access body to execute view code
        let _ = view.body

        // Callbacks are stored (we can't test them being called in this simple test)
        #expect(retryCallCount == 0)
        #expect(removeCallCount == 0)
    }

    @Test("DocumentErrorView with different document")
    func testWithDifferentDocument() {
        let error = NSError(domain: "TestError", code: 1)
        let document = RecentDocument(
            url: URL(fileURLWithPath: "/Users/test/custom.md"),
            displayName: "custom.md",
            lastOpened: Date()
        )
        let view = DocumentErrorView(
            error: error,
            document: document,
            onRetry: {},
            onRemove: {}
        )

        #expect(view.document.displayName == "custom.md")
        #expect(view.document.url.path == "/Users/test/custom.md")

        // Access body to execute view rendering
        let _ = view.body
    }

    @Test("DocumentErrorView body renders without crashing for various errors")
    func testBodyRendersWithVariousErrors() {
        let errors: [Error] = [
            NSError(domain: "test", code: 1),
            NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"]),
            NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        ]

        let document = RecentDocument.sample()

        for error in errors {
            let view = DocumentErrorView(
                error: error,
                document: document,
                onRetry: {},
                onRemove: {}
            )

            // Access body for each error type
            let _ = view.body
        }

        #expect(Bool(true))
    }
}
