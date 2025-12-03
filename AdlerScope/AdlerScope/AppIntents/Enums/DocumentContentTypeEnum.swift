//
//  DocumentContentTypeEnum.swift
//  AdlerScope
//
//  AppEnum wrapper for DocumentContentType
//  Exposes document content types to Siri and Shortcuts
//

import AppIntents

/// AppEnum wrapper for DocumentContentType
enum DocumentContentTypeEnum: String, AppEnum {
    case markdown
    case pdf

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Document Type")
    }

    static var caseDisplayRepresentations: [DocumentContentTypeEnum: DisplayRepresentation] {
        [
            .markdown: DisplayRepresentation(
                title: "Markdown",
                subtitle: "Markdown document (.md, .markdown)",
                image: .init(systemName: "doc.text")
            ),
            .pdf: DisplayRepresentation(
                title: "PDF",
                subtitle: "PDF document",
                image: .init(systemName: "doc.richtext")
            )
        ]
    }
}
