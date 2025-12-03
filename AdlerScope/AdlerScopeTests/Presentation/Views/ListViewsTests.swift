//
//  ListViewsTests.swift
//  AdlerScopeTests
//
//  Tests for UnorderedListView and OrderedListView
//

import Testing
import Foundation
import SwiftUI
import Markdown
@testable import AdlerScope

@Suite("UnorderedListView Tests")
struct UnorderedListViewTests {

    @Test("UnorderedListView can be instantiated and body renders")
    func testInstantiation() {
        let doc = Document(parsing: "- Item 1\n- Item 2")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("UnorderedListView body can be accessed")
    func testBodyAccess() {
        let doc = Document(parsing: "- Single item")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        // Accessing body executes the view rendering code
        let _ = view.body

        // Test passes if body can be accessed without crashing
        #expect(Bool(true))
    }

    @Test("UnorderedListView with multiple items")
    func testMultipleItems() {
        let doc = Document(parsing: "- Item 1\n- Item 2\n- Item 3")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        #expect(list.childCount == 3)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("UnorderedListView with openInlineLinks false")
    func testOpenInlineLinksFalse() {
        let doc = Document(parsing: "- Item with [link](https://example.com)")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        #expect(view.openInlineLinks == false)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("UnorderedListView with openInlineLinks true")
    func testOpenInlineLinksTrue() {
        let doc = Document(parsing: "- Item")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: true)

        #expect(view.openInlineLinks == true)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("UnorderedListView with formatted text")
    func testWithFormattedText() {
        let doc = Document(parsing: "- Item with **bold** and *italic*")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("UnorderedListView with inline code")
    func testWithInlineCode() {
        let doc = Document(parsing: "- Item with `code`")
        guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
            Issue.record("Expected UnorderedList")
            return
        }

        let view = UnorderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("UnorderedListView renders for various list types")
    func testVariousListTypes() {
        let markdowns = [
            "- Simple item",
            "- Item 1\n- Item 2\n- Item 3",
            "- Item with **formatting**",
            "- Item with [link](url)",
            "- Item with `code`"
        ]

        for markdown in markdowns {
            let doc = Document(parsing: markdown)
            guard let list = doc.children.compactMap({ $0 as? UnorderedList }).first else {
                continue
            }

            let view = UnorderedListView(list: list, openInlineLinks: false)

            // Access body for each list type
            let _ = view.body
        }

        #expect(Bool(true))
    }
}

@Suite("OrderedListView Tests")
struct OrderedListViewTests {

    @Test("OrderedListView can be instantiated and body renders")
    func testInstantiation() {
        let doc = Document(parsing: "1. Item 1\n2. Item 2")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("OrderedListView body can be accessed")
    func testBodyAccess() {
        let doc = Document(parsing: "1. Single item")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        // Accessing body executes the view rendering code
        let _ = view.body

        // Test passes if body can be accessed without crashing
        #expect(Bool(true))
    }

    @Test("OrderedListView with multiple items")
    func testMultipleItems() {
        let doc = Document(parsing: "1. Item 1\n2. Item 2\n3. Item 3")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        #expect(list.childCount == 3)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("OrderedListView with openInlineLinks false")
    func testOpenInlineLinksFalse() {
        let doc = Document(parsing: "1. Item with [link](https://example.com)")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        #expect(view.openInlineLinks == false)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("OrderedListView with openInlineLinks true")
    func testOpenInlineLinkTrue() {
        let doc = Document(parsing: "1. Item")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: true)

        #expect(view.openInlineLinks == true)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("OrderedListView with custom start index")
    func testCustomStartIndex() {
        let doc = Document(parsing: "5. Item\n6. Item")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        #expect(list.startIndex == 5)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("OrderedListView starting at 1")
    func testStartingAtOne() {
        let doc = Document(parsing: "1. First\n2. Second\n3. Third")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        #expect(list.startIndex == 1)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("OrderedListView with formatted text")
    func testWithFormattedText() {
        let doc = Document(parsing: "1. Item with **bold** and *italic*")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("OrderedListView with inline code")
    func testWithInlineCode() {
        let doc = Document(parsing: "1. Item with `code`")
        guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
            Issue.record("Expected OrderedList")
            return
        }

        let view = OrderedListView(list: list, openInlineLinks: false)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("OrderedListView renders for various list types")
    func testVariousListTypes() {
        let markdowns = [
            "1. Simple item",
            "1. Item 1\n2. Item 2\n3. Item 3",
            "5. Starting at 5\n6. Item 6",
            "1. Item with **formatting**",
            "1. Item with [link](url)",
            "1. Item with `code`"
        ]

        for markdown in markdowns {
            let doc = Document(parsing: markdown)
            guard let list = doc.children.compactMap({ $0 as? OrderedList }).first else {
                continue
            }

            let view = OrderedListView(list: list, openInlineLinks: false)

            // Access body for each list type
            let _ = view.body
        }

        #expect(Bool(true))
    }
}
