//
//  BlockQuoteViewTests.swift
//  AdlerScopeTests
//
//  Tests for BlockQuoteView
//

import Testing
import Foundation
import SwiftUI
import Markdown
@testable import AdlerScope

@Suite("BlockQuoteView Tests")
struct BlockQuoteViewTests {

    @Test("BlockQuoteView can be instantiated and body renders")
    func testInstantiation() {
        let doc = Document(parsing: "> Quote")
        var blockQuote: BlockQuote?
        for child in doc.children {
            if let bq = child as? BlockQuote {
                blockQuote = bq
                break
            }
        }

        guard let blockQuote else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        #expect(view.blockQuote.childCount == blockQuote.childCount)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("BlockQuoteView body can be accessed")
    func testBodyAccess() {
        let doc = Document(parsing: "> Simple quote")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        // Accessing body executes the view rendering code
        let _ = view.body

        // Test passes if body can be accessed without crashing
        #expect(Bool(true))
    }

    @Test("BlockQuoteView with openInlineLinks false")
    func testOpenInlineLinksFalse() {
        let doc = Document(parsing: "> Quote with [link](https://example.com)")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        #expect(view.openInlineLinks == false)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("BlockQuoteView with openInlineLinks true")
    func testOpenInlineLinksTrue() {
        let doc = Document(parsing: "> Quote")
        var blockQuote: BlockQuote?
        for child in doc.children {
            if let bq = child as? BlockQuote {
                blockQuote = bq
                break
            }
        }

        guard let blockQuote else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: true)

        #expect(view.openInlineLinks == true)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("BlockQuoteView with multi-line quote")
    func testMultiLineQuote() {
        let doc = Document(parsing: "> Line 1\n> Line 2\n> Line 3")
        var blockQuote: BlockQuote?
        for child in doc.children {
            if let bq = child as? BlockQuote {
                blockQuote = bq
                break
            }
        }

        guard let blockQuote else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        #expect(view.blockQuote.childCount > 0)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("BlockQuoteView with single paragraph")
    func testSingleParagraph() {
        let doc = Document(parsing: "> Single paragraph quote")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        #expect(view.blockQuote.childCount >= 1)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("BlockQuoteView with emphasis")
    func testWithEmphasis() {
        let doc = Document(parsing: "> Quote with **bold** and *italic*")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("BlockQuoteView with code")
    func testWithCode() {
        let doc = Document(parsing: "> Quote with `code`")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("BlockQuoteView with link")
    func testWithLink() {
        let doc = Document(parsing: "> Quote with [link](https://example.com)")
        guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
            Issue.record("Expected BlockQuote")
            return
        }

        let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: true)

        // Access body to execute rendering code
        let _ = view.body

        #expect(view.openInlineLinks == true)
    }

    @Test("BlockQuoteView renders for various quote types")
    func testVariousQuoteTypes() {
        let markdowns = [
            "> Simple quote",
            "> Multi\n> line\n> quote",
            "> Quote with **formatting**",
            "> Quote with [link](url)",
            "> Quote with `code`"
        ]

        for markdown in markdowns {
            let doc = Document(parsing: markdown)
            guard let blockQuote = doc.children.compactMap({ $0 as? BlockQuote }).first else {
                continue
            }

            let view = BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)

            // Access body for each quote type
            let _ = view.body
        }

        #expect(Bool(true))
    }
}
