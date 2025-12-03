//
//  TableView.swift
//  AdlerScope
//
//  Renders markdown tables using SwiftUI Grid with horizontal scrolling
//

import SwiftUI
import Markdown

/// Renders markdown tables with header styling and column alignment
struct TableView: View {
    let table: Markdown.Table
    let openInlineLinks: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 8) {
                // Header Section
                if table.head.childCount > 0 {
                    ForEach(Array(table.head.children.enumerated()), id: \.offset) { rowIndex, row in
                        if let tableRow = row as? Markdown.Table.Row {
                            GridRow {
                                ForEach(Array(tableRow.cells.enumerated()), id: \.offset) { cellIndex, cell in
                                    TableCellView(
                                        cell: cell,
                                        isHeader: true,
                                        alignment: columnAlignment(at: cellIndex),
                                        openInlineLinks: openInlineLinks
                                    )
                                }
                            }
                        }
                    }

                    // Divider after header
                    Divider()
                        .gridCellUnsizedAxes(.horizontal)
                }

                // Body Section
                ForEach(Array(table.body.children.enumerated()), id: \.offset) { rowIndex, row in
                    if let tableRow = row as? Markdown.Table.Row {
                        GridRow {
                            ForEach(Array(tableRow.cells.enumerated()), id: \.offset) { cellIndex, cell in
                                TableCellView(
                                    cell: cell,
                                    isHeader: false,
                                    alignment: columnAlignment(at: cellIndex),
                                    openInlineLinks: openInlineLinks
                                )
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color.Markdown.codeBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    /// Maps swift-markdown column alignment to SwiftUI alignment
    private func columnAlignment(at index: Int) -> Alignment {
        guard index < table.columnAlignments.count else {
            return .leading // Default alignment
        }

        switch table.columnAlignments[index] {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        case .none:
            return .leading // Default for unspecified alignment
        }
    }
}

// MARK: - Table Cell View

/// Renders individual table cells with proper alignment and header styling
private struct TableCellView: View {
    let cell: Markdown.Table.Cell
    let isHeader: Bool
    let alignment: Alignment
    let openInlineLinks: Bool

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 4) {
            ForEach(Array(cell.children.enumerated()), id: \.offset) { _, child in
                InlineContentView(markup: child, openInlineLinks: openInlineLinks)
            }
        }
        .frame(minWidth: 80, alignment: alignment) // Minimum column width
        .font(isHeader ? .body.bold() : .body)
        .foregroundStyle(isHeader ? .primary : .secondary)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    /// Convert Alignment to HorizontalAlignment for VStack
    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }
}

// MARK: - Inline Content Renderer

/// Renders inline markdown content (text, emphasis, code, links, etc.)
private struct InlineContentView: View {
    let markup: Markup
    let openInlineLinks: Bool

    var body: some View {
        Group {
            if let text = markup as? Markdown.Text {
                SwiftUI.Text(text.string)
            } else if let emphasis = markup as? Emphasis {
                renderEmphasis(emphasis)
            } else if let strong = markup as? Strong {
                renderStrong(strong)
            } else if let inlineCode = markup as? InlineCode {
                SwiftUI.Text(inlineCode.code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .background(Color.Markdown.inlineCodeBackground)
                    .cornerRadius(3)
            } else if let link = markup as? Markdown.Link {
                renderLink(link)
            } else {
                // Fallback for other inline elements
                SwiftUI.Text(markup.format())
            }
        }
    }

    @ViewBuilder
    private func renderEmphasis(_ emphasis: Emphasis) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(emphasis.children.enumerated()), id: \.offset) { _, child in
                InlineContentView(markup: child, openInlineLinks: openInlineLinks)
            }
        }
        .italic()
    }

    @ViewBuilder
    private func renderStrong(_ strong: Strong) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(strong.children.enumerated()), id: \.offset) { _, child in
                InlineContentView(markup: child, openInlineLinks: openInlineLinks)
            }
        }
        .bold()
    }

    @ViewBuilder
    private func renderLink(_ link: Markdown.Link) -> some View {
        if openInlineLinks, let destination = link.destination, let url = URL(string: destination) {
            SwiftUI.Link(destination: url) {
                HStack(spacing: 2) {
                    ForEach(Array(link.children.enumerated()), id: \.offset) { _, child in
                        InlineContentView(markup: child, openInlineLinks: openInlineLinks)
                    }
                }
            }
        } else {
            HStack(spacing: 2) {
                ForEach(Array(link.children.enumerated()), id: \.offset) { _, child in
                    InlineContentView(markup: child, openInlineLinks: openInlineLinks)
                }
            }
            .foregroundStyle(.blue)
        }
    }
}

// MARK: - Previews

#Preview("Simple Table") {
    if let table = PreviewTableParser.parse("""
        | Name | Age | City |
        |------|-----|------|
        | Alice | 25 | Berlin |
        | Bob | 30 | Munich |
        | Carol | 28 | Hamburg |
        """) {
        TableView(table: table, openInlineLinks: false)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse table")
    }
}

#Preview("Table with Alignment") {
    if let table = PreviewTableParser.parse("""
        | Left | Center | Right |
        |:-----|:------:|------:|
        | A | B | C |
        | Data | Data | Data |
        | Long text | Short | 123 |
        """) {
        TableView(table: table, openInlineLinks: false)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse table")
    }
}

#Preview("Table with Formatting") {
    if let table = PreviewTableParser.parse("""
        | Feature | Status | Notes |
        |---------|--------|-------|
        | **Bold** | *Done* | `code` |
        | Links | Pending | See docs |
        | Images | WIP | Coming soon |
        """) {
        TableView(table: table, openInlineLinks: false)
            .padding()
            .frame(width: 500)
    } else {
        Text("Failed to parse table")
    }
}

#Preview("Wide Table (Scrollable)") {
    if let table = PreviewTableParser.parse("""
        | Column 1 | Column 2 | Column 3 | Column 4 | Column 5 | Column 6 |
        |----------|----------|----------|----------|----------|----------|
        | Data A1 | Data A2 | Data A3 | Data A4 | Data A5 | Data A6 |
        | Data B1 | Data B2 | Data B3 | Data B4 | Data B5 | Data B6 |
        """) {
        TableView(table: table, openInlineLinks: false)
            .padding()
            .frame(width: 400)
    } else {
        Text("Failed to parse table")
    }
}

/// Helper to parse markdown and extract Table for previews
private enum PreviewTableParser {
    static func parse(_ markdown: String) -> Markdown.Table? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? Markdown.Table }.first
    }
}
