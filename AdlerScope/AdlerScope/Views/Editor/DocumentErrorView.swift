//
//  DocumentErrorView.swift
//  AdlerScope
//
//  Error view when document fails to load
//

import SwiftUI

struct DocumentErrorView: View {
    let error: Error
    let document: RecentDocument
    let onRetry: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Failed to Load Document")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)

                Button("Remove from Recents") {
                    onRemove()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
    }
}

// MARK: - Preview

#Preview {
    DocumentErrorView(
        error: NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"]),
        document: RecentDocument.sample(),
        onRetry: { print("Retry tapped") },
        onRemove: { print("Remove tapped") }
    )
}
