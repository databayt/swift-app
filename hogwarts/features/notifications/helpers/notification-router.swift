import SwiftUI

/// Routes notification taps to the correct screen
/// Handles deep linking from push notifications
struct NotificationRouter {

    /// Possible notification destinations
    enum Destination: Hashable {
        case attendance(recordId: String?)
        case grade(resultId: String?)
        case message(conversationId: String?)
        case announcement(id: String?)
        case dashboard
    }

    /// Parse notification data into a destination
    static func destination(from notification: AppNotification) -> Destination {
        let type = notification.notificationType

        // Parse data JSON for ID
        let dataId = parseDataId(notification.data)

        switch type {
        case .attendance:
            return .attendance(recordId: dataId)
        case .grade:
            return .grade(resultId: dataId)
        case .message:
            return .message(conversationId: dataId)
        case .announcement:
            return .announcement(id: dataId)
        case .system:
            return .dashboard
        }
    }

    /// Parse notification from push payload
    static func destination(from userInfo: [AnyHashable: Any]) -> Destination? {
        guard let type = userInfo["type"] as? String else { return nil }
        let id = userInfo["id"] as? String

        switch type {
        case "attendance":
            return .attendance(recordId: id)
        case "grade":
            return .grade(resultId: id)
        case "message":
            return .message(conversationId: id)
        case "announcement":
            return .announcement(id: id)
        default:
            return .dashboard
        }
    }

    /// Parse the data field JSON string for an ID
    private static func parseDataId(_ data: String?) -> String? {
        guard let data, !data.isEmpty,
              let jsonData = data.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return dict["id"] as? String ?? dict["recordId"] as? String
    }
}

// MARK: - Navigation State

/// Observable navigation state for deep linking from notifications
@Observable
@MainActor
final class NotificationNavigationState {
    var selectedTab: AppTab = .dashboard
    var pendingDestination: NotificationRouter.Destination?

    /// Handle a notification tap
    func navigate(to destination: NotificationRouter.Destination) {
        switch destination {
        case .attendance:
            selectedTab = .dashboard
            pendingDestination = destination
        case .grade:
            selectedTab = .dashboard
            pendingDestination = destination
        case .message:
            selectedTab = .messages
            pendingDestination = destination
        case .announcement:
            selectedTab = .notifications
            pendingDestination = destination
        case .dashboard:
            selectedTab = .dashboard
            pendingDestination = nil
        }
    }

    /// Clear pending destination after handling
    func clearPending() {
        pendingDestination = nil
    }
}

/// App tabs enum
enum AppTab: Hashable {
    case dashboard
    case students
    case schedule
    case messages
    case notifications
    case profile
}
