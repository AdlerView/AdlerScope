//
//  ParseErrorTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for ParseError
//

import Testing
@testable import AdlerScope

@Suite("ParseError Tests")
struct ParseErrorTests {

    @Test("Invalid syntax error with line number")
    func testInvalidSyntaxWithLine() {
        // Arrange & Act
        let error = ParseError.invalidSyntax(line: 42, message: "Unexpected character")

        // Assert
        #expect(error.localizedDescription.contains("line 42"))
        #expect(error.localizedDescription.contains("Unexpected character"))
    }

    @Test("Invalid syntax error without line number")
    func testInvalidSyntaxWithoutLine() {
        // Arrange & Act
        let error = ParseError.invalidSyntax(line: nil, message: "Generic error")

        // Assert
        #expect(error.localizedDescription.contains("Syntax error"))
        #expect(error.localizedDescription.contains("Generic error"))
        #expect(!error.localizedDescription.contains("line"))
    }

    @Test("Parser internal error")
    func testParserInternalError() {
        // Arrange & Act
        let error = ParseError.parserInternalError("Memory corruption")

        // Assert
        #expect(error.localizedDescription.contains("Parser error"))
        #expect(error.localizedDescription.contains("Memory corruption"))
    }

    @Test("Timeout error")
    func testTimeoutError() {
        // Arrange & Act
        let error = ParseError.timeout(estimatedTime: 5000)

        // Assert
        #expect(error.localizedDescription.contains("timed out"))
        #expect(error.localizedDescription.contains("5000"))
    }

    @Test("Unsupported extension error")
    func testUnsupportedExtension() {
        // Arrange & Act
        let error = ParseError.unsupportedExtension("CustomExtension")

        // Assert
        #expect(error.localizedDescription.contains("Unsupported"))
        #expect(error.localizedDescription.contains("CustomExtension"))
    }

    @Test("Empty input error")
    func testEmptyInput() {
        // Arrange & Act
        let error = ParseError.emptyInput

        // Assert
        #expect(error.localizedDescription.contains("empty"))
    }

    @Test("Complexity limit exceeded error")
    func testComplexityLimitExceeded() {
        // Arrange & Act
        let error = ParseError.complexityLimitExceeded(complexity: 10000, limit: 5000)

        // Assert
        #expect(error.localizedDescription.contains("10000"))
        #expect(error.localizedDescription.contains("5000"))
        #expect(error.localizedDescription.contains("exceeds"))
    }

    @Test("Invalid YAML front matter error")
    func testInvalidYAMLFrontMatter() {
        // Arrange & Act
        let error = ParseError.invalidYAMLFrontMatter("Malformed key")

        // Assert
        #expect(error.localizedDescription.contains("YAML"))
        #expect(error.localizedDescription.contains("Malformed key"))
    }

    @Test("Invalid math syntax error with line")
    func testInvalidMathSyntaxWithLine() {
        // Arrange & Act
        let error = ParseError.invalidMathSyntax(line: 10, message: "Unclosed bracket")

        // Assert
        #expect(error.localizedDescription.contains("line 10"))
        #expect(error.localizedDescription.contains("Unclosed bracket"))
    }

    @Test("Invalid math syntax error without line")
    func testInvalidMathSyntaxWithoutLine() {
        // Arrange & Act
        let error = ParseError.invalidMathSyntax(line: nil, message: "Invalid LaTeX")

        // Assert
        #expect(error.localizedDescription.contains("Math syntax error"))
        #expect(!error.localizedDescription.contains("line"))
    }

    @Test("Invalid settings error")
    func testInvalidSettings() {
        // Arrange & Act
        let error = ParseError.invalidSettings("Conflicting options")

        // Assert
        #expect(error.localizedDescription.contains("Invalid parser settings"))
        #expect(error.localizedDescription.contains("Conflicting options"))
    }

    @Test("Conflicting options error")
    func testConflictingOptions() {
        // Arrange & Act
        let error = ParseError.conflictingOptions("Option A and Option B are mutually exclusive")

        // Assert
        #expect(error.localizedDescription.contains("Conflicting"))
        #expect(error.localizedDescription.contains("mutually exclusive"))
    }

    @Test("Error equality with simple cases")
    func testErrorEqualitySimple() {
        // Arrange
        let error1 = ParseError.emptyInput
        let error2 = ParseError.emptyInput
        let error3 = ParseError.parserInternalError("test")

        // Assert
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Error equality with associated values - same values")
    func testErrorEqualitySameValues() {
        // Arrange - invalidSyntax with same values
        let error1 = ParseError.invalidSyntax(line: 42, message: "Unexpected character")
        let error2 = ParseError.invalidSyntax(line: 42, message: "Unexpected character")
        #expect(error1 == error2)

        // Arrange - timeout with same values
        let error3 = ParseError.timeout(estimatedTime: 5000)
        let error4 = ParseError.timeout(estimatedTime: 5000)
        #expect(error3 == error4)

        // Arrange - complexityLimitExceeded with same values
        let error5 = ParseError.complexityLimitExceeded(complexity: 10000, limit: 5000)
        let error6 = ParseError.complexityLimitExceeded(complexity: 10000, limit: 5000)
        #expect(error5 == error6)
    }

    @Test("Error equality with associated values - different values")
    func testErrorEqualityDifferentValues() {
        // Arrange - different line numbers
        let error1 = ParseError.invalidSyntax(line: 42, message: "Error A")
        let error2 = ParseError.invalidSyntax(line: 43, message: "Error A")
        #expect(error1 != error2)

        // Arrange - different messages
        let error3 = ParseError.invalidSyntax(line: 42, message: "Error A")
        let error4 = ParseError.invalidSyntax(line: 42, message: "Error B")
        #expect(error3 != error4)

        // Arrange - different timeout values
        let error5 = ParseError.timeout(estimatedTime: 5000)
        let error6 = ParseError.timeout(estimatedTime: 6000)
        #expect(error5 != error6)

        // Arrange - different complexity values
        let error7 = ParseError.complexityLimitExceeded(complexity: 10000, limit: 5000)
        let error8 = ParseError.complexityLimitExceeded(complexity: 20000, limit: 5000)
        #expect(error7 != error8)
    }

    @Test("Error equality with optional line numbers")
    func testErrorEqualityOptionalLines() {
        // Arrange - invalidSyntax: line vs nil
        let error1 = ParseError.invalidSyntax(line: 42, message: "Error")
        let error2 = ParseError.invalidSyntax(line: nil, message: "Error")
        #expect(error1 != error2)

        // Arrange - invalidMathSyntax: line vs nil
        let error3 = ParseError.invalidMathSyntax(line: 10, message: "Math error")
        let error4 = ParseError.invalidMathSyntax(line: nil, message: "Math error")
        #expect(error3 != error4)

        // Arrange - both nil
        let error5 = ParseError.invalidSyntax(line: nil, message: "Error")
        let error6 = ParseError.invalidSyntax(line: nil, message: "Error")
        #expect(error5 == error6)
    }
}
