//
//  FileValidatorTests.swift
//  AdlerScopeTests
//
//  Tests for file validation utilities
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("FileValidator Tests")
struct FileValidatorTests {

    @Test("Validates markdown extensions")
    func markdownExtensions() {
        let mdURL = URL(fileURLWithPath: "/test/file.md")
        #expect(FileValidator.isMarkdownFile(mdURL))

        let markdownURL = URL(fileURLWithPath: "/test/file.markdown")
        #expect(FileValidator.isMarkdownFile(markdownURL))

        let rmdURL = URL(fileURLWithPath: "/test/file.rmd")
        #expect(FileValidator.isMarkdownFile(rmdURL))

        let qmdURL = URL(fileURLWithPath: "/test/file.qmd")
        #expect(FileValidator.isMarkdownFile(qmdURL))

        let txtURL = URL(fileURLWithPath: "/test/file.txt")
        #expect(FileValidator.isMarkdownFile(txtURL))
    }

    @Test("Rejects non-markdown extensions")
    func nonMarkdownExtensions() {
        let pdfURL = URL(fileURLWithPath: "/test/file.pdf")
        #expect(!FileValidator.isMarkdownFile(pdfURL))

        let docURL = URL(fileURLWithPath: "/test/file.doc")
        #expect(!FileValidator.isMarkdownFile(docURL))

        let pngURL = URL(fileURLWithPath: "/test/file.png")
        #expect(!FileValidator.isMarkdownFile(pngURL))
    }

    @Test("Case insensitive validation")
    func caseInsensitiveExtensions() {
        let upperURL = URL(fileURLWithPath: "/test/file.MD")
        #expect(FileValidator.isMarkdownFile(upperURL))

        let mixedURL = URL(fileURLWithPath: "/test/file.Markdown")
        #expect(FileValidator.isMarkdownFile(mixedURL))
    }
}
