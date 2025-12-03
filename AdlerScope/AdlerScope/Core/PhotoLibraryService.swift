//
//  PhotoLibraryService.swift
//  AdlerScope
//
//  Service for managing Photo Library access and authorization
//  Provides PhotoKit integration for importing photos into documents
//

import Foundation
import Photos
import PhotosUI
import SwiftUI
import OSLog

/// Authorization status for Photo Library access
enum PhotoLibraryAuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited

    var canAccessPhotos: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .notDetermined, .restricted, .denied:
            return false
        }
    }

    var userActionRequired: Bool {
        switch self {
        case .denied:
            return true
        case .notDetermined, .restricted, .authorized, .limited:
            return false
        }
    }
}

/// Service for Photo Library operations
@Observable
@MainActor
class PhotoLibraryService: NSObject {
    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "PhotoLibraryService")

    private(set) var authorizationStatus: PhotoLibraryAuthorizationStatus = .notDetermined

    // MARK: - Initialization

    override init() {
        super.init()
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Updates the current authorization status from the system
    func updateAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = mapAuthorizationStatus(status)
        logger.debug("Photo Library authorization status: \(String(describing: self.authorizationStatus))")
    }

    /// Requests authorization to access the Photo Library
    /// - Returns: The resulting authorization status
    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        logger.info("Requesting Photo Library authorization")

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        let mappedStatus = mapAuthorizationStatus(status)

        await MainActor.run {
            self.authorizationStatus = mappedStatus
        }

        logger.info("Photo Library authorization result: \(String(describing: mappedStatus))")
        return mappedStatus
    }

    /// Maps PHAuthorizationStatus to our PhotoLibraryAuthorizationStatus
    private func mapAuthorizationStatus(_ status: PHAuthorizationStatus) -> PhotoLibraryAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            logger.warning("Unknown PHAuthorizationStatus: \(status.rawValue)")
            return .denied
        }
    }

    // MARK: - Settings Navigation

    #if os(macOS)
    /// Opens System Settings to the Privacy & Security > Photos section
    func openPhotoLibrarySettings() {
        logger.info("Opening Photo Library settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
            NSWorkspace.shared.open(url)
        }
    }
    #endif

    #if os(iOS)
    /// Opens Settings app to the app's privacy settings
    func openPhotoLibrarySettings() {
        logger.info("Opening app settings")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    #endif

    // MARK: - Limited Library Management (iOS only)

    #if os(iOS)
    /// Presents the limited library picker to allow users to select additional photos
    /// - Parameter viewController: The view controller to present from
    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        guard authorizationStatus == .limited else {
            logger.warning("Cannot present limited library picker - not in limited mode")
            return
        }

        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
    }
    #endif
}

// MARK: - PhotosPicker Configuration Helper

extension PhotoLibraryService {
    /// Creates a PhotosPickerConfiguration for use with SwiftUI PhotosPicker
    /// - Parameters:
    ///   - selectionLimit: Maximum number of items to select (0 for unlimited)
    ///   - filter: Filter for media types
    /// - Returns: PHPickerConfiguration
    func makePickerConfiguration(
        selectionLimit: Int = 0,
        filter: PHPickerFilter = .images
    ) -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = selectionLimit
        configuration.filter = filter
        configuration.preferredAssetRepresentationMode = .current
        return configuration
    }
}

// MARK: - Photo Import Result

/// Result of importing a photo from the library
struct PhotoImportResult: Identifiable {
    let id = UUID()
    let image: PlatformImage?
    let data: Data?
    let fileExtension: String
    let originalFilename: String?

    #if os(macOS)
    typealias PlatformImage = NSImage
    #else
    typealias PlatformImage = UIImage
    #endif
}

// MARK: - Change Observer

extension PhotoLibraryService: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.updateAuthorizationStatus()
        }
    }

    /// Registers for photo library change notifications
    func startObservingChanges() {
        PHPhotoLibrary.shared().register(self)
        logger.debug("Started observing Photo Library changes")
    }

    /// Unregisters from photo library change notifications
    func stopObservingChanges() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        logger.debug("Stopped observing Photo Library changes")
    }
}
