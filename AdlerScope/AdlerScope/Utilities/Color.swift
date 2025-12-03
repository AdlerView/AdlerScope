//
//  Color.swift
//  AdlerScope
//
//  Created by adlerflow on 2025-11-03.
//  Pure SwiftUI Color utilities
//

import SwiftUI

// MARK: - Color Extensions

extension Color {

    // MARK: - Hex Color Parsing

    /// Creates a Color from a hex string (e.g., "#FF5733", "#F573", "#FF5733AA")
    ///
    /// Supports the following formats:
    /// - `#RGB` - Short form (expands to #RRGGBB)
    /// - `#RGBA` - Short form with alpha (expands to #RRGGBBAA)
    /// - `#RRGGBB` - Standard hex color
    /// - `#RRGGBBAA` - Hex color with alpha channel
    ///
    /// **Example:**
    /// ```swift
    /// let red = Color(hex: "#FF0000")
    /// let blue = Color(hex: "00F")  // Short form, no # prefix
    /// let semiTransparent = Color(hex: "#FF000080")
    /// ```
    ///
    /// - Parameter hex: A hex color string (with or without the # prefix)
    /// - Returns: A Color instance, or nil if parsing fails
    init?(hex: String) {
        var color = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        color = color.hasPrefix("#") ? String(color.dropFirst()) : color

        // Expand short forms: #RGB → #RRGGBB, #RGBA → #RRGGBBAA
        if color.count == 3 || color.count == 4 {
            var expanded = ""
            for char in color {
                expanded += String(char) + String(char)
            }
            color = expanded
        }

        // Parse hex value
        var rgbValue: UInt64 = 0
        guard Scanner(string: color).scanHexInt64(&rgbValue) else {
            return nil
        }

        let alpha: Double
        if color.count == 8 {
            // #RRGGBBAA format
            alpha = Double((rgbValue & 0xFF)) / 255.0
            rgbValue = rgbValue >> 8
        } else if color.count == 6 {
            // #RRGGBB format (default alpha = 1.0)
            alpha = 1.0
        } else {
            return nil
        }

        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Semantic Color Palette

extension Color {

    /// Semantic colors for markdown rendering
    ///
    /// These colors adapt automatically to light/dark mode using SwiftUI's semantic color system.
    ///
    /// **SwiftUI Best Practice**: Use semantic colors from this palette rather than hard-coded RGB values.
    /// All colors automatically adapt to the system's light/dark mode setting.
    enum Markdown {

        /// Code block background
        ///
        /// Uses platform-specific semantic colors for automatic light/dark adaptation.
        static var codeBackground: Color {
            #if os(macOS)
            Color(.controlBackgroundColor)
            #else
            Color(.systemGray6)
            #endif
        }

        /// Inline code background
        ///
        /// Light gray with transparency, adapts naturally to system appearance.
        static var inlineCodeBackground: Color {
            Color.gray.opacity(0.15)
        }

        /// Inline code foreground
        ///
        /// Pink accent color for inline code snippets (e.g., `code`).
        static let inlineCodeForeground = Color.pink

        /// Block quote accent bar
        ///
        /// Semi-transparent blue for the vertical bar in block quotes.
        static let blockQuoteAccent = Color.blue.opacity(0.4)

        /// Hyperlink color
        ///
        /// Standard blue for clickable links in markdown.
        static let link = Color.blue

        /// Warning/unsupported element color
        ///
        /// Orange for placeholder content or unsupported markdown elements.
        static let warning = Color.orange

        /// Main text background
        ///
        /// Uses platform-specific semantic colors for editable text areas.
        static var textBackground: Color {
            #if os(macOS)
            Color(.textBackgroundColor)
            #else
            Color(.systemBackground)
            #endif
        }
    }
}
