//
//  EmptyStateView.swift
//  AdlerScope
//
//  Empty state when no document is selected
//

import SwiftUI

struct EmptyStateView: View {
    let onOpenDocument: () -> Void
    let onNewDocument: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)  // Decorative

            VStack(spacing: 8) {
                Text("No Document Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a new document or open an existing one")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 12) {
                Button {
                    onNewDocument()
                } label: {
                    Label("New Document", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("n", modifiers: .command)
                .accessibilityLabel("Create new document")
                .accessibilityHint("Creates a new empty markdown document")

                Button {
                    onOpenDocument()
                } label: {
                    Label("Open Document", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)
                .accessibilityLabel("Open markdown document")
                .accessibilityHint("Opens file picker to select a markdown file")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Empty document state")
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        onOpenDocument: { },
        onNewDocument: { }
    )
}
