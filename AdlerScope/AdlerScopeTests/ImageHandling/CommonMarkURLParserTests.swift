//
//  CommonMarkURLParserTests.swift
//  AdlerScopeTests
//
//  Tests for CommonMark-compliant URL parsing
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("CommonMarkURLParser Tests")
struct CommonMarkURLParserTests {

    // MARK: - Angle Bracket Tests

    @Test("Strips angle brackets from URL")
    func angleBrackets() {
        #expect(CommonMarkURLParser.parse("<url>") == "url")
        #expect(CommonMarkURLParser.parse("<https://example.com>") == "https://example.com")
    }

    @Test("Allows spaces inside angle brackets")
    func angleBracketsWithSpaces() {
        #expect(CommonMarkURLParser.parse("<url with spaces>") == "url with spaces")
        #expect(CommonMarkURLParser.parse("</path/to/my file.png>") == "/path/to/my file.png")
    }

    @Test("Handles empty angle brackets")
    func emptyAngleBrackets() {
        #expect(CommonMarkURLParser.parse("<>") == "")
    }

    @Test("Preserves single angle bracket")
    func singleAngleBracket() {
        // Not a valid angle-bracketed form
        #expect(CommonMarkURLParser.parse("<url") == "<url")
        #expect(CommonMarkURLParser.parse("url>") == "url>")
    }

    // MARK: - Backslash Escape Tests

    @Test("Processes backslash-escaped parentheses")
    func escapedParentheses() {
        #expect(CommonMarkURLParser.parse("foo\\)bar") == "foo)bar")
        #expect(CommonMarkURLParser.parse("foo\\(bar") == "foo(bar")
        #expect(CommonMarkURLParser.parse("\\(foo\\)") == "(foo)")
    }

    @Test("Processes backslash-escaped backslash")
    func escapedBackslash() {
        #expect(CommonMarkURLParser.parse("foo\\\\bar") == "foo\\bar")
    }

    @Test("Preserves backslash before non-escapable character")
    func backslashBeforeNonEscapable() {
        // 'a' is not an escapable character
        #expect(CommonMarkURLParser.parse("foo\\abar") == "foo\\abar")
    }

    @Test("Handles trailing backslash")
    func trailingBackslash() {
        #expect(CommonMarkURLParser.parse("foo\\") == "foo\\")
    }

    @Test("Processes multiple escapes")
    func multipleEscapes() {
        #expect(CommonMarkURLParser.parse("a\\(b\\)c\\\\d") == "a(b)c\\d")
    }

    @Test("Escapes all CommonMark punctuation")
    func allEscapablePunctuation() {
        // Test a selection of escapable characters
        #expect(CommonMarkURLParser.parse("\\!") == "!")
        #expect(CommonMarkURLParser.parse("\\\"") == "\"")
        #expect(CommonMarkURLParser.parse("\\#") == "#")
        #expect(CommonMarkURLParser.parse("\\*") == "*")
        #expect(CommonMarkURLParser.parse("\\[") == "[")
        #expect(CommonMarkURLParser.parse("\\]") == "]")
        #expect(CommonMarkURLParser.parse("\\_") == "_")
        #expect(CommonMarkURLParser.parse("\\`") == "`")
    }

    // MARK: - Whitespace Handling

    @Test("Trims leading and trailing whitespace")
    func trimWhitespace() {
        #expect(CommonMarkURLParser.parse("  url  ") == "url")
        #expect(CommonMarkURLParser.parse("\t/path/to/file\t") == "/path/to/file")
    }

    @Test("Preserves internal whitespace in angle-bracketed URLs")
    func internalWhitespace() {
        #expect(CommonMarkURLParser.parse("<my file.png>") == "my file.png")
    }

    // MARK: - Normal URL Preservation

    @Test("Preserves normal URLs unchanged")
    func normalURLs() {
        #expect(CommonMarkURLParser.parse("https://example.com/image.png") == "https://example.com/image.png")
        #expect(CommonMarkURLParser.parse("/path/to/image.png") == "/path/to/image.png")
        #expect(CommonMarkURLParser.parse("./relative/path.png") == "./relative/path.png")
        #expect(CommonMarkURLParser.parse("../parent/path.png") == "../parent/path.png")
        #expect(CommonMarkURLParser.parse("image.png") == "image.png")
    }

    @Test("Preserves URL-encoded sequences")
    func urlEncodedSequences() {
        #expect(CommonMarkURLParser.parse("path%20with%20spaces.png") == "path%20with%20spaces.png")
        #expect(CommonMarkURLParser.parse("file%2Fname.png") == "file%2Fname.png")
    }

    // MARK: - Edge Cases

    @Test("Handles empty string")
    func emptyString() {
        #expect(CommonMarkURLParser.parse("") == "")
    }

    @Test("Handles whitespace-only string")
    func whitespaceOnly() {
        #expect(CommonMarkURLParser.parse("   ") == "")
    }

    @Test("Combined angle brackets and escapes")
    func combinedParsing() {
        #expect(CommonMarkURLParser.parse("<foo\\)bar>") == "foo)bar")
    }

    // MARK: - CommonMark Spec Examples

    @Test("CommonMark spec: angle bracket URL with parenthesis")
    func specAngleBracketWithParen() {
        // From CommonMark spec: [a](<b)c>)
        #expect(CommonMarkURLParser.parse("<b)c>") == "b)c")
    }

    @Test("CommonMark spec: escaped parentheses in URL")
    func specEscapedParens() {
        // From CommonMark spec: [link](\(foo\))
        #expect(CommonMarkURLParser.parse("\\(foo\\)") == "(foo)")
    }

    @Test("CommonMark spec: backslash in URL")
    func specBackslashInURL() {
        // From CommonMark spec: [link](foo\bar)
        // Backslash before non-escapable 'b' is preserved
        #expect(CommonMarkURLParser.parse("foo\\bar") == "foo\\bar")
    }
}
