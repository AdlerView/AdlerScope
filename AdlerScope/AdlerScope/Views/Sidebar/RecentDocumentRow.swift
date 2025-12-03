//
//  RecentDocumentRow.swift
//  AdlerScope
//
//  Single row item for recent documents list
//

import SwiftUI

struct RecentDocumentRow: View {
    let document: RecentDocument

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName)
                    .font(.body)
                    .lineLimit(1)

                Text(relativeDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: document.lastOpened, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    List {
        RecentDocumentRow(document: RecentDocument.sample())
        RecentDocumentRow(document: RecentDocument(
            url: URL(fileURLWithPath: "/Users/test/TODO.md"),
            displayName: "TODO.md",
            lastOpened: Date().addingTimeInterval(-3600),
            isFavorite: false
        ))
    }
}
