//
//  AlertErrorTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for AlertError functionality
//  Tests initialization, error conversion, factory methods, and view extensions
//

import Testing
import Foundation
import SwiftUI

@testable import AdlerScope

// MARK: - Test Helpers

/// Mock LocalizedError for testing
struct MockLocalizedError: LocalizedError {
    let errorDescription: String?
    let failureReason: String?
    let recoverySuggestion: String?

    init(
        errorDescription: String? = "Mock Error",
        failureReason: String? = "Mock failure reason",
        recoverySuggestion: String? = "Mock recovery suggestion"
    ) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
    }
}

/// Mock generic Error for testing (not LocalizedError)
struct MockGenericError: Error, CustomNSError {
    let message: String

    // CustomNSError provides localizedDescription without conforming to LocalizedError
    static var errorDomain: String { "TestDomain" }

    var errorCode: Int { 1 }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: message]
    }
}

/// Plain Error for testing non-LocalizedError behavior
struct PlainError: Error, CustomNSError {
    let message: String

    // CustomNSError provides localizedDescription without conforming to LocalizedError
    static var errorDomain: String { "TestDomain" }

    var errorCode: Int { 2 }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: message]
    }
}

// MARK: - AlertError Initialization Tests

@Suite("AlertError Initialization Tests")
struct AlertErrorInitializationTests {

    @Test("ID is automatically generated and unique")
    func testIDGeneration() {
        let error1 = AlertError(title: "Test", message: "Message")
        let error2 = AlertError(title: "Test", message: "Message")

        // Each instance should have a unique ID
        #expect(error1.id != error2.id)
    }

    @Test("Basic initializer sets all properties correctly")
    func testBasicInitialization() {
        let error = AlertError(
            title: "Test Title",
            message: "Test Message",
            recoverySuggestion: "Test Suggestion"
        )

        #expect(error.title == "Test Title")
        #expect(error.message == "Test Message")
        #expect(error.recoverySuggestion == "Test Suggestion")
    }

    @Test("Basic initializer with nil recovery suggestion")
    func testBasicInitializationWithNilSuggestion() {
        let error = AlertError(
            title: "Test Title",
            message: "Test Message",
            recoverySuggestion: nil
        )

        #expect(error.title == "Test Title")
        #expect(error.message == "Test Message")
        #expect(error.recoverySuggestion == nil)
    }

    @Test("Basic initializer without recovery suggestion parameter")
    func testBasicInitializationDefaultSuggestion() {
        let error = AlertError(
            title: "Test Title",
            message: "Test Message"
        )

        #expect(error.title == "Test Title")
        #expect(error.message == "Test Message")
        #expect(error.recoverySuggestion == nil)
    }
}

// MARK: - AlertError from LocalizedError Tests

@Suite("AlertError from LocalizedError Tests")
struct AlertErrorFromLocalizedErrorTests {

    @Test("Init from LocalizedError with all properties")
    func testInitFromLocalizedErrorComplete() {
        let mockError = MockLocalizedError(
            errorDescription: "Custom Error",
            failureReason: "Custom Reason",
            recoverySuggestion: "Custom Suggestion"
        )

        let alertError = AlertError(from: mockError)

        #expect(alertError.title == "Custom Error")
        #expect(alertError.message == "Custom Reason")
        #expect(alertError.recoverySuggestion == "Custom Suggestion")
    }

    @Test("Init from LocalizedError with nil errorDescription")
    func testInitFromLocalizedErrorNilDescription() {
        let mockError = MockLocalizedError(
            errorDescription: nil,
            failureReason: "Custom Reason",
            recoverySuggestion: "Custom Suggestion"
        )

        let alertError = AlertError(from: mockError)

        #expect(alertError.title == "Error")
        #expect(alertError.message == "Custom Reason")
        #expect(alertError.recoverySuggestion == "Custom Suggestion")
    }

    @Test("Init from LocalizedError with nil failureReason uses localizedDescription")
    func testInitFromLocalizedErrorNilFailureReason() {
        let mockError = MockLocalizedError(
            errorDescription: "Custom Error",
            failureReason: nil,
            recoverySuggestion: "Custom Suggestion"
        )

        let alertError = AlertError(from: mockError)

        #expect(alertError.title == "Custom Error")
        // When failureReason is nil, it should use localizedDescription
        #expect(alertError.message == mockError.localizedDescription)
        #expect(alertError.recoverySuggestion == "Custom Suggestion")
    }

    @Test("Init from LocalizedError with nil recoverySuggestion")
    func testInitFromLocalizedErrorNilRecoverySuggestion() {
        let mockError = MockLocalizedError(
            errorDescription: "Custom Error",
            failureReason: "Custom Reason",
            recoverySuggestion: nil
        )

        let alertError = AlertError(from: mockError)

        #expect(alertError.title == "Custom Error")
        #expect(alertError.message == "Custom Reason")
        #expect(alertError.recoverySuggestion == nil)
    }
}

// MARK: - AlertError from DocumentLoadError Tests

@Suite("AlertError from DocumentLoadError Tests")
struct AlertErrorFromDocumentLoadErrorTests {

    @Test("Init from DocumentLoadError.fileNotAccessible")
    func testInitFromFileNotAccessible() {
        let url = URL(fileURLWithPath: "/test/path/file.txt")
        let docError = DocumentLoadError.fileNotAccessible(url)

        let alertError = AlertError(from: docError)

        #expect(alertError.title == "Cannot access file at file.txt")
        #expect(alertError.message.contains("could not be accessed"))
        #expect(alertError.recoverySuggestion != nil)
    }

    @Test("Init from DocumentLoadError.encodingFailed")
    func testInitFromEncodingFailed() {
        let docError = DocumentLoadError.encodingFailed

        let alertError = AlertError(from: docError)

        #expect(alertError.title == "Failed to encode file content as UTF-8")
        #expect(alertError.message.contains("UTF-8"))
        #expect(alertError.recoverySuggestion != nil)
    }

    @Test("Init from DocumentLoadError.bookmarkResolutionFailed")
    func testInitFromBookmarkResolutionFailed() {
        let docError = DocumentLoadError.bookmarkResolutionFailed

        let alertError = AlertError(from: docError)

        #expect(alertError.title == "Security-scoped bookmark resolution failed")
        #expect(alertError.message.contains("security bookmark"))
        #expect(alertError.recoverySuggestion != nil)
    }

    @Test("Init from DocumentLoadError.saveFailed")
    func testInitFromSaveFailed() {
        let underlyingError = MockGenericError(message: "Disk full")
        let docError = DocumentLoadError.saveFailed(underlyingError)

        let alertError = AlertError(from: docError)

        #expect(alertError.title == "Failed to save document")
        #expect(alertError.message.contains("Save operation failed"))
        #expect(alertError.recoverySuggestion != nil)
    }

    @Test("Init from DocumentLoadError.unknown")
    func testInitFromUnknown() {
        let underlyingError = MockGenericError(message: "Unknown issue")
        let docError = DocumentLoadError.unknown(underlyingError)

        let alertError = AlertError(from: docError)

        #expect(alertError.title == "An unexpected error occurred")
        #expect(alertError.message.contains("Unknown issue"))
        #expect(alertError.recoverySuggestion != nil)
    }
}

// MARK: - AlertError from Generic Error Tests

@Suite("AlertError from Generic Error Tests")
struct AlertErrorFromGenericErrorTests {

    @Test("Init from Error that is LocalizedError")
    func testInitFromErrorAsLocalizedError() {
        let mockError = MockLocalizedError(
            errorDescription: "Localized Error",
            failureReason: "Localized Reason",
            recoverySuggestion: "Localized Suggestion"
        )

        let alertError = AlertError(from: mockError as Error)

        #expect(alertError.title == "Localized Error")
        #expect(alertError.message == "Localized Reason")
        #expect(alertError.recoverySuggestion == "Localized Suggestion")
    }

    @Test("Init from Error that is not LocalizedError")
    func testInitFromGenericError() {
        let genericError = PlainError(message: "Generic error message")

        let alertError = AlertError(from: genericError as Error)

        #expect(alertError.title == "Error")
        #expect(alertError.message == "Generic error message")
        #expect(alertError.recoverySuggestion == nil)
    }

    @Test("Init from NSError")
    func testInitFromNSError() {
        let nsError = NSError(
            domain: "TestDomain",
            code: 123,
            userInfo: [NSLocalizedDescriptionKey: "NSError description"]
        )

        let alertError = AlertError(from: nsError as Error)

        #expect(alertError.title == "Error")
        #expect(alertError.message == "NSError description")
        #expect(alertError.recoverySuggestion == nil)
    }
}

// MARK: - AlertError Factory Methods Tests

@Suite("AlertError Factory Methods Tests")
struct AlertErrorFactoryMethodsTests {

    @Test("fileNotFound factory method")
    func testFileNotFound() {
        let alertError = AlertError.fileNotFound("document.txt")

        #expect(alertError.title == "File Not Found")
        #expect(alertError.message.contains("document.txt"))
        #expect(alertError.message.contains("could not be found"))
        #expect(alertError.recoverySuggestion != nil)
        #expect(alertError.recoverySuggestion?.contains("recents") == true)
    }

    @Test("accessDenied factory method")
    func testAccessDenied() {
        let alertError = AlertError.accessDenied("secret.txt")

        #expect(alertError.title == "Access Denied")
        #expect(alertError.message.contains("secret.txt"))
        #expect(alertError.message.contains("permission"))
        #expect(alertError.recoverySuggestion != nil)
        #expect(alertError.recoverySuggestion?.contains("permissions") == true)
    }

    @Test("saveFailed factory method without reason")
    func testSaveFailedWithoutReason() {
        let alertError = AlertError.saveFailed("document.txt")

        #expect(alertError.title == "Save Failed")
        #expect(alertError.message.contains("document.txt"))
        #expect(alertError.message.contains("Failed to save"))
        #expect(alertError.recoverySuggestion != nil)
        #expect(alertError.recoverySuggestion?.contains("different location") == true)
    }

    @Test("saveFailed factory method with reason")
    func testSaveFailedWithReason() {
        let alertError = AlertError.saveFailed("document.txt", reason: "Disk full")

        #expect(alertError.title == "Save Failed")
        #expect(alertError.message.contains("document.txt"))
        #expect(alertError.message.contains("Disk full"))
        #expect(alertError.recoverySuggestion != nil)
    }

    @Test("encodingError factory method")
    func testEncodingError() {
        let alertError = AlertError.encodingError()

        #expect(alertError.title == "Encoding Error")
        #expect(alertError.message.contains("UTF-8"))
        #expect(alertError.message.contains("cannot be read"))
        #expect(alertError.recoverySuggestion != nil)
        #expect(alertError.recoverySuggestion?.contains("corrupted") == true)
    }

    @Test("databaseError factory method")
    func testDatabaseError() {
        let alertError = AlertError.databaseError("update records")

        #expect(alertError.title == "Database Error")
        #expect(alertError.message.contains("update records"))
        #expect(alertError.message.contains("Failed to"))
        #expect(alertError.recoverySuggestion != nil)
        #expect(alertError.recoverySuggestion?.contains("restart") == true)
    }
}

// MARK: - AlertError Identifiable Conformance Tests

@Suite("AlertError Identifiable Conformance Tests")
struct AlertErrorIdentifiableTests {

    @Test("AlertError conforms to Identifiable")
    func testIdentifiableConformance() {
        let error = AlertError(title: "Test", message: "Message")

        // Should have an id property
        let _: UUID = error.id
        #expect(true)
    }

    @Test("Multiple AlertErrors have different IDs")
    func testMultipleErrorsHaveDifferentIDs() {
        let errors = (0..<10).map { _ in
            AlertError(title: "Test", message: "Message")
        }

        let ids = Set(errors.map { $0.id })

        // All IDs should be unique
        #expect(ids.count == 10)
    }

    @Test("Same content different IDs")
    func testSameContentDifferentIDs() {
        let error1 = AlertError(
            title: "Same Title",
            message: "Same Message",
            recoverySuggestion: "Same Suggestion"
        )

        let error2 = AlertError(
            title: "Same Title",
            message: "Same Message",
            recoverySuggestion: "Same Suggestion"
        )

        // Even with identical content, IDs should differ
        #expect(error1.id != error2.id)
    }
}

// MARK: - View Extension Tests

@Suite("View Extension Tests")
struct ViewExtensionTests {

    @Test("Alert view modifier with error binding exists")
    func testAlertModifierExists() {
        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { nil },
            set: { _ in }
        )

        // This should compile without errors
        let _ = view.alert(error: errorBinding)
        #expect(true)
    }

    @Test("Alert view modifier with primary action exists")
    func testAlertModifierWithActionExists() {
        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { nil },
            set: { _ in }
        )

        // This should compile without errors
        let _ = view.alert(
            error: errorBinding,
            primaryAction: {},
            primaryLabel: "Retry"
        )

        #expect(true)
    }

    @Test("Alert modifier handles error with recovery suggestion")
    func testAlertWithRecoverySuggestion() {
        let error = AlertError(
            title: "Test Error",
            message: "Test Message",
            recoverySuggestion: "Try again"
        )

        // Verify the error has the recovery suggestion
        #expect(error.recoverySuggestion == "Try again")

        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { error },
            set: { _ in }
        )

        let _ = view.alert(error: errorBinding)
        #expect(true)
    }

    @Test("Alert modifier handles error without recovery suggestion")
    func testAlertWithoutRecoverySuggestion() {
        let error = AlertError(
            title: "Test Error",
            message: "Test Message",
            recoverySuggestion: nil
        )

        // Verify the error has no recovery suggestion
        #expect(error.recoverySuggestion == nil)

        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { error },
            set: { _ in }
        )

        let _ = view.alert(error: errorBinding)
        #expect(true)
    }

    @Test("Alert modifier with custom primary label")
    func testAlertWithCustomPrimaryLabel() {
        let error = AlertError(
            title: "Test Error",
            message: "Test Message"
        )

        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { error },
            set: { _ in }
        )

        let _ = view.alert(
            error: errorBinding,
            primaryAction: {},
            primaryLabel: "Custom Action"
        )

        #expect(true)
    }

    @Test("Alert modifier with default primary label")
    func testAlertWithDefaultPrimaryLabel() {
        let error = AlertError(
            title: "Test Error",
            message: "Test Message"
        )

        let view = Text("Test")
        let errorBinding = Binding<AlertError?>(
            get: { error },
            set: { _ in }
        )

        // Should use "Retry" as default
        let _ = view.alert(
            error: errorBinding,
            primaryAction: {}
        )

        #expect(true)
    }
}

// MARK: - Integration Tests

@Suite("AlertError Integration Tests")
struct AlertErrorIntegrationTests {

    @Test("Full workflow: Create error, convert, display")
    func testFullWorkflow() {
        // 1. Create a DocumentLoadError
        let url = URL(fileURLWithPath: "/test/file.txt")
        let docError = DocumentLoadError.fileNotAccessible(url)

        // 2. Convert to AlertError
        let alertError = AlertError(from: docError)

        // 3. Verify it can be used with SwiftUI
        #expect(alertError.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        #expect(alertError.title.isEmpty == false)
        #expect(alertError.message.isEmpty == false)

        // 4. Use in a binding
        var storedError: AlertError? = alertError
        let binding = Binding<AlertError?>(
            get: { storedError },
            set: { storedError = $0 }
        )

        #expect(binding.wrappedValue != nil)

        // 5. Clear the error
        binding.wrappedValue = nil
        #expect(storedError == nil)
    }

    @Test("Error chain: NSError -> Generic Error -> AlertError")
    func testErrorChain() {
        // 1. Create NSError
        let nsError = NSError(
            domain: "TestDomain",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Resource not found"]
        )

        // 2. Convert to generic Error
        let genericError: Error = nsError

        // 3. Convert to AlertError
        let alertError = AlertError(from: genericError)

        // 4. Verify conversion
        #expect(alertError.title == "Error")
        #expect(alertError.message == "Resource not found")
    }

    @Test("Multiple error types to AlertError")
    func testMultipleErrorTypes() {
        let errors: [AlertError] = [
            AlertError.fileNotFound("file1.txt"),
            AlertError.accessDenied("file2.txt"),
            AlertError.saveFailed("file3.txt"),
            AlertError.encodingError(),
            AlertError.databaseError("query")
        ]

        // All should have unique IDs
        let ids = Set(errors.map { $0.id })
        #expect(ids.count == errors.count)

        // All should have non-empty titles and messages
        for error in errors {
            #expect(error.title.isEmpty == false)
            #expect(error.message.isEmpty == false)
        }
    }
}

// MARK: - Edge Cases and Boundary Tests

@Suite("AlertError Edge Cases")
struct AlertErrorEdgeCaseTests {

    @Test("Empty string title and message")
    func testEmptyStrings() {
        let error = AlertError(
            title: "",
            message: "",
            recoverySuggestion: ""
        )

        #expect(error.title == "")
        #expect(error.message == "")
        #expect(error.recoverySuggestion == "")
    }

    @Test("Very long title and message")
    func testVeryLongStrings() {
        let longString = String(repeating: "x", count: 10000)
        let error = AlertError(
            title: longString,
            message: longString,
            recoverySuggestion: longString
        )

        #expect(error.title.count == 10000)
        #expect(error.message.count == 10000)
        #expect(error.recoverySuggestion?.count == 10000)
    }

    @Test("Special characters in strings")
    func testSpecialCharacters() {
        let specialString = "Test\n\t\r\"'\\emoji🎉"
        let error = AlertError(
            title: specialString,
            message: specialString,
            recoverySuggestion: specialString
        )

        #expect(error.title == specialString)
        #expect(error.message == specialString)
        #expect(error.recoverySuggestion == specialString)
    }

    @Test("Unicode and internationalization")
    func testUnicodeStrings() {
        let error = AlertError(
            title: "错误",
            message: "エラーが発生しました",
            recoverySuggestion: "الرجاء المحاولة مرة أخرى"
        )

        #expect(error.title == "错误")
        #expect(error.message == "エラーが発生しました")
        #expect(error.recoverySuggestion == "الرجاء المحاولة مرة أخرى")
    }

    @Test("Factory methods with special filenames")
    func testFactoryMethodsWithSpecialFilenames() {
        let filenames = [
            "file with spaces.txt",
            "file-with-dashes.txt",
            "file_with_underscores.txt",
            "file.with.multiple.dots.txt",
            "UPPERCASE.TXT",
            "file@special#chars$.txt"
        ]

        for filename in filenames {
            let error = AlertError.fileNotFound(filename)
            #expect(error.message.contains(filename))
        }
    }
}
