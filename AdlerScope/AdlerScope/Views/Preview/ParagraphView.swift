//
//  ParagraphView.swift
//  AdlerScope
//
//  Renders markdown paragraphs with inline formatting
//

import SwiftUI
import Markdown

/// Renders markdown paragraphs with inline elements (bold, italic, code, links, etc.)
struct ParagraphView: View {
    let paragraph: Paragraph
    let openInlineLinks: Bool
    let sidecarManager: SidecarManager?

    init(paragraph: Paragraph, openInlineLinks: Bool, sidecarManager: SidecarManager? = nil) {
        self.paragraph = paragraph
        self.openInlineLinks = openInlineLinks
        self.sidecarManager = sidecarManager
    }

    var body: some View {
        Text(MarkdownInlineRenderer.render(paragraph, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager))
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}

// MARK: - Inline Renderer

/// Renders inline markdown elements (bold, italic, code, links, etc.) to AttributedString
struct MarkdownInlineRenderer {

    /// Renders a markup element and its children to an AttributedString
    /// - Parameters:
    ///   - markup: The markup element to render (typically Paragraph or inline container)
    ///   - openInlineLinks: Whether links should be clickable
    ///   - sidecarManager: Optional sidecar manager for resolving image paths
    /// - Returns: Styled AttributedString with inline formatting
    static func render(_ markup: Markup, openInlineLinks: Bool, sidecarManager: SidecarManager? = nil) -> AttributedString {
        var result = AttributedString()

        for child in markup.children {
            if let text = child as? Markdown.Text {
                result += AttributedString(text.string)
            } else if let strong = child as? Strong {
                result += renderStrong(strong, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
            } else if let emphasis = child as? Emphasis {
                result += renderEmphasis(emphasis, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
            } else if let code = child as? InlineCode {
                result += renderInlineCode(code)
            } else if let link = child as? Markdown.Link {
                result += renderLink(link, openInlineLinks: openInlineLinks)
            } else if let strikethrough = child as? Strikethrough {
                result += renderStrikethrough(strikethrough, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
            } else if let image = child as? Markdown.Image {
                result += renderImage(image, sidecarManager: sidecarManager)
            } else if child is SoftBreak {
                // CommonMark spec: Soft breaks (single newlines) render as spaces
                result += AttributedString(" ")
            } else if child is LineBreak {
                // Hard line breaks (two spaces + newline, or backslash + newline)
                result += AttributedString("\n")
            }
        }

        return result
    }

    // MARK: - Private Renderers

    private static func renderStrong(_ strong: Strong, openInlineLinks: Bool, sidecarManager: SidecarManager?) -> AttributedString {
        var bold = render(strong, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
        bold.font = .body.bold()
        return bold
    }

    private static func renderEmphasis(_ emphasis: Emphasis, openInlineLinks: Bool, sidecarManager: SidecarManager?) -> AttributedString {
        var italic = render(emphasis, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
        italic.font = .body.italic()
        return italic
    }

    private static func renderInlineCode(_ code: InlineCode) -> AttributedString {
        var codeText = AttributedString(code.code)
        codeText.font = .system(.body, design: .monospaced)
        codeText.backgroundColor = Color.Markdown.inlineCodeBackground
        codeText.foregroundColor = Color.Markdown.inlineCodeForeground
        return codeText
    }

    private static func renderLink(_ link: Markdown.Link, openInlineLinks: Bool) -> AttributedString {
        var linkText = AttributedString(link.plainText)
        linkText.foregroundColor = Color.Markdown.link
        linkText.underlineStyle = .single

        // Only make links clickable if setting is enabled
        if openInlineLinks, let url = link.destination {
            linkText.link = URL(string: url)
        }

        return linkText
    }

    private static func renderStrikethrough(_ strikethrough: Strikethrough, openInlineLinks: Bool, sidecarManager: SidecarManager?) -> AttributedString {
        var struck = render(strikethrough, openInlineLinks: openInlineLinks, sidecarManager: sidecarManager)
        struck.strikethroughStyle = .single
        struck.foregroundColor = Color.secondary
        return struck
    }

    private static func renderImage(_ image: Markdown.Image, sidecarManager: SidecarManager?) -> AttributedString {
        // For inline images (mixed with text), we show a placeholder indicator
        // Block-level images are rendered by ImagePreviewView instead
        let altText = image.plainText
        let source = image.source ?? ""

        // Create a styled placeholder for inline images
        let displayText = altText.isEmpty ? "[\(source)]" : "[\(altText)]"
        var imageIndicator = AttributedString("🖼 " + displayText)
        imageIndicator.foregroundColor = Color.Markdown.link
        imageIndicator.backgroundColor = Color.Markdown.inlineCodeBackground
        imageIndicator.font = .body.italic()

        return imageIndicator
    }
}

// MARK: - Previews

#Preview("Simple Paragraph") {
    if let paragraph = PreviewParagraphParser.parse("This is a simple paragraph with plain text.") {
        ParagraphView(paragraph: paragraph, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

#Preview("Bold and Italic") {
    if let paragraph = PreviewParagraphParser.parse("This has **bold text** and *italic text* and ***both***!") {
        ParagraphView(paragraph: paragraph, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

#Preview("Inline Code") {
    if let paragraph = PreviewParagraphParser.parse("Use the `print()` function to output text. Variables like `myVar` are highlighted.") {
        ParagraphView(paragraph: paragraph, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

#Preview("Links") {
    if let paragraph = PreviewParagraphParser.parse("Visit [Apple](https://apple.com) or [GitHub](https://github.com) for more info.") {
        ParagraphView(paragraph: paragraph, openInlineLinks: true)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

#Preview("Strikethrough") {
    if let paragraph = PreviewParagraphParser.parse("This is ~~deleted text~~ and this is normal.") {
        ParagraphView(paragraph: paragraph, openInlineLinks: false)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

#Preview("Mixed Formatting") {
    if let paragraph = PreviewParagraphParser.parse("A **bold** word, an *italic* phrase, some `code`, a [link](https://example.com), and ~~strikethrough~~.") {
        ParagraphView(paragraph: paragraph, openInlineLinks: true)
            .padding()
            .frame(width: 400, alignment: .leading)
    } else {
        Text("Failed to parse paragraph")
    }
}

/// Helper to parse markdown and extract Paragraph for previews
private enum PreviewParagraphParser {
    static func parse(_ markdown: String) -> Paragraph? {
        let document = Document(parsing: markdown)
        return document.children.compactMap { $0 as? Paragraph }.first
    }
}
