//
//  HeadingStyleProvider.swift
//  AdlerScope
//
//  Provides styling (font and padding) for markdown heading levels
//

import SwiftUI

/// Provides consistent styling for markdown headings across the application
struct HeadingStyleProvider {
    /// Returns the appropriate font for a heading level
    /// - Parameter level: The heading level (1-6)
    /// - Returns: SwiftUI Font matching the heading level
    func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        case 5: return .headline
        default: return .body.bold()
        }
    }

    /// Returns the vertical padding for a heading level
    /// - Parameter level: The heading level (1-6)
    /// - Returns: Vertical padding in points
    func verticalPaddingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 8
        case 2: return 6
        case 3, 4: return 4
        default: return 2
        }
    }
}

// MARK: - Preview

/// Demo view showing all heading styles
private struct HeadingStylePreview: View {
    private let styleProvider = HeadingStyleProvider()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(1...6, id: \.self) { level in
                Text("Heading Level \(level)")
                    .font(styleProvider.fontForLevel(level))
                    .padding(.vertical, styleProvider.verticalPaddingForLevel(level))

                Text("Padding: \(Int(styleProvider.verticalPaddingForLevel(level)))pt")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Heading Styles") {
    HeadingStylePreview()
        .frame(width: 400)
}

#Preview("Heading Comparison") {
    VStack(alignment: .leading, spacing: 16) {
        let styleProvider = HeadingStyleProvider()

        Group {
            Text("# Heading 1")
                .font(styleProvider.fontForLevel(1))
            Text("## Heading 2")
                .font(styleProvider.fontForLevel(2))
            Text("### Heading 3")
                .font(styleProvider.fontForLevel(3))
            Text("#### Heading 4")
                .font(styleProvider.fontForLevel(4))
            Text("##### Heading 5")
                .font(styleProvider.fontForLevel(5))
            Text("###### Heading 6")
                .font(styleProvider.fontForLevel(6))
        }
    }
    .padding()
    .frame(width: 400, alignment: .leading)
}
