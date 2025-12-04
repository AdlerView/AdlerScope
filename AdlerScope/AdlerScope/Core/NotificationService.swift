//
//  NotificationService.swift
//  AdlerScope
//
//  Push Notifications service handling authorization, registration,
//  and notification delivery for iOS, macOS, and visionOS.
//

import Foundation
import Combine
import UserNotifications
import os.log

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Notification Categories

/// Identifiers for notification categories (actionable notifications)
enum NotificationCategory: String, CaseIterable {
    case documentSync = "DOCUMENT_SYNC"
    case contentUpdate = "CONTENT_UPDATE"
    case reminder = "REMINDER"
}

/// Identifiers for notification actions
enum NotificationAction: String {
    // Document sync actions
    case viewDocument = "VIEW_DOCUMENT"
    case dismissSync = "DISMISS_SYNC"

    // Content update actions
    case viewUpdate = "VIEW_UPDATE"
    case dismissUpdate = "DISMISS_UPDATE"

    // Reminder actions
    case openReminder = "OPEN_REMINDER"
    case snoozeReminder = "SNOOZE_REMINDER"
}

// MARK: - Notification Service

/// Centralized service for managing Push Notifications
/// Handles authorization, registration, categories, and delivery
@MainActor
final class NotificationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Published Properties

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var deviceToken: String?
    @Published private(set) var isRegisteredForRemoteNotifications: Bool = false

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Configures the notification service. Call this at app launch.
    func configure() {
        notificationCenter.delegate = self
        registerCategories()

        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Requests notification authorization from the user.
    /// - Parameter options: The authorization options to request
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await refreshAuthorizationStatus()

            if granted {
                logger.info("Notification authorization granted")
                await registerForRemoteNotifications()
            } else {
                logger.info("Notification authorization denied")
            }

            return granted
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    /// Requests provisional authorization (silent delivery to Notification Center only)
    /// Notifications are delivered quietly without interrupting the user
    @discardableResult
    func requestProvisionalAuthorization() async -> Bool {
        return await requestAuthorization(options: [.alert, .sound, .badge, .provisional])
    }

    /// Refreshes the current authorization status from the system
    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        #if DEBUG
        logger.debug("Authorization status: \(String(describing: settings.authorizationStatus.rawValue))")
        #endif
    }

    /// Returns detailed notification settings
    func getNotificationSettings() async -> UNNotificationSettings {
        return await notificationCenter.notificationSettings()
    }

    // MARK: - Remote Notification Registration

    /// Registers the app for remote notifications with APNs
    func registerForRemoteNotifications() async {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            logger.warning("Cannot register for remote notifications: not authorized")
            return
        }

        #if canImport(UIKit) && !os(watchOS)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        logger.info("Registered for remote notifications (iOS/visionOS)")
        #elseif canImport(AppKit)
        await MainActor.run {
            NSApplication.shared.registerForRemoteNotifications()
        }
        logger.info("Registered for remote notifications (macOS)")
        #endif
    }

    /// Called when device token is received from APNs
    /// - Parameter deviceToken: The raw device token data
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        self.isRegisteredForRemoteNotifications = true

        logger.info("Received device token: \(tokenString.prefix(20))...")

        // TODO: Send device token to your provider server
        // providerServer.registerDeviceToken(tokenString)
    }

    /// Called when remote notification registration fails
    /// - Parameter error: The registration error
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        self.isRegisteredForRemoteNotifications = false
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Notification Categories

    /// Registers notification categories and actions with the system
    private func registerCategories() {
        let categories = createNotificationCategories()
        notificationCenter.setNotificationCategories(categories)
        #if DEBUG
        logger.debug("Registered \(categories.count) notification categories")
        #endif
    }

    private func createNotificationCategories() -> Set<UNNotificationCategory> {
        // Document Sync Category
        let viewDocumentAction = UNNotificationAction(
            identifier: NotificationAction.viewDocument.rawValue,
            title: "View Document",
            options: [.foreground]
        )
        let dismissSyncAction = UNNotificationAction(
            identifier: NotificationAction.dismissSync.rawValue,
            title: "Dismiss",
            options: []
        )
        let documentSyncCategory = UNNotificationCategory(
            identifier: NotificationCategory.documentSync.rawValue,
            actions: [viewDocumentAction, dismissSyncAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Content Update Category
        let viewUpdateAction = UNNotificationAction(
            identifier: NotificationAction.viewUpdate.rawValue,
            title: "View",
            options: [.foreground]
        )
        let dismissUpdateAction = UNNotificationAction(
            identifier: NotificationAction.dismissUpdate.rawValue,
            title: "Dismiss",
            options: []
        )
        let contentUpdateCategory = UNNotificationCategory(
            identifier: NotificationCategory.contentUpdate.rawValue,
            actions: [viewUpdateAction, dismissUpdateAction],
            intentIdentifiers: [],
            options: []
        )

        // Reminder Category
        let openReminderAction = UNNotificationAction(
            identifier: NotificationAction.openReminder.rawValue,
            title: "Open",
            options: [.foreground]
        )
        let snoozeReminderAction = UNNotificationAction(
            identifier: NotificationAction.snoozeReminder.rawValue,
            title: "Snooze",
            options: []
        )
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminder.rawValue,
            actions: [openReminderAction, snoozeReminderAction],
            intentIdentifiers: [],
            options: []
        )

        return [documentSyncCategory, contentUpdateCategory, reminderCategory]
    }

    // MARK: - Local Notifications

    /// Schedules a local notification
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: The notification body text
    ///   - category: The notification category for actions
    ///   - userInfo: Custom data to include with the notification
    ///   - trigger: When to deliver the notification (nil for immediate)
    /// - Returns: The notification request identifier
    @discardableResult
    func scheduleLocalNotification(
        title: String,
        body: String,
        category: NotificationCategory? = nil,
        userInfo: [AnyHashable: Any] = [:],
        trigger: UNNotificationTrigger? = nil
    ) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        if let category = category {
            content.categoryIdentifier = category.rawValue
        }

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.info("Scheduled local notification: \(identifier)")

        return identifier
    }

    /// Schedules a notification to fire after a time interval
    @discardableResult
    func scheduleNotification(
        title: String,
        body: String,
        category: NotificationCategory? = nil,
        userInfo: [AnyHashable: Any] = [:],
        after interval: TimeInterval
    ) async throws -> String {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        return try await scheduleLocalNotification(
            title: title,
            body: body,
            category: category,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    /// Cancels a pending notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        #if DEBUG
        logger.debug("Cancelled notification: \(identifier)")
        #endif
    }

    /// Cancels all pending notifications
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        #if DEBUG
        logger.debug("Cancelled all pending notifications")
        #endif
    }

    /// Gets all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Gets all delivered notifications
    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }

    /// Removes delivered notifications from Notification Center
    func removeDeliveredNotifications(identifiers: [String]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Clears the app badge
    func clearBadge() async {
        #if canImport(UIKit) && !os(watchOS)
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        #elseif canImport(AppKit)
        await MainActor.run {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Called when a notification is delivered while the app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        #if DEBUG
        logger.debug("Notification received in foreground: \(notification.request.identifier)")
        #endif

        // Show banner and play sound even when app is in foreground
        return [.banner, .sound, .badge]
    }

    /// Called when the user interacts with a notification (tap or action)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        let actionIdentifier = response.actionIdentifier
        let notification = response.notification
        let userInfo = notification.request.content.userInfo

        logger.info("Notification action: \(actionIdentifier)")

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            await handleNotificationTap(notification: notification, userInfo: userInfo)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            #if DEBUG
            logger.debug("Notification dismissed")
            #endif

        case NotificationAction.viewDocument.rawValue:
            await handleViewDocument(userInfo: userInfo)

        case NotificationAction.viewUpdate.rawValue:
            await handleViewUpdate(userInfo: userInfo)

        case NotificationAction.openReminder.rawValue:
            await handleOpenReminder(userInfo: userInfo)

        case NotificationAction.snoozeReminder.rawValue:
            await handleSnoozeReminder(userInfo: userInfo)

        default:
            logger.warning("Unknown action: \(actionIdentifier)")
        }
    }

    // MARK: - Action Handlers

    private func handleNotificationTap(notification: UNNotification, userInfo: [AnyHashable: Any]) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        logger.info("Handling notification tap")

        // Handle based on category
        let category = notification.request.content.categoryIdentifier
        switch category {
        case NotificationCategory.documentSync.rawValue:
            await handleViewDocument(userInfo: userInfo)
        case NotificationCategory.contentUpdate.rawValue:
            await handleViewUpdate(userInfo: userInfo)
        case NotificationCategory.reminder.rawValue:
            await handleOpenReminder(userInfo: userInfo)
        default:
            break
        }
    }

    private func handleViewDocument(userInfo: [AnyHashable: Any]) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        logger.info("View document action")

        // Extract document URL from userInfo and open it
        if let urlString = userInfo["documentURL"] as? String,
           let url = URL(string: urlString) {
            _ = await MainActor.run {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #elseif canImport(AppKit)
                NSWorkspace.shared.open(url)
                #endif
            }
        }
    }

    private func handleViewUpdate(userInfo: [AnyHashable: Any]) async {
        await navigateToDocument(userInfo: userInfo, action: "View update")
    }

    private func handleOpenReminder(userInfo: [AnyHashable: Any]) async {
        await navigateToDocument(userInfo: userInfo, action: "Open reminder")
    }

    /// Shared navigation logic for notification action handlers
    /// - Parameters:
    ///   - userInfo: Notification payload containing documentID or documentURL
    ///   - action: Description of the action for logging
    private func navigateToDocument(userInfo: [AnyHashable: Any], action: String) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        logger.info("\(action) action")

        // Navigate to document by ID if provided (preferred for in-app navigation)
        if let documentIDString = userInfo["documentID"] as? String,
           let documentID = UUID(uuidString: documentIDString) {
            await NavigationService.shared.requestOpenDocument(id: documentID)
            return
        }

        // Fallback: open document URL externally if provided
        if let urlString = userInfo["documentURL"] as? String,
           let url = URL(string: urlString) {
            // Validate URL scheme for security
            guard let scheme = url.scheme?.lowercased(),
                  ["file", "http", "https"].contains(scheme) else {
                logger.warning("Rejected unsafe URL scheme: \(url.scheme ?? "nil", privacy: .public)")
                return
            }

            await MainActor.run {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #elseif canImport(AppKit)
                NSWorkspace.shared.open(url)
                #endif
            }
            return
        }

        logger.warning("No valid documentID or documentURL provided in userInfo")
    }

    private func handleSnoozeReminder(userInfo: [AnyHashable: Any]) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "Notifications")
        logger.info("Snooze reminder action")

        // Reschedule notification for 10 minutes later
        _ = await MainActor.run {
            Task {
                try? await NotificationService.shared.scheduleNotification(
                    title: "Reminder (Snoozed)",
                    body: userInfo["reminderBody"] as? String ?? "You have a reminder",
                    category: .reminder,
                    userInfo: userInfo,
                    after: 10 * 60 // 10 minutes
                )
            }
        }
    }
}
