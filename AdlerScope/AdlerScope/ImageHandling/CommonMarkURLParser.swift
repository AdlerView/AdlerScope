//
//  CommonMarkURLParser.swift
//  AdlerScope
//
//  Parses image/link URLs according to CommonMark specification.
//  Handles angle-bracket stripping and backslash escape processing.
//

import Foundation

/// Parses CommonMark-compliant image and link URLs
///
/// CommonMark defines two forms of link destinations:
/// 1. Angle-bracketed: `<url with spaces>` - angle brackets stripped, spaces allowed
/// 2. Non-angle-bracketed: `url` - no spaces allowed, balanced parentheses
///
/// Both forms support backslash escapes for special characters.
struct CommonMarkURLParser: Sendable {

    // MARK: - Public Methods

    /// Parses a raw URL string according to CommonMark rules
    /// - Parameter rawURL: The URL string as it appears in markdown
    /// - Returns: Normalized URL string ready for resolution
    static func parse(_ rawURL: String) -> String {
        var url = rawURL.trimmingCharacters(in: .whitespaces)

        // Empty URL
        guard !url.isEmpty else { return url }

        // 1. Handle angle-bracketed form: <url> → url
        if url.hasPrefix("<") && url.hasSuffix(">") && url.count >= 2 {
            url = String(url.dropFirst().dropLast())
        }

        // 2. Process backslash escapes
        url = processBackslashEscapes(url)

        return url
    }

    // MARK: - Private Helpers

    /// CommonMark escapable characters (ASCII punctuation)
    /// Per CommonMark spec: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
    private static let escapableCharacters: Set<Character> = [
        "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*",
        "+", ",", "-", ".", "/", ":", ";", "<", "=", ">",
        "?", "@", "[", "\\", "]", "^", "_", "`", "{", "|",
        "}", "~"
    ]

    /// Processes CommonMark backslash escapes
    /// - Parameter input: String potentially containing escape sequences
    /// - Returns: String with escapes resolved
    ///
    /// A backslash followed by an escapable character is replaced by that character.
    /// A backslash NOT followed by an escapable character is preserved as-is.
    private static func processBackslashEscapes(_ input: String) -> String {
        var result = ""
        result.reserveCapacity(input.count)

        var index = input.startIndex
        while index < input.endIndex {
            let char = input[index]

            if char == "\\" {
                let nextIndex = input.index(after: index)
                if nextIndex < input.endIndex {
                    let nextChar = input[nextIndex]
                    if escapableCharacters.contains(nextChar) {
                        // Escaped character - append only the character, not the backslash
                        result.append(nextChar)
                        index = input.index(after: nextIndex)
                        continue
                    }
                }
                // Backslash not followed by escapable char - keep the backslash
                result.append(char)
            } else {
                result.append(char)
            }

            index = input.index(after: index)
        }

        return result
    }
}
