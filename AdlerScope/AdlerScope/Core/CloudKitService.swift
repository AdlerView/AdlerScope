//
//  CloudKitService.swift
//  AdlerScope
//
//  Service for CloudKit container and database access
//  Manages account status, share participants, and provides database references
//

import CloudKit
import Foundation
import OSLog

/// Account status for iCloud/CloudKit access
enum CloudAccountStatus: Equatable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    case unknown

    var isAvailable: Bool {
        self == .available
    }

    var localizedDescription: String {
        switch self {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "No iCloud account configured. Please sign in to iCloud in System Settings."
        case .restricted:
            return "iCloud access is restricted by parental controls or device management."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later."
        case .couldNotDetermine:
            return "Could not determine iCloud status."
        case .unknown:
            return "Unknown iCloud status."
        }
    }
}


/// Service for CloudKit operations
@Observable
@MainActor
class CloudKitService {
    // MARK: - Constants

    static let containerIdentifier = "iCloud.com.AdlerScope"

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "CloudKitService")

    /// Current iCloud account status
    private(set) var accountStatus: CloudAccountStatus = .unknown

    /// The CloudKit container for this app
    let container: CKContainer

    /// Private database for user-specific data
    var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    /// Shared database for data shared by other users
    var sharedDatabase: CKDatabase {
        container.sharedCloudDatabase
    }

    /// Public database for app-wide data
    var publicDatabase: CKDatabase {
        container.publicCloudDatabase
    }

    // MARK: - Initialization

    init() {
        self.container = CKContainer(identifier: Self.containerIdentifier)
        logger.info("CloudKitService initialized with container: \(Self.containerIdentifier)")
    }

    // MARK: - Account Status

    /// Checks the current iCloud account status
    /// - Returns: The current account status
    func checkAccountStatus() async -> CloudAccountStatus {
        logger.debug("Checking iCloud account status...")

        do {
            let status = try await container.accountStatus()
            let mappedStatus = mapAccountStatus(status)
            self.accountStatus = mappedStatus
            logger.info("iCloud account status: \(String(describing: mappedStatus))")
            return mappedStatus
        } catch {
            logger.error("Failed to check account status: \(error.localizedDescription)")
            self.accountStatus = .couldNotDetermine
            return .couldNotDetermine
        }
    }

    /// Maps CKAccountStatus to our CloudAccountStatus
    private func mapAccountStatus(_ status: CKAccountStatus) -> CloudAccountStatus {
        switch status {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .couldNotDetermine:
            return .couldNotDetermine
        @unknown default:
            logger.warning("Unknown CKAccountStatus: \(status.rawValue)")
            return .unknown
        }
    }

    // MARK: - User Identity

    /// Fetches the current user's record ID
    /// - Returns: The user's record ID, or nil if not available
    func fetchUserRecordID() async -> CKRecord.ID? {
        logger.debug("Fetching user record ID...")

        do {
            let recordID = try await container.userRecordID()
            logger.info("User record ID: \(recordID.recordName)")
            return recordID
        } catch {
            logger.error("Failed to fetch user record ID: \(error.localizedDescription)")
            return nil
        }
    }

    /// Fetches the current user's identity from a share's participant list
    ///
    /// In the modern CloudKit sharing model, user identity information is only available
    /// within the context of a CKShare. Use `share.currentUserParticipant?.userIdentity`
    /// or this method to get the current user's identity from an existing share.
    ///
    /// - Parameter share: The share to fetch the current user's identity from
    /// - Returns: The user's identity, or nil if not a participant
    func fetchUserIdentity(from share: CKShare) -> CKUserIdentity? {
        guard let participant = share.currentUserParticipant else {
            logger.debug("Current user is not a participant in this share")
            return nil
        }
        let identity = participant.userIdentity
        logger.info("Fetched user identity from share: \(identity.nameComponents?.formatted() ?? "unknown")")
        return identity
    }

    // MARK: - Share Participants

    /// Fetches share participants for the given user record IDs
    /// Use this to look up potential participants when setting up sharing
    /// - Parameter userRecordIDs: The record IDs to look up
    /// - Returns: A dictionary mapping record IDs to participant results
    func fetchShareParticipants(for userRecordIDs: [CKRecord.ID]) async -> [CKRecord.ID: Result<CKShare.Participant, Error>] {
        logger.debug("Fetching share participants for \(userRecordIDs.count) user record IDs...")

        do {
            let results = try await container.shareParticipants(forUserRecordIDs: userRecordIDs)
            logger.info("Fetched \(results.count) share participant results")
            return results
        } catch {
            logger.error("Failed to fetch share participants: \(error.localizedDescription)")
            return [:]
        }
    }

    /// Fetches share participants for the given email addresses
    /// Use this to look up potential participants by email when setting up sharing
    /// - Parameter emailAddresses: The email addresses to look up
    /// - Returns: A dictionary mapping email addresses to participant results
    func fetchShareParticipants(forEmailAddresses emailAddresses: [String]) async -> [String: Result<CKShare.Participant, Error>] {
        logger.debug("Fetching share participants for \(emailAddresses.count) email addresses...")

        do {
            let results = try await container.shareParticipants(forEmailAddresses: emailAddresses)
            logger.info("Fetched \(results.count) share participant results")
            return results
        } catch {
            logger.error("Failed to fetch share participants: \(error.localizedDescription)")
            return [:]
        }
    }

    /// Fetches share participants for the given phone numbers
    /// Use this to look up potential participants by phone when setting up sharing
    /// - Parameter phoneNumbers: The phone numbers to look up
    /// - Returns: A dictionary mapping phone numbers to participant results
    func fetchShareParticipants(forPhoneNumbers phoneNumbers: [String]) async -> [String: Result<CKShare.Participant, Error>] {
        logger.debug("Fetching share participants for \(phoneNumbers.count) phone numbers...")

        do {
            let results = try await container.shareParticipants(forPhoneNumbers: phoneNumbers)
            logger.info("Fetched \(results.count) share participant results")
            return results
        } catch {
            logger.error("Failed to fetch share participants: \(error.localizedDescription)")
            return [:]
        }
    }

    // MARK: - Account Change Notifications

    /// Starts observing account status changes
    func startObservingAccountChanges() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.logger.info("iCloud account changed, refreshing status...")
                _ = await self?.checkAccountStatus()
            }
        }
        logger.debug("Started observing iCloud account changes")
    }

    /// Stops observing account status changes
    func stopObservingAccountChanges() {
        NotificationCenter.default.removeObserver(self, name: .CKAccountChanged, object: nil)
        logger.debug("Stopped observing iCloud account changes")
    }
}
