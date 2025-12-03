//
//  RecentDocumentsSidebarView.swift
//  AdlerScope
//
//  Sidebar with favorites and recent documents
//

import SwiftUI
import SwiftData

struct RecentDocumentsSidebarView: View {
    // MARK: - Bindings

    @Binding var selectedDocument: RecentDocument?

    // MARK: - Environment

    @Environment(\.openWindow) private var openWindow

    // MARK: - SwiftData Queries

    /// Recent documents sorted by last opened date
    @Query(sort: \RecentDocument.lastOpened, order: .reverse)
    private var recentDocuments: [RecentDocument]

    /// Favorite documents only
    @Query(filter: #Predicate<RecentDocument> { $0.isFavorite })
    private var favoriteDocuments: [RecentDocument]

    // MARK: - Actions

    let onOpenDocument: () -> Void
    let onToggleFavorite: (RecentDocument) -> Void
    let onRemoveDocument: (RecentDocument) -> Void

    // MARK: - Body

    var body: some View {
        List(selection: $selectedDocument) {
            // Favorites Section
            if !favoriteDocuments.isEmpty {
                Section("Favorites") {
                    ForEach(favoriteDocuments) { document in
                        RecentDocumentRow(document: document)
                            .tag(document)
                            .contextMenu {
                                Button("Open in New Window") {
                                    openNewWindowWithDocument(document)
                                }

                                Divider()

                                Button("Toggle Favorite") {
                                    onToggleFavorite(document)
                                }

                                Divider()

                                Button("Remove from Recents", role: .destructive) {
                                    onRemoveDocument(document)
                                }
                            }
                    }
                }
            }

            // Recent Documents Section
            Section("Recent") {
                ForEach(recentDocuments.prefix(10)) { document in
                    RecentDocumentRow(document: document)
                        .tag(document)
                        .contextMenu {
                            Button("Open in New Window") {
                                openNewWindowWithDocument(document)
                            }

                            Divider()

                            Button("Toggle Favorite") {
                                onToggleFavorite(document)
                            }

                            Divider()

                            Button("Remove from Recents", role: .destructive) {
                                onRemoveDocument(document)
                            }
                        }
                }
            }
        }
        .navigationTitle("AdlerScope")
        .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onOpenDocument()
                } label: {
                    Label("Open", systemImage: "doc.badge.plus")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }

    // MARK: - Window Management

    private func openNewWindowWithDocument(_ document: RecentDocument) {
        // Store document ID in UserDefaults as a bridge to the new window
        // The new window will read this on appear and select the document
        UserDefaults.standard.set(document.id.uuidString, forKey: "pendingDocumentID")

        // Open new window
        openWindow(id: "main")

        // Clear the pending ID after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UserDefaults.standard.removeObject(forKey: "pendingDocumentID")
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedDocument: RecentDocument?

    return NavigationSplitView {
        RecentDocumentsSidebarView(
            selectedDocument: $selectedDocument,
            onOpenDocument: { print("Open document") },
            onToggleFavorite: { doc in print("Toggle favorite: \(doc.displayName)") },
            onRemoveDocument: { doc in print("Remove: \(doc.displayName)") }
        )
    } detail: {
        Text("Select a document")
    }
    .modelContainer(for: RecentDocument.self, inMemory: true)
}
