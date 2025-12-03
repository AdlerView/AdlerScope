#if os(macOS)
//
//  ImageDropHandler.swift
//  AdlerScope
//
//  Handles drag-and-drop and paste operations for images.
//  Integrates with SidecarManager and FormatMenuActions.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

/// Handles image drop and paste operations
@MainActor
final class ImageDropHandler {
    // MARK: - Dependencies

    private let sidecarManager: SidecarManager
    private let formatActions: FormatMenuActions
    private weak var undoManager: UndoManager?

    // MARK: - Initialization

    /// Creates a new image drop handler
    /// - Parameters:
    ///   - sidecarManager: The sidecar manager for storing images
    ///   - formatActions: The format actions for queuing insertions
    ///   - undoManager: Optional undo manager for undo support
    init(
        sidecarManager: SidecarManager,
        formatActions: FormatMenuActions,
        undoManager: UndoManager?
    ) {
        self.sidecarManager = sidecarManager
        self.formatActions = formatActions
        self.undoManager = undoManager
    }

    // MARK: - Drop Handling

    /// Handles dropped URLs (from Finder or other apps)
    /// - Parameter urls: The dropped URLs
    /// - Returns: true if at least one image was successfully handled
    @discardableResult
    func handleDrop(of urls: [URL]) -> Bool {
        // Filter to only image files
        let imageURLs = urls.filter { url in
            guard let values = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
                  let typeIdentifier = values.typeIdentifier,
                  let utType = UTType(typeIdentifier) else {
                return false
            }
            return utType.conforms(to: .image)
        }

        guard !imageURLs.isEmpty else { return false }

        // Group as single undo operation
        undoManager?.beginUndoGrouping()
        undoManager?.setActionName(imageURLs.count == 1 ? "Insert Image" : "Insert Images")

        var successCount = 0

        for imageURL in imageURLs {
            do {
                // Start accessing security-scoped resource if needed
                let accessGranted = imageURL.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        imageURL.stopAccessingSecurityScopedResource()
                    }
                }

                let filename = try sidecarManager.addImage(from: imageURL)
                let altText = imageURL.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")

                formatActions.insertImageMarkdown(filename: filename, altText: altText)
                successCount += 1
            } catch {
                print("Failed to import image \(imageURL.lastPathComponent): \(error)")
            }
        }

        undoManager?.endUndoGrouping()

        return successCount > 0
    }

    // MARK: - Paste Handling

    /// Handles paste from pasteboard
    /// - Parameter pasteboard: The pasteboard to read from
    /// - Returns: true if an image was successfully pasted
    @discardableResult
    func handlePaste(from pasteboard: NSPasteboard) -> Bool {
        // Check for image data first (screenshots, copied images)
        if let imageInfo = extractImageData(from: pasteboard) {
            return handlePastedImageData(imageInfo)
        }

        // Check for file URLs
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [UTType.image.identifier]
        ]

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
           !urls.isEmpty {
            return handleDrop(of: urls)
        }

        return false
    }

    /// Extracts image data from pasteboard
    /// - Parameter pasteboard: The pasteboard to read from
    /// - Returns: Tuple of image data and UTType, or nil if no image data found
    private func extractImageData(from pasteboard: NSPasteboard) -> (Data, UTType)? {
        // Check types in order of preference
        let typesToCheck: [(NSPasteboard.PasteboardType, UTType)] = [
            (.png, .png),
            (.tiff, .tiff),
            (NSPasteboard.PasteboardType(UTType.jpeg.identifier), .jpeg),
            (NSPasteboard.PasteboardType("public.jpeg"), .jpeg)
        ]

        for (pbType, utType) in typesToCheck {
            if let data = pasteboard.data(forType: pbType), !data.isEmpty {
                return (data, utType)
            }
        }

        return nil
    }

    /// Handles pasted image data (not a file)
    /// - Parameter imageInfo: Tuple of image data and UTType
    /// - Returns: true if the image was successfully saved
    private func handlePastedImageData(_ imageInfo: (Data, UTType)) -> Bool {
        let (data, utType) = imageInfo

        // Generate timestamp-based filename
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "T", with: "_")

        let ext = utType.preferredFilenameExtension ?? "png"
        let filename = "pasted-\(timestamp).\(ext)"

        undoManager?.beginUndoGrouping()
        undoManager?.setActionName("Paste Image")

        do {
            let finalFilename = try sidecarManager.addImageData(data, preferredName: filename)
            formatActions.insertImageMarkdown(filename: finalFilename, altText: "Pasted Image")
            undoManager?.endUndoGrouping()
            return true
        } catch {
            print("Failed to paste image: \(error)")
            undoManager?.endUndoGrouping()
            return false
        }
    }

    // MARK: - Validation

    /// Checks if the pasteboard contains image data
    /// - Parameter pasteboard: The pasteboard to check
    /// - Returns: true if the pasteboard contains images
    func canHandlePaste(from pasteboard: NSPasteboard) -> Bool {
        // Check for image data
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png,
            .tiff,
            NSPasteboard.PasteboardType(UTType.jpeg.identifier),
            NSPasteboard.PasteboardType("public.jpeg")
        ]

        for type in imageTypes {
            if pasteboard.data(forType: type) != nil {
                return true
            }
        }

        // Check for image file URLs
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [UTType.image.identifier]
        ]

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
           !urls.isEmpty {
            return true
        }

        return false
    }

    /// Validates if URLs can be handled as image drops
    /// - Parameter urls: The URLs to validate
    /// - Returns: true if at least one URL is a valid image
    func canHandleDrop(of urls: [URL]) -> Bool {
        urls.contains { url in
            guard let values = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
                  let typeIdentifier = values.typeIdentifier,
                  let utType = UTType(typeIdentifier) else {
                return false
            }
            return utType.conforms(to: .image)
        }
    }

    /// Returns the accepted drag types for NSView registration
    static var acceptedDragTypes: [NSPasteboard.PasteboardType] {
        [
            .fileURL,
            .png,
            .tiff,
            NSPasteboard.PasteboardType(UTType.jpeg.identifier)
        ]
    }
}

#endif
