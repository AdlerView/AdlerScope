//
//  MockMarkdownParserRepository.swift
//  AdlerScopeTests
//
//  Centralized mock implementation of MarkdownParserRepository for testing
//  Combines features from all mock variants with comprehensive call tracking and flexible configuration
//

import Foundation
import Markdown
@testable import AdlerScope

/// Centralized mock implementation of MarkdownParserRepository
/// Provides flexible configuration for all test scenarios
@MainActor
final class MockMarkdownParserRepository: MarkdownParserRepository, @unchecked Sendable {

    // MARK: - Test Data

    /// Document to return from parse operations (if set)
    var resultDocument: Document?

    /// Complexity value to return from estimateComplexity operations
    var mockComplexity: Int = 100

    /// Whether validate should return true (default) or false
    var validationResult: Bool = true

    // MARK: - Result Configuration (takes precedence over direct properties)

    /// Result configuration for parse operations
    var parseResult: Result<Document, Error>?

    // MARK: - Direct Error Configuration (legacy compatibility)

    /// Boolean flag to throw error from parse operations (ignored if parseResult is set)
    var shouldThrowError: Bool = false

    /// Optional error to throw from parse operations (ignored if parseResult is set)
    var error: Error?

    // MARK: - Call Tracking

    /// Number of times parse was called
    var parseCallCount = 0

    /// Number of times validate was called
    var validateCallCount = 0

    /// Number of times estimateComplexity was called
    var estimateComplexityCallCount = 0

    // MARK: - Parameter Tracking

    /// Last markdown string passed to parse
    var lastParsedMarkdown: String?

    /// Last markdown string passed to validate
    var lastValidatedMarkdown: String?

    /// Last markdown string passed to estimateComplexity
    var lastComplexityMarkdown: String?

    // MARK: - Repository Methods

    func parse(_ markdown: String) async throws -> Document {
        parseCallCount += 1
        lastParsedMarkdown = markdown

        // Check result configuration first
        if let result = parseResult {
            switch result {
            case .success(let document):
                return document
            case .failure(let error):
                throw error
            }
        }

        // Check error configuration
        if shouldThrowError {
            throw error ?? ParseError.invalidSyntax(line: 1, message: "Mock parse error")
        }

        // Return configured document or parse the markdown
        if let document = resultDocument {
            return document
        }

        return Document(parsing: markdown)
    }

    func validate(_ markdown: String) async -> Bool {
        validateCallCount += 1
        lastValidatedMarkdown = markdown
        return validationResult
    }

    func estimateComplexity(_ markdown: String) async -> Int {
        estimateComplexityCallCount += 1
        lastComplexityMarkdown = markdown
        return mockComplexity
    }

    // MARK: - Test Helpers

    /// Reset only call counts and parameter tracking (preserves configuration)
    func resetTracking() {
        parseCallCount = 0
        validateCallCount = 0
        estimateComplexityCallCount = 0

        lastParsedMarkdown = nil
        lastValidatedMarkdown = nil
        lastComplexityMarkdown = nil
    }

    /// Reset all state including configuration
    func reset() {
        resetTracking()

        // Reset results
        resultDocument = nil
        mockComplexity = 100
        validationResult = true

        // Reset result configurations
        parseResult = nil

        // Reset error configurations
        shouldThrowError = false
        error = nil
    }
}

// MARK: - Factory Methods

extension MockMarkdownParserRepository {

    /// Create a mock that successfully parses markdown
    /// - Returns: Configured mock repository
    static func withSuccessfulParsing() -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        mock.validationResult = true
        return mock
    }

    /// Create a mock with a specific result document
    /// - Parameter document: Document to return from parse operations
    /// - Returns: Configured mock repository
    static func withDocument(_ document: Document) -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        mock.resultDocument = document
        return mock
    }

    /// Create a mock where parse operations fail
    /// - Parameter error: Error to throw (default: generic ParseError)
    /// - Returns: Configured mock repository
    static func withParseError(_ error: Error = ParseError.invalidSyntax(line: 1, message: "Mock parse error")) -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        mock.shouldThrowError = true
        mock.error = error
        return mock
    }

    /// Create a mock with specific complexity
    /// - Parameter complexity: Complexity value to return
    /// - Returns: Configured mock repository
    static func withComplexity(_ complexity: Int) -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        mock.mockComplexity = complexity
        return mock
    }

    /// Create a mock that fails validation
    /// - Returns: Configured mock repository
    static func withFailedValidation() -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        mock.validationResult = false
        return mock
    }

    /// Create a custom configured mock
    /// - Parameter configure: Configuration closure
    /// - Returns: Configured mock repository
    static func with(_ configure: (MockMarkdownParserRepository) -> Void) -> MockMarkdownParserRepository {
        let mock = MockMarkdownParserRepository()
        configure(mock)
        return mock
    }
}
