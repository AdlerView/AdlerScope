//
//  BlockQuoteView.swift
//  AdlerScope
//
//  Renders block quotes with accent bar
//

import SwiftUI
import Markdown

/// Renders block quotes (> quoted text)
struct BlockQuoteView: View {
    let blockQuote: BlockQuote
    let openInlineLinks: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.Markdown.blockQuoteAccent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    MarkdownBlockView(markup: child, openInlineLinks: openInlineLinks)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Block Quote") {
    if let blockQuote = PreviewBlockQuoteParser.parse("""
        > This is a block quote.
        > It can span multiple lines.
        >
        > It can also have **bold** and *italic* text.
        """) {
        BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)
            .padding()
            .frame(width: 400)
    } else {
        Text("Failed to parse block quote")
    }
}

#Preview("Nested Block Quote") {
    if let blockQuote = PreviewBlockQuoteParser.parse("""
        > First level quote
        >
        > > Nested quote inside
        >
        > Back to first level
        """) {
        BlockQuoteView(blockQuote: blockQuote, openInlineLinks: false)
            .padding()
            .frame(width: 400)
    } else {
        Text("Failed to parse block quote")
    }
}

/// Helper to parse markdown and extract BlockQuote for previews
private enum PreviewBlockQuoteParser {
    static func parse(_ markdown: String) -> BlockQuote? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? BlockQuote }.first
    }
}
