//
//  HeadingView.swift
//  AdlerScope
//
//  Renders markdown headings (# through ######)
//

import SwiftUI
import Markdown

/// Renders markdown headings with appropriate font sizes
struct HeadingView: View {
    let heading: Heading
    let openInlineLinks: Bool
    let sidecarManager: SidecarManager?

    private let styleProvider = HeadingStyleProvider()

    init(heading: Heading, openInlineLinks: Bool, sidecarManager: SidecarManager? = nil) {
        self.heading = heading
        self.openInlineLinks = openInlineLinks
        self.sidecarManager = sidecarManager
    }

    var body: some View {
        Text(MarkdownInlineRenderer.render(heading, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager))
            .font(styleProvider.fontForLevel(heading.level))
            .fontWeight(.bold)
            .padding(.vertical, styleProvider.verticalPaddingForLevel(heading.level))
    }
}

// MARK: - Preview

#Preview("All Heading Levels") {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(1...6, id: \.self) { level in
            if let heading = PreviewHeadingParser.parse(level: level, text: "Heading Level \(level)") {
                HeadingView(heading: heading, openInlineLinks: false)
            }
        }
    }
    .padding()
    .frame(width: 400, alignment: .leading)
}

#Preview("H1 - Main Title") {
    if let heading = PreviewHeadingParser.parse(level: 1, text: "Welcome to AdlerScope") {
        HeadingView(heading: heading, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    }
}

#Preview("H2 - Section Title") {
    if let heading = PreviewHeadingParser.parse(level: 2, text: "Getting Started") {
        HeadingView(heading: heading, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    }
}

#Preview("H3 - Subsection") {
    if let heading = PreviewHeadingParser.parse(level: 3, text: "Installation Instructions") {
        HeadingView(heading: heading, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    }
}

/// Helper to parse markdown and extract Heading for previews
private enum PreviewHeadingParser {
    static func parse(level: Int, text: String) -> Heading? {
        let hashes = String(repeating: "#", count: level)
        let markdown = "\(hashes) \(text)"
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? Heading }.first
    }
}
