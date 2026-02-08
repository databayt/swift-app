import UIKit
import UserNotifications
import GoogleSignIn
import FacebookCore
import os

/// App delegate for push notifications and OAuth URL handling
/// Handles APNs registration, notification delivery, and OAuth callbacks
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()

        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    // MARK: - URL Handling (OAuth Callbacks)

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Facebook Login
        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }

        return false
    }

    // MARK: - Push Notifications

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            try? await APIClient.shared.registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.app.error("Failed to register for notifications: \(error)")
    }

    /// Handle silent push - trigger sync
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await SyncEngine.shared.syncAll()
        return .newData
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let type = response.notification.request.content.userInfo["type"] as? String
        let id = response.notification.request.content.userInfo["id"] as? String
        if let type {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .didReceiveNotification,
                    object: nil,
                    userInfo: ["type": type, "id": id as Any]
                )
            }
        }
    }
}

extension Notification.Name {
    static let didReceiveNotification = Notification.Name("didReceiveNotification")
}
