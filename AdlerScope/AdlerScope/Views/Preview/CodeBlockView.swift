//
//  CodeBlockView.swift
//  AdlerScope
//
//  Renders fenced code blocks with language badge
//

import SwiftUI
import Markdown

/// Renders fenced code blocks (```language)
struct CodeBlockView: View {
    let codeBlock: CodeBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language Badge (optional)
            if let language = codeBlock.language, !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.Markdown.inlineCodeBackground)
                        .cornerRadius(4)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            // Code Content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightedCode)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.Markdown.codeBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var highlightedCode: AttributedString {
        // Pure SwiftUI rendering: Plain monospaced text
        // Future enhancement: Integrate SwiftHighlighter for syntax coloring
        // Currently displays plain text to maintain Pure SwiftUI architecture
        var attributed = AttributedString(codeBlock.code)
        attributed.font = .system(.body, design: .monospaced)
        return attributed
    }
}

// MARK: - Preview

#Preview("Swift Code Block") {
    if let codeBlock = PreviewCodeBlockParser.parse("""
        ```swift
        struct ContentView: View {
            @State private var count = 0

            var body: some View {
                Button("Count: \\(count)") {
                    count += 1
                }
            }
        }
        ```
        """) {
        CodeBlockView(codeBlock: codeBlock)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse code block")
    }
}

#Preview("Python Code Block") {
    if let codeBlock = PreviewCodeBlockParser.parse("""
        ```python
        def fibonacci(n):
            if n <= 1:
                return n
            return fibonacci(n-1) + fibonacci(n-2)

        for i in range(10):
            print(fibonacci(i))
        ```
        """) {
        CodeBlockView(codeBlock: codeBlock)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse code block")
    }
}

#Preview("Code Block - No Language") {
    if let codeBlock = PreviewCodeBlockParser.parse("""
        ```
        Plain code block without language specification
        Just some text here
        ```
        """) {
        CodeBlockView(codeBlock: codeBlock)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse code block")
    }
}

/// Helper to parse markdown and extract CodeBlock for previews
private enum PreviewCodeBlockParser {
    static func parse(_ markdown: String) -> CodeBlock? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? CodeBlock }.first
    }
}
