//
//  ListViews.swift
//  AdlerScope
//
//  Renders unordered and ordered lists
//

import SwiftUI
import Markdown

/// Renders unordered (bulleted) lists
struct UnorderedListView: View {
    let list: UnorderedList
    let openInlineLinks: Bool
    let sidecarManager: SidecarManager?

    init(list: UnorderedList, openInlineLinks: Bool, sidecarManager: SidecarManager? = nil) {
        self.list = list
        self.openInlineLinks = openInlineLinks
        self.sidecarManager = sidecarManager
    }

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                GridRow(alignment: .top) {
                    Text("•")
                        .font(.body.bold())
                        .gridColumnAlignment(.leading)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            MarkdownBlockView(markup: child, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.leading, 20)
    }
}

/// Renders ordered (numbered) lists
struct OrderedListView: View {
    let list: OrderedList
    let openInlineLinks: Bool
    let sidecarManager: SidecarManager?

    init(list: OrderedList, openInlineLinks: Bool, sidecarManager: SidecarManager? = nil) {
        self.list = list
        self.openInlineLinks = openInlineLinks
        self.sidecarManager = sidecarManager
    }

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                GridRow(alignment: .top) {
                    Text("\(Int(list.startIndex) + index).")
                        .font(.body)
                        .gridColumnAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            MarkdownBlockView(markup: child, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.leading, 20)
    }
}

// MARK: - Previews

#Preview("Unordered List") {
    if let list = PreviewListParser.parseUnordered("""
        - First item
        - Second item
        - Third item with **bold** text
        - Fourth item
        """) {
        UnorderedListView(list: list, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse list")
    }
}

#Preview("Ordered List") {
    if let list = PreviewListParser.parseOrdered("""
        1. First step
        2. Second step
        3. Third step with *italic* text
        4. Fourth step
        """) {
        OrderedListView(list: list, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse list")
    }
}

#Preview("Nested Unordered List") {
    if let list = PreviewListParser.parseUnordered("""
        - Parent item 1
          - Child item A
          - Child item B
        - Parent item 2
          - Child item C
        """) {
        UnorderedListView(list: list, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse list")
    }
}

#Preview("Ordered List - Custom Start") {
    if let list = PreviewListParser.parseOrdered("""
        5. Starting at five
        6. Six
        7. Seven
        8. Eight
        """) {
        OrderedListView(list: list, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse list")
    }
}

/// Helper to parse markdown and extract lists for previews
private enum PreviewListParser {
    static func parseUnordered(_ markdown: String) -> UnorderedList? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? UnorderedList }.first
    }

    static func parseOrdered(_ markdown: String) -> OrderedList? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? OrderedList }.first
    }
}
