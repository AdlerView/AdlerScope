//
//  DocumentLoadErrorTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for DocumentLoadError functionality
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("DocumentLoadError Tests")
struct DocumentLoadErrorTests {

    @Test("fileNotAccessible error description")
    func testFileNotAccessibleDescription() {
        let url = URL(fileURLWithPath: "/path/to/document.txt")
        let error = DocumentLoadError.fileNotAccessible(url)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("document.txt") == true)
        #expect(description?.contains("Cannot access file") == true)
    }

    @Test("fileNotAccessible failure reason")
    func testFileNotAccessibleFailureReason() {
        let url = URL(fileURLWithPath: "/path/to/document.txt")
        let error = DocumentLoadError.fileNotAccessible(url)

        let reason = error.failureReason
        #expect(reason != nil)
        #expect(reason?.contains("/path/to/document.txt") == true)
        #expect(reason?.contains("could not be accessed") == true)
    }

    @Test("fileNotAccessible recovery suggestion")
    func testFileNotAccessibleRecoverySuggestion() {
        let url = URL(fileURLWithPath: "/path/to/document.txt")
        let error = DocumentLoadError.fileNotAccessible(url)

        let suggestion = error.recoverySuggestion
        #expect(suggestion != nil)
        #expect(suggestion?.contains("permission") == true)
    }

    @Test("encodingFailed error description")
    func testEncodingFailedDescription() {
        let error = DocumentLoadError.encodingFailed

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("UTF-8") == true)
        #expect(description?.contains("encode") == true)
    }

    @Test("encodingFailed failure reason")
    func testEncodingFailedFailureReason() {
        let error = DocumentLoadError.encodingFailed

        let reason = error.failureReason
        #expect(reason != nil)
        #expect(reason?.contains("UTF-8") == true)
        #expect(reason?.contains("characters") == true)
    }

    @Test("encodingFailed recovery suggestion")
    func testEncodingFailedRecoverySuggestion() {
        let error = DocumentLoadError.encodingFailed

        let suggestion = error.recoverySuggestion
        #expect(suggestion != nil)
        #expect(suggestion?.contains("different editor") == true)
    }

    @Test("bookmarkResolutionFailed error description")
    func testBookmarkResolutionFailedDescription() {
        let error = DocumentLoadError.bookmarkResolutionFailed

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("bookmark") == true)
        #expect(description?.contains("Security-scoped") == true)
    }

    @Test("bookmarkResolutionFailed failure reason")
    func testBookmarkResolutionFailedFailureReason() {
        let error = DocumentLoadError.bookmarkResolutionFailed

        let reason = error.failureReason
        #expect(reason != nil)
        #expect(reason?.contains("security bookmark") == true)
        #expect(reason?.contains("no longer valid") == true)
    }

    @Test("bookmarkResolutionFailed recovery suggestion")
    func testBookmarkResolutionFailedRecoverySuggestion() {
        let error = DocumentLoadError.bookmarkResolutionFailed

        let suggestion = error.recoverySuggestion
        #expect(suggestion != nil)
        #expect(suggestion?.contains("Remove") == true)
        #expect(suggestion?.contains("recents") == true)
    }

    @Test("saveFailed error description")
    func testSaveFailedDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = DocumentLoadError.saveFailed(underlyingError)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("save") == true)
    }

    @Test("saveFailed failure reason includes underlying error")
    func testSaveFailedFailureReason() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Disk full"]
        )
        let error = DocumentLoadError.saveFailed(underlyingError)

        let reason = error.failureReason
        #expect(reason != nil)
        #expect(reason?.contains("Save operation failed") == true)
        #expect(reason?.contains("Disk full") == true)
    }

    @Test("saveFailed recovery suggestion")
    func testSaveFailedRecoverySuggestion() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = DocumentLoadError.saveFailed(underlyingError)

        let suggestion = error.recoverySuggestion
        #expect(suggestion != nil)
        #expect(suggestion?.contains("different location") == true)
        #expect(suggestion?.contains("disk space") == true)
    }

    @Test("unknown error description")
    func testUnknownDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = DocumentLoadError.unknown(underlyingError)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("unexpected") == true)
    }

    @Test("unknown failure reason includes underlying error")
    func testUnknownFailureReason() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Something went wrong"]
        )
        let error = DocumentLoadError.unknown(underlyingError)

        let reason = error.failureReason
        #expect(reason != nil)
        #expect(reason?.contains("Something went wrong") == true)
    }

    @Test("unknown recovery suggestion")
    func testUnknownRecoverySuggestion() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = DocumentLoadError.unknown(underlyingError)

        let suggestion = error.recoverySuggestion
        #expect(suggestion != nil)
        #expect(suggestion?.contains("try again") == true)
    }
}

@Suite("DocumentLoadError Edge Cases")
struct DocumentLoadErrorEdgeCaseTests {

    @Test("fileNotAccessible with various URL types")
    func testFileNotAccessibleVariousURLs() {
        let urls = [
            URL(fileURLWithPath: "/"),
            URL(fileURLWithPath: "/path/with spaces/file.txt"),
            URL(fileURLWithPath: "/path/with/unicode/文件.txt"),
            URL(fileURLWithPath: "/very/long/path/that/goes/deep/into/filesystem/structure/file.txt")
        ]

        for url in urls {
            let error = DocumentLoadError.fileNotAccessible(url)
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }

    @Test("saveFailed with various underlying errors")
    func testSaveFailedVariousErrors() {
        struct CustomError: Error {}
        let errors: [Error] = [
            NSError(domain: "TestDomain", code: 1, userInfo: nil),
            CustomError(),
            URLError(.cannotWriteToFile)
        ]

        for underlyingError in errors {
            let error = DocumentLoadError.saveFailed(underlyingError)
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }

    @Test("unknown with various underlying errors")
    func testUnknownVariousErrors() {
        struct CustomError: Error {}
        let errors: [Error] = [
            NSError(domain: "TestDomain", code: 1, userInfo: nil),
            CustomError(),
            URLError(.unknown)
        ]

        for underlyingError in errors {
            let error = DocumentLoadError.unknown(underlyingError)
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }
}

@Suite("DocumentLoadError LocalizedError Conformance")
struct DocumentLoadErrorLocalizedErrorTests {

    @Test("All cases provide error description")
    func testAllCasesProvideErrorDescription() {
        let url = URL(fileURLWithPath: "/test.txt")
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)

        let errors: [DocumentLoadError] = [
            .fileNotAccessible(url),
            .encodingFailed,
            .bookmarkResolutionFailed,
            .saveFailed(underlyingError),
            .unknown(underlyingError)
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test("All cases provide failure reason")
    func testAllCasesProvideFailureReason() {
        let url = URL(fileURLWithPath: "/test.txt")
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)

        let errors: [DocumentLoadError] = [
            .fileNotAccessible(url),
            .encodingFailed,
            .bookmarkResolutionFailed,
            .saveFailed(underlyingError),
            .unknown(underlyingError)
        ]

        for error in errors {
            #expect(error.failureReason != nil)
            #expect(error.failureReason?.isEmpty == false)
        }
    }

    @Test("All cases provide recovery suggestion")
    func testAllCasesProvideRecoverySuggestion() {
        let url = URL(fileURLWithPath: "/test.txt")
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)

        let errors: [DocumentLoadError] = [
            .fileNotAccessible(url),
            .encodingFailed,
            .bookmarkResolutionFailed,
            .saveFailed(underlyingError),
            .unknown(underlyingError)
        ]

        for error in errors {
            #expect(error.recoverySuggestion != nil)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }

    @Test("DocumentLoadError conforms to Error protocol")
    func testErrorProtocolConformance() {
        let error: Error = DocumentLoadError.encodingFailed
        #expect(error is DocumentLoadError)
    }
}
