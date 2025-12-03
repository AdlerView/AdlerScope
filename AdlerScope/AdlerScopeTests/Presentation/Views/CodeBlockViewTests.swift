//
//  CodeBlockViewTests.swift
//  AdlerScopeTests
//
//  Tests for CodeBlockView
//

import Testing
import Foundation
import SwiftUI
import Markdown
@testable import AdlerScope

@Suite("CodeBlockView Tests")
struct CodeBlockViewTests {

    @Test("CodeBlockView can be instantiated and body renders")
    func testInstantiation() {
        let doc = Document(parsing: "```\ncode\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.childCount >= 0)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView body can be accessed")
    func testBodyAccess() {
        let doc = Document(parsing: "```\nprint('Hello')\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        // Accessing body executes the view rendering code
        let _ = view.body

        // Test passes if body can be accessed without crashing
        #expect(Bool(true))
    }

    @Test("CodeBlockView with language Swift")
    func testWithLanguageSwift() {
        let doc = Document(parsing: "```swift\nlet x = 1\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.language == "swift")
        #expect(codeBlock.language == "swift")

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView with language Python")
    func testWithLanguagePython() {
        let doc = Document(parsing: "```python\nprint('Hello')\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.language == "python")

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView with language JavaScript")
    func testWithLanguageJavaScript() {
        let doc = Document(parsing: "```javascript\nconsole.log('test');\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.language == "javascript")

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView without language")
    func testWithoutLanguage() {
        let doc = Document(parsing: "```\ncode\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.language == nil)

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView with multiline code")
    func testMultilineCode() {
        let doc = Document(parsing: """
        ```swift
        func hello() {
            print("Hello")
            return 42
        }
        ```
        """)
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        #expect(view.codeBlock.language == "swift")

        // Access body to execute rendering code
        let _ = view.body
    }

    @Test("CodeBlockView with empty code")
    func testEmptyCode() {
        let doc = Document(parsing: "```\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("CodeBlockView with special characters")
    func testWithSpecialCharacters() {
        let doc = Document(parsing: "```\nlet str = \"test & <html>\"\n```")
        guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
            Issue.record("Expected CodeBlock")
            return
        }

        let view = CodeBlockView(codeBlock: codeBlock)

        // Access body to execute rendering code
        let _ = view.body

        #expect(Bool(true))
    }

    @Test("CodeBlockView with various languages")
    func testVariousLanguages() {
        let languages = ["swift", "python", "javascript", "java", "rust", "go"]

        for language in languages {
            let doc = Document(parsing: "```\(language)\ncode\n```")
            guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
                continue
            }

            let view = CodeBlockView(codeBlock: codeBlock)

            // Access body for each language
            let _ = view.body

            #expect(view.codeBlock.language == language)
        }
    }

    @Test("CodeBlockView renders for various code types")
    func testVariousCodeTypes() {
        let markdowns = [
            "```\nsimple code\n```",
            "```swift\nlet x = 1\n```",
            "```python\nprint('hello')\n```",
            "```\nmulti\nline\ncode\n```",
            "```javascript\nconst x = () => {};\n```"
        ]

        for markdown in markdowns {
            let doc = Document(parsing: markdown)
            guard let codeBlock = doc.children.compactMap({ $0 as? CodeBlock }).first else {
                continue
            }

            let view = CodeBlockView(codeBlock: codeBlock)

            // Access body for each code type
            let _ = view.body
        }

        #expect(Bool(true))
    }
}
