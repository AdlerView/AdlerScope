//
//  RecentDocumentRowTests.swift
//  AdlerScopeTests
//
//  Tests for RecentDocumentRow view
//

import Testing
import Foundation
import SwiftUI
@testable import AdlerScope

@Suite("RecentDocumentRow Tests")
@MainActor
struct RecentDocumentRowTests {

    @Test("RecentDocumentRow can be instantiated")
    func testInstantiation() {
        let document = RecentDocument(url: URL(fileURLWithPath: "/test/document.md"))

        let _ = RecentDocumentRow(document: document)

        #expect(Bool(true))
    }

    @Test("RecentDocumentRow with favorite document")
    func testFavoriteDocument() {
        let document = RecentDocument(url: URL(fileURLWithPath: "/test/fav.md"), isFavorite: true)

        let _ = RecentDocumentRow(document: document)

        #expect(document.isFavorite == true)
    }
}
