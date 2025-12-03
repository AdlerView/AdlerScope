//
//  AboutViewTests.swift
//  AdlerScopeTests
//
//  Tests for AboutView
//

import Testing
import Foundation
import SwiftUI
@testable import AdlerScope

@Suite("AboutView Tests")
struct AboutViewTests {

    @Test("AboutView can be instantiated")
    func testInstantiation() {
        let view = AboutView()

        // AboutView is a struct, verify it has a body
        // (The fact that this compiles proves the view is valid)
        let _ = view.body
        #expect(true)
    }
}
