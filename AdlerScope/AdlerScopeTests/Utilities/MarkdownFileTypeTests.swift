//
//  MarkdownFileTypeTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for MarkdownFileType functionality
//

import Testing
import Foundation
import UniformTypeIdentifiers
@testable import AdlerScope

@Suite("UTType Extensions Tests")
struct UTTypeExtensionsTests {

    @Test("markdown UTType exists")
    func testMarkdownType() {
        let markdownType = UTType.markdown

        // UTType is a struct, so just verify it exists and has an identifier
        #expect(!markdownType.identifier.isEmpty)
    }

    @Test("rMarkdown UTType exists")
    func testRMarkdownType() {
        let rMarkdownType = UTType.rMarkdown

        // UTType is a struct, so just verify it exists and has an identifier
        #expect(!rMarkdownType.identifier.isEmpty)
    }

    @Test("quarto UTType exists")
    func testQuartoType() {
        let quartoType = UTType.quarto

        // UTType is a struct, so just verify it exists and has an identifier
        #expect(!quartoType.identifier.isEmpty)
    }

    @Test("markdown type has correct identifier")
    func testMarkdownTypeIdentifier() {
        let markdownType = UTType.markdown

        // Should have a valid identifier
        #expect(!markdownType.identifier.isEmpty)
    }
}

@Suite("MarkdownFileType Tests")
struct MarkdownFileTypeTests {

    @Test("allowedTypes contains expected types")
    func testAllowedTypes() {
        let allowedTypes = MarkdownFileType.allowedTypes

        #expect(allowedTypes.count == 4)
        #expect(allowedTypes.contains(.plainText))
        #expect(allowedTypes.contains(.markdown))
        #expect(allowedTypes.contains(.rMarkdown))
        #expect(allowedTypes.contains(.quarto))
    }

    @Test("markdown property returns markdown type")
    func testMarkdownProperty() {
        let markdownType = MarkdownFileType.markdown

        #expect(markdownType == UTType.markdown)
    }

    @Test("isMarkdownFile with .md extension")
    func testIsMarkdownFileMD() {
        let url = URL(fileURLWithPath: "/path/to/document.md")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with .markdown extension")
    func testIsMarkdownFileMarkdown() {
        let url = URL(fileURLWithPath: "/path/to/document.markdown")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with .txt extension")
    func testIsMarkdownFileTxt() {
        let url = URL(fileURLWithPath: "/path/to/document.txt")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with .rmd extension")
    func testIsMarkdownFileRmd() {
        let url = URL(fileURLWithPath: "/path/to/document.rmd")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with .qmd extension")
    func testIsMarkdownFileQmd() {
        let url = URL(fileURLWithPath: "/path/to/document.qmd")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with uppercase extension")
    func testIsMarkdownFileUppercase() {
        let url = URL(fileURLWithPath: "/path/to/document.MD")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with mixed case extension")
    func testIsMarkdownFileMixedCase() {
        let url = URL(fileURLWithPath: "/path/to/document.Md")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }

    @Test("isMarkdownFile with invalid extension returns false")
    func testIsMarkdownFileInvalid() {
        let url = URL(fileURLWithPath: "/path/to/document.pdf")

        #expect(MarkdownFileType.isMarkdownFile(url) == false)
    }

    @Test("isMarkdownFile with no extension returns false")
    func testIsMarkdownFileNoExtension() {
        let url = URL(fileURLWithPath: "/path/to/document")

        #expect(MarkdownFileType.isMarkdownFile(url) == false)
    }
}

@Suite("MarkdownFileType Display Name Tests")
struct MarkdownFileTypeDisplayNameTests {

    @Test("displayName for .md extension")
    func testDisplayNameMD() {
        let url = URL(fileURLWithPath: "/path/to/file.md")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Markdown")
    }

    @Test("displayName for .markdown extension")
    func testDisplayNameMarkdown() {
        let url = URL(fileURLWithPath: "/path/to/file.markdown")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Markdown")
    }

    @Test("displayName for .rmd extension")
    func testDisplayNameRmd() {
        let url = URL(fileURLWithPath: "/path/to/file.rmd")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "R Markdown")
    }

    @Test("displayName for .qmd extension")
    func testDisplayNameQmd() {
        let url = URL(fileURLWithPath: "/path/to/file.qmd")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Quarto Markdown")
    }

    @Test("displayName for .txt extension")
    func testDisplayNameTxt() {
        let url = URL(fileURLWithPath: "/path/to/file.txt")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Plain Text")
    }

    @Test("displayName for uppercase extension")
    func testDisplayNameUppercase() {
        let url = URL(fileURLWithPath: "/path/to/file.MD")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Markdown")
    }

    @Test("displayName for unknown extension")
    func testDisplayNameUnknown() {
        let url = URL(fileURLWithPath: "/path/to/file.pdf")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Document")
    }

    @Test("displayName for no extension")
    func testDisplayNameNoExtension() {
        let url = URL(fileURLWithPath: "/path/to/file")
        let displayName = MarkdownFileType.displayName(for: url)

        #expect(displayName == "Document")
    }
}

@Suite("MarkdownFileType Edge Cases")
struct MarkdownFileTypeEdgeCaseTests {

    @Test("isMarkdownFile with various path formats")
    func testIsMarkdownFileVariousPaths() {
        let paths = [
            "/file.md",
            "/path/to/file.md",
            "/path with spaces/file.md",
            "/path/with/unicode/文件.md",
            "/path/with.dots/in.path/file.md"
        ]

        for path in paths {
            let url = URL(fileURLWithPath: path)
            #expect(MarkdownFileType.isMarkdownFile(url) == true)
        }
    }

    @Test("displayName with various path formats")
    func testDisplayNameVariousPaths() {
        let paths = [
            "/file.md",
            "/path/to/file.md",
            "/path with spaces/file.md",
            "/path/with/unicode/文件.md"
        ]

        for path in paths {
            let url = URL(fileURLWithPath: path)
            let displayName = MarkdownFileType.displayName(for: url)
            #expect(displayName == "Markdown")
        }
    }

    @Test("isMarkdownFile with all supported extensions")
    func testIsMarkdownFileAllSupportedExtensions() {
        let extensions = ["md", "markdown", "txt", "rmd", "qmd"]

        for ext in extensions {
            let url = URL(fileURLWithPath: "/path/to/file.\(ext)")
            #expect(MarkdownFileType.isMarkdownFile(url) == true)
        }
    }

    @Test("displayName for all supported markdown types")
    func testDisplayNameAllMarkdownTypes() {
        let expectations: [(String, String)] = [
            ("md", "Markdown"),
            ("markdown", "Markdown"),
            ("rmd", "R Markdown"),
            ("qmd", "Quarto Markdown"),
            ("txt", "Plain Text")
        ]

        for (ext, expectedName) in expectations {
            let url = URL(fileURLWithPath: "/file.\(ext)")
            let displayName = MarkdownFileType.displayName(for: url)
            #expect(displayName == expectedName)
        }
    }

    @Test("isMarkdownFile with empty filename")
    func testIsMarkdownFileEmptyFilename() {
        // A file named ".md" is a hidden file with no extension
        // The ".md" is the filename, not an extension
        let url = URL(fileURLWithPath: "/.md")

        #expect(MarkdownFileType.isMarkdownFile(url) == false)
    }

    @Test("isMarkdownFile with multiple dots in filename")
    func testIsMarkdownFileMultipleDots() {
        let url = URL(fileURLWithPath: "/file.name.with.dots.md")

        #expect(MarkdownFileType.isMarkdownFile(url) == true)
    }
}

@Suite("MarkdownFileType Integration Tests")
struct MarkdownFileTypeIntegrationTests {

    @Test("Workflow: Check if markdown file and get display name")
    func testWorkflow() {
        let url = URL(fileURLWithPath: "/path/to/document.md")

        let isMarkdown = MarkdownFileType.isMarkdownFile(url)
        #expect(isMarkdown == true)

        let displayName = MarkdownFileType.displayName(for: url)
        #expect(displayName == "Markdown")
    }

    @Test("Workflow: Reject non-markdown file")
    func testWorkflowRejectNonMarkdown() {
        let url = URL(fileURLWithPath: "/path/to/document.pdf")

        let isMarkdown = MarkdownFileType.isMarkdownFile(url)
        #expect(isMarkdown == false)

        let displayName = MarkdownFileType.displayName(for: url)
        #expect(displayName == "Document")
    }

    @Test("allowedTypes can be used for file selection")
    func testAllowedTypesForFileSelection() {
        let types = MarkdownFileType.allowedTypes

        #expect(!types.isEmpty)
        #expect(types.allSatisfy { !$0.identifier.isEmpty })
    }
}
