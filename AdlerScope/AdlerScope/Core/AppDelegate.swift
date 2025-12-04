//
//  AppDelegate.swift
//  AdlerScope
//
//  AppDelegate adaptor for handling push notification registration callbacks.
//  Used with UIApplicationDelegateAdaptor (iOS/visionOS) and NSApplicationDelegateAdaptor (macOS).
//

import Foundation
import os.log

#if canImport(UIKit)
import UIKit

// MARK: - iOS/visionOS App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "AppDelegate")

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("Application did finish launching")

        // Configure notification service
        Task { @MainActor in
            NotificationService.shared.configure()
        }

        // Check if launched from notification
        if let notificationPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            logger.info("Launched from remote notification")
            handleRemoteNotificationLaunch(payload: notificationPayload)
        }

        return true
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            NotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    // MARK: - Remote Notification Handling

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        logger.info("Received remote notification")

        // Handle silent/background notifications
        handleSilentNotification(userInfo: userInfo) { result in
            completionHandler(result)
        }
    }

    // MARK: - Private Methods

    private func handleRemoteNotificationLaunch(payload: [AnyHashable: Any]) {
        // Handle app launch from notification tap
        #if DEBUG
        logger.debug("Processing notification launch payload")
        #endif
        // Extract relevant data and navigate to appropriate content
    }

    private func handleSilentNotification(
        userInfo: [AnyHashable: Any],
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle background/silent push notifications
        // These are used for content updates without user-visible alerts

        guard let contentAvailable = userInfo["content-available"] as? Int, contentAvailable == 1 else {
            completion(.noData)
            return
        }

        logger.info("Processing silent notification")

        // Perform background work (e.g., sync documents, fetch updates)
        Task {
            do {
                // Example: Trigger document sync
                // await DependencyContainer.shared.iCloudDocumentManager.syncDocuments()
                completion(.newData)
            } catch {
                logger.error("Silent notification processing failed: \(error.localizedDescription)")
                completion(.failed)
            }
        }
    }
}

#elseif canImport(AppKit)
import AppKit

// MARK: - macOS App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AdlerScope", category: "AppDelegate")

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")

        // Configure notification service
        Task { @MainActor in
            NotificationService.shared.configure()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
    }

    // MARK: - Remote Notification Registration

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            NotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            NotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    // MARK: - Remote Notification Handling

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        logger.info("Received remote notification")
        handleRemoteNotification(userInfo: userInfo)
    }

    // MARK: - Private Methods

    private func handleRemoteNotification(userInfo: [String: Any]) {
        #if DEBUG
        logger.debug("Processing remote notification")
        #endif

        // Check for silent notification
        if let contentAvailable = userInfo["content-available"] as? Int, contentAvailable == 1 {
            handleSilentNotification(userInfo: userInfo)
            return
        }

        // Handle regular notification
        // Extract relevant data and update UI or trigger actions
    }

    private func handleSilentNotification(userInfo: [String: Any]) {
        logger.info("Processing silent notification")

        Task {
            // Perform background work
            // Example: await DependencyContainer.shared.iCloudDocumentManager.syncDocuments()
        }
    }
}

#endif
