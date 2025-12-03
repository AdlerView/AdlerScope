#if os(macOS)
//
//  ImagePreviewView.swift
//  AdlerScope
//
//  Renders images in the markdown preview.
//  Loads images from the sidecar directory using SidecarManager.
//

import SwiftUI
import AppKit
import Markdown

/// Renders an image in the markdown preview
struct ImagePreviewView: View {
    let image: Markdown.Image
    let sidecarManager: SidecarManager?

    @State private var loadedImage: NSImage?
    @State private var loadState: LoadState = .loading

    enum LoadState {
        case loading
        case loaded
        case missing
        case corrupt
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingPlaceholder

            case .loaded:
                if let nsImage = loadedImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityLabel(altText)
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
        // Retry loading when sidecarManager becomes available or updates
        .onChange(of: sidecarManager?.sidecarURL) { _, _ in
            if loadState == .loading || loadState == .missing {
                loadImage()
            }
        }
        .onChange(of: sidecarManager?.imageManifest.count) { _, _ in
            if loadState == .loading || loadState == .missing {
                loadImage()
            }
        }
    }

    // MARK: - Computed Properties

    private var altText: String {
        image.plainText
    }

    private var filename: String {
        image.source ?? ""
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        placeholderView(
            icon: "arrow.triangle.2.circlepath",
            text: "Loading...",
            backgroundColor: Color.secondary.opacity(0.1)
        )
    }

    private var missingPlaceholder: some View {
        placeholderView(
            icon: "questionmark.square.dashed",
            text: altText.isEmpty ? "Image not found: \(filename)" : altText,
            backgroundColor: Color.secondary.opacity(0.1)
        )
    }

    private var corruptPlaceholder: some View {
        placeholderView(
            icon: "exclamationmark.triangle",
            text: "Cannot load image: \(filename)",
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
        print("[ImagePreviewView] Loading image, source: \(image.source ?? "nil")")
        print("[ImagePreviewView] SidecarManager: \(sidecarManager != nil ? "present" : "nil")")
        print("[ImagePreviewView] SidecarURL: \(sidecarManager?.sidecarURL?.path ?? "nil")")
        print("[ImagePreviewView] DocumentURL: \(sidecarManager?.documentURL?.path ?? "nil")")

        guard let source = image.source, !source.isEmpty else {
            print("[ImagePreviewView] No source, setting missing")
            loadState = .missing
            return
        }

        // Check if this is a URL or a local filename
        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            // Remote URL - for now show as missing (could add async loading later)
            print("[ImagePreviewView] Remote URL not supported")
            loadState = .missing
            return
        }

        // Strategy 1: Try to resolve via SidecarManager manifest
        if let manager = sidecarManager,
           let url = manager.resolveImage(filename: source) {
            print("[ImagePreviewView] Strategy 1: Found in manifest: \(url.path)")
            loadFromURL(url)
            return
        }

        // Strategy 2: Try direct path in sidecar directory
        if let manager = sidecarManager,
           let sidecarURL = manager.sidecarURL {
            let imageURL = sidecarURL.appendingPathComponent(source)
            let exists = FileManager.default.fileExists(atPath: imageURL.path)
            print("[ImagePreviewView] Strategy 2: Direct path \(imageURL.path), exists: \(exists)")
            if exists {
                loadFromURL(imageURL)
                return
            }
        }

        // Strategy 3: Try computing sidecar URL from documentURL
        if let manager = sidecarManager,
           let documentURL = manager.documentURL {
            let sidecarURL = SidecarManager.sidecarURL(for: documentURL)
            let imageURL = sidecarURL.appendingPathComponent(source)
            let exists = FileManager.default.fileExists(atPath: imageURL.path)
            print("[ImagePreviewView] Strategy 3: Computed path \(imageURL.path), exists: \(exists)")
            if exists {
                loadFromURL(imageURL)
                return
            }
        }

        // No sidecar manager or image not found
        print("[ImagePreviewView] Image not found, setting missing")
        loadState = .missing
    }

    private func loadFromURL(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            loadState = .missing
            return
        }

        if let nsImage = NSImage(contentsOf: url), nsImage.isValid {
            loadedImage = nsImage
            loadState = .loaded
        } else {
            loadState = .corrupt
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
