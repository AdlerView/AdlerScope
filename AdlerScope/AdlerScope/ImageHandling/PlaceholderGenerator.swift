#if os(macOS)
//
//  PlaceholderGenerator.swift
//  AdlerScope
//
//  Generates placeholder images for error states (missing, corrupt, loading).
//

import AppKit
import Foundation

/// Type of placeholder to generate
enum PlaceholderType {
    /// Image file is missing
    case missing

    /// Image file is corrupt or invalid
    case corrupt

    /// Image is currently loading
    case loading

    /// SF Symbol name for this placeholder type
    var iconName: String {
        switch self {
        case .missing: return "questionmark.square.dashed"
        case .corrupt: return "exclamationmark.triangle"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    /// Background color for this placeholder type
    var backgroundColor: NSColor {
        switch self {
        case .missing: return .controlBackgroundColor
        case .corrupt: return NSColor.systemRed.withAlphaComponent(0.1)
        case .loading: return .controlBackgroundColor
        }
    }

    /// Label text for this placeholder type
    var label: String {
        switch self {
        case .missing: return "Image not found"
        case .corrupt: return "Cannot load image"
        case .loading: return "Loading..."
        }
    }
}

/// Generates placeholder images for various error states
enum PlaceholderGenerator {
    /// Default placeholder size
    static let defaultSize = CGSize(width: 200, height: 80)

    /// Generates a placeholder image
    /// - Parameters:
    ///   - type: The type of placeholder
    ///   - altText: Alternative text to display
    ///   - filename: The filename to display
    ///   - size: Optional custom size
    /// - Returns: A placeholder NSImage
    static func generate(
        type: PlaceholderType,
        altText: String,
        filename: String,
        size: CGSize = defaultSize
    ) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)

        // Draw background
        type.backgroundColor.setFill()
        let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        backgroundPath.fill()

        // Draw border
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(
            roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
            xRadius: 6,
            yRadius: 6
        )
        borderPath.lineWidth = 1
        borderPath.stroke()

        // Draw icon
        if let icon = NSImage(systemSymbolName: type.iconName, accessibilityDescription: type.label) {
            let iconSize: CGFloat = 24
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2,
                y: size.height - iconSize - 12,
                width: iconSize,
                height: iconSize
            )

            // Configure icon color
            let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            let tintedIcon = icon.withSymbolConfiguration(config)

            NSColor.secondaryLabelColor.set()
            tintedIcon?.draw(in: iconRect)
        }

        // Draw text
        let displayText = altText.isEmpty ? filename : altText
        let truncatedText = truncateText(displayText, maxLength: 30)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingMiddle

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = NSRect(
            x: 8,
            y: 8,
            width: size.width - 16,
            height: 20
        )

        (truncatedText as NSString).draw(in: textRect, withAttributes: attributes)

        return image
    }

    /// Generates a simple loading spinner placeholder
    /// - Parameter size: The size of the placeholder
    /// - Returns: A loading placeholder image
    static func generateLoading(size: CGSize = defaultSize) -> NSImage {
        generate(type: .loading, altText: "", filename: "Loading...", size: size)
    }

    /// Generates a missing image placeholder
    /// - Parameters:
    ///   - filename: The missing filename
    ///   - size: The size of the placeholder
    /// - Returns: A missing placeholder image
    static func generateMissing(filename: String, size: CGSize = defaultSize) -> NSImage {
        generate(type: .missing, altText: "", filename: filename, size: size)
    }

    /// Generates a corrupt image placeholder
    /// - Parameters:
    ///   - filename: The corrupt filename
    ///   - size: The size of the placeholder
    /// - Returns: A corrupt placeholder image
    static func generateCorrupt(filename: String, size: CGSize = defaultSize) -> NSImage {
        generate(type: .corrupt, altText: "", filename: filename, size: size)
    }

    // MARK: - Helpers

    /// Truncates text to a maximum length with ellipsis
    private static func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }

        let halfLength = (maxLength - 3) / 2
        let prefix = text.prefix(halfLength)
        let suffix = text.suffix(halfLength)
        return "\(prefix)...\(suffix)"
    }
}

#endif
