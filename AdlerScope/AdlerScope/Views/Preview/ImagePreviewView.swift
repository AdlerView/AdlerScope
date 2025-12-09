#if os(macOS)
//
//  ImagePreviewView.swift
//  AdlerScope
//
//  Renders images in the markdown preview.
//  Supports local files (absolute, relative, sidecar) and remote URLs.
//

import SwiftUI
import AppKit
import Markdown

/// Renders an image in the markdown preview
struct ImagePreviewView: View {
    let image: Markdown.Image
    let sidecarManager: SidecarManager?

    @State private var loadedImage: NSImage?
    @State private var loadState: LoadState = .loading(progress: nil)
    @State private var loadTask: Task<Void, Never>?

    // Use the shared image loader via the use case
    private let loadImageUseCase: LoadImageUseCase

    enum LoadState: Equatable {
        case loading(progress: Double?)
        case loaded
        case missing
        case corrupt
    }

    // MARK: - Initialization

    init(image: Markdown.Image, sidecarManager: SidecarManager?) {
        self.image = image
        self.sidecarManager = sidecarManager
        self.loadImageUseCase = LoadImageUseCase(imageLoader: SecureImageLoader.shared)
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading(let progress):
                if isRemoteSource, let p = progress {
                    downloadingPlaceholder(progress: p)
                } else {
                    loadingPlaceholder
                }

            case .loaded:
                if let nsImage = loadedImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityLabel(altText)
                        .accessibilityHint(title ?? "")
                        .help(title ?? "")  // macOS tooltip from CommonMark title
                } else {
                    missingPlaceholder
                }

            case .missing:
                missingPlaceholder

            case .corrupt:
                corruptPlaceholder
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            loadTask?.cancel()
        }
        // Retry loading when sidecarManager becomes available or updates
        .onChange(of: sidecarManager?.sidecarURL) { _, _ in
            if case .loading = loadState {
                loadImage()
            } else if case .missing = loadState {
                loadImage()
            }
        }
        .onChange(of: sidecarManager?.imageManifest.count) { _, _ in
            if case .loading = loadState {
                loadImage()
            } else if case .missing = loadState {
                loadImage()
            }
        }
    }

    // MARK: - Computed Properties

    private var altText: String {
        image.plainText
    }

    private var source: String {
        image.source ?? ""
    }

    /// Image title from CommonMark syntax: ![alt](url "title")
    /// Used for tooltips and accessibility hints
    private var title: String? {
        image.title
    }

    /// Whether the image source is a remote URL
    private var isRemoteSource: Bool {
        let trimmed = source.trimmingCharacters(in: .whitespaces).lowercased()
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        placeholderView(
            icon: "arrow.triangle.2.circlepath",
            text: "Loading...",
            backgroundColor: Color.secondary.opacity(0.1)
        )
    }

    private func downloadingPlaceholder(progress: Double) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.secondary)

                Text("Downloading... \(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(maxWidth: 200)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var missingPlaceholder: some View {
        placeholderView(
            icon: "questionmark.square.dashed",
            text: altText.isEmpty ? "Image not found: \(source)" : altText,
            backgroundColor: Color.secondary.opacity(0.1)
        )
    }

    private var corruptPlaceholder: some View {
        placeholderView(
            icon: "exclamationmark.triangle",
            text: "Cannot load image: \(source)",
            backgroundColor: Color.red.opacity(0.1)
        )
    }

    private func placeholderView(icon: String, text: String, backgroundColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Image Loading

    private func loadImage() {
        guard !source.isEmpty else {
            loadState = .missing
            return
        }

        // Cancel any existing load task
        loadTask?.cancel()

        // Reset state
        loadState = .loading(progress: nil)

        // Start new load task
        loadTask = Task {
            let result = await loadImageUseCase.execute(
                source: source,
                altText: altText,
                documentURL: sidecarManager?.documentURL,
                sidecarManager: sidecarManager,
                onProgress: { @Sendable progress in
                    Task { @MainActor in
                        // Only update if still in loading state
                        if case .loading = loadState {
                            loadState = .loading(progress: progress)
                        }
                    }
                }
            )

            // Check if cancelled
            guard !Task.isCancelled else { return }

            // Update state on main actor
            await MainActor.run {
                switch result {
                case .success(let nsImage):
                    loadedImage = nsImage
                    loadState = .loaded

                case .missing:
                    loadState = .missing

                case .corrupt:
                    loadState = .corrupt

                case .loading:
                    // Should not happen after execute completes
                    break
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Image - Loading") {
    let markdown = "![Test Image](test.png)"
    let doc = Document(parsing: markdown)

    if let paragraph = Array(doc.children).first as? Paragraph,
       let image = Array(paragraph.children).first as? Markdown.Image {
        ImagePreviewView(image: image, sidecarManager: nil)
            .frame(width: 400)
            .padding()
    } else {
        Text("Failed to parse image")
    }
}

#Preview("Image - Remote URL") {
    let markdown = "![Remote Image](https://picsum.photos/400/300)"
    let doc = Document(parsing: markdown)

    if let paragraph = Array(doc.children).first as? Paragraph,
       let image = Array(paragraph.children).first as? Markdown.Image {
        ImagePreviewView(image: image, sidecarManager: nil)
            .frame(width: 400)
            .padding()
    } else {
        Text("Failed to parse image")
    }
}

#Preview("Image - Missing") {
    let markdown = "![Alt Text](nonexistent.png)"
    let doc = Document(parsing: markdown)

    if let paragraph = Array(doc.children).first as? Paragraph,
       let image = Array(paragraph.children).first as? Markdown.Image {
        ImagePreviewView(image: image, sidecarManager: nil)
            .frame(width: 400)
            .padding()
    } else {
        Text("Failed to parse image")
    }
}

#endif
