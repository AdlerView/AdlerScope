//
//  MarkdownFileType.swift
//  AdlerScope
//
//  Markdown file type definitions for file import/export
//  Uses UTImportedTypeDeclarations from Info.plist for DocumentGroup compatibility
//

import UniformTypeIdentifiers

// MARK: - UTType Extensions

extension UTType {
    /// Markdown file type (.md, .markdown)
    /// Uses imported type declaration from Info.plist
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }

    /// R Markdown file type (.rmd)
    static var rMarkdown: UTType {
        UTType(importedAs: "org.rstudio.rmarkdown", conformingTo: .plainText)
    }

    /// Quarto file type (.qmd)
    static var quarto: UTType {
        UTType(importedAs: "org.quarto.qmd", conformingTo: .plainText)
    }
}

enum MarkdownFileType {
    /// All supported markdown file types for file import
    static let allowedTypes: [UTType] = [
        .plainText,
        .markdown,
        .rMarkdown,
        .quarto
    ]

    /// Primary markdown type
    static var markdown: UTType {
        .markdown
    }
}

// MARK: - File Extension Validation

extension MarkdownFileType {
    /// Check if a URL has a valid markdown extension
    static func isMarkdownFile(_ url: URL) -> Bool {
        let validExtensions = ["md", "markdown", "txt", "rmd", "qmd"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }

    /// Get the display name for a file type
    static func displayName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown":
            return "Markdown"
        case "rmd":
            return "R Markdown"
        case "qmd":
            return "Quarto Markdown"
        case "txt":
            return "Plain Text"
        default:
            return "Document"
        }
    }
}
