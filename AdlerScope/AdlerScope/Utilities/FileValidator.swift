//
//  FileValidator.swift
//  AdlerScope
//
//  File validation utilities
//

import Foundation

/// Validates file types and formats
struct FileValidator {
    /// Checks if URL represents a markdown file
    /// - Parameter url: File URL to check
    /// - Returns: True if file is markdown-compatible
    static func isMarkdownFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["md", "markdown", "rmd", "qmd", "txt"].contains(ext)
    }
}
