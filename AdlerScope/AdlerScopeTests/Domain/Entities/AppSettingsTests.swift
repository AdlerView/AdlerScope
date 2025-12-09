//
//  AppSettingsTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for AppSettings functionality
//

import Testing
import Foundation
import SwiftData
@testable import AdlerScope

@Suite("AppSettings Tests")
struct AppSettingsTests {

    @Test("Singleton ID is consistent")
    func testSingletonID() {
        let expectedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #expect(AppSettings.singletonID == expectedID)
    }

    @Test("Default AppSettings initialization")
    func testDefaultInitialization() {
        let settings = AppSettings.default

        #expect(settings.id == AppSettings.singletonID)
        #expect(settings.editor?.openInlineLink == false)
        #expect(settings.editor?.debug == false)
    }

    @Test("Custom initialization with default ID")
    func testCustomInitializationDefaultID() {
        let editorSettings = EditorSettings.default
        let settings = AppSettings(editor: editorSettings)

        #expect(settings.id == AppSettings.singletonID)
        #expect(settings.editor?.openInlineLink == editorSettings.openInlineLink)
        #expect(settings.editor?.debug == editorSettings.debug)
    }

    @Test("Custom initialization with custom ID")
    func testCustomInitializationCustomID() {
        let customID = UUID()
        let editorSettings = EditorSettings.default
        let settings = AppSettings(id: customID, editor: editorSettings)

        #expect(settings.id == customID)
        #expect(settings.id != AppSettings.singletonID)
    }

    @Test("Default returns new instance each time")
    func testDefaultReturnsNewInstance() {
        let settings1 = AppSettings.default
        let settings2 = AppSettings.default

        // They should have the same singleton ID
        #expect(settings1.id == settings2.id)
        #expect(settings1.id == AppSettings.singletonID)
    }

    @Test("Validated returns validated settings")
    func testValidated() {
        let editorSettings = EditorSettings(openInlineLink: true, debug: true)
        let settings = AppSettings(editor: editorSettings)

        let validated = settings.validated()

        #expect(validated.id == settings.id)
        // Editor settings should be validated (though current validation just returns same)
        #expect(validated.editor?.openInlineLink == true)
        #expect(validated.editor?.debug == true)
    }

    @Test("Validated preserves ID")
    func testValidatedPreservesID() {
        let customID = UUID()
        let settings = AppSettings(id: customID, editor: .default)

        let validated = settings.validated()

        #expect(validated.id == customID)
    }

    @Test("Editor property can be modified")
    func testEditorPropertyModification() {
        let settings = AppSettings.default
        let newEditor = EditorSettings(openInlineLink: true, debug: true)

        settings.editor = newEditor

        #expect(settings.editor?.openInlineLink == true)
        #expect(settings.editor?.debug == true)
    }

    @Test("Multiple default instances have same singleton ID")
    func testMultipleDefaultsSameSingletonID() {
        let defaults = (0..<10).map { _ in AppSettings.default }

        for settings in defaults {
            #expect(settings.id == AppSettings.singletonID)
        }
    }
}

@Suite("AppSettings Validation Tests")
struct AppSettingsValidationTests {

    @Test("Validation with valid editor settings")
    func testValidationWithValidEditor() {
        let editorSettings = EditorSettings(openInlineLink: false, debug: false)
        let settings = AppSettings(editor: editorSettings)

        let validated = settings.validated()

        #expect(validated.editor?.openInlineLink == false)
        #expect(validated.editor?.debug == false)
    }

    @Test("Validation preserves editor settings")
    func testValidationPreservesSettings() {
        let editorSettings = EditorSettings(openInlineLink: true, debug: true)
        let settings = AppSettings(editor: editorSettings)

        let validated = settings.validated()

        // Should preserve values (current validation doesn't change boolean settings)
        #expect(validated.editor?.openInlineLink == true)
        #expect(validated.editor?.debug == true)
    }

    @Test("Validation with all boolean combinations")
    func testValidationAllCombinations() {
        let combinations = [
            (openInlineLink: false, debug: false),
            (openInlineLink: false, debug: true),
            (openInlineLink: true, debug: false),
            (openInlineLink: true, debug: true)
        ]

        for (openInlineLink, debug) in combinations {
            let editorSettings = EditorSettings(openInlineLink: openInlineLink, debug: debug)
            let settings = AppSettings(editor: editorSettings)

            let validated = settings.validated()

            #expect(validated.editor?.openInlineLink == openInlineLink)
            #expect(validated.editor?.debug == debug)
        }
    }
}

@MainActor
@Suite("AppSettings MainActor Tests")
struct AppSettingsMainActorTests {

    @Test("applyValidation preserves editor settings")
    func testApplyValidation() async {
        let editorSettings = EditorSettings(openInlineLink: true, debug: true)
        let settings = AppSettings(editor: editorSettings)

        settings.applyValidation()

        // Editor should be validated (but values unchanged for boolean properties)
        #expect(settings.editor?.openInlineLink == true)
        #expect(settings.editor?.debug == true)
    }

    @Test("applyValidation with default settings")
    func testApplyValidationWithDefaultSettings() async {
        let settings = AppSettings.default
        let originalOpenInlineLink = settings.editor?.openInlineLink
        let originalDebug = settings.editor?.debug

        settings.applyValidation()

        // Should remain unchanged
        #expect(settings.editor?.openInlineLink == originalOpenInlineLink)
        #expect(settings.editor?.debug == originalDebug)
    }

    @Test("applyValidation multiple times is idempotent")
    func testApplyValidationIdempotent() async {
        let settings = AppSettings(editor: EditorSettings(openInlineLink: true, debug: false))

        settings.applyValidation()
        let afterFirst = settings.editor

        settings.applyValidation()
        let afterSecond = settings.editor

        // Should be identical after multiple validations
        #expect(afterFirst?.openInlineLink == afterSecond?.openInlineLink)
        #expect(afterFirst?.debug == afterSecond?.debug)
    }
}
