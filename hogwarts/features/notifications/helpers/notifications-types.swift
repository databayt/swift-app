import SwiftUI

/// Type definitions for Notifications feature
/// Mirrors: src/components/platform/notifications/types.ts

// MARK: - API Response Types

/// App notification
struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let message: String
    let schoolId: String
    let data: String?
    let isRead: Bool
    let createdAt: Date

    var notificationType: NotificationType {
        NotificationType(rawValue: type) ?? .system
    }
}

/// Notification type enum
enum NotificationType: String, CaseIterable {
    case attendance
    case grade
    case message
    case announcement
    case system

    var icon: String {
        switch self {
        case .attendance: return "checkmark.circle"
        case .grade: return "chart.bar"
        case .message: return "bubble.left"
        case .announcement: return "megaphone"
        case .system: return "gear"
        }
    }

    var color: Color {
        switch self {
        case .attendance: return .green
        case .grade: return .purple
        case .message: return .blue
        case .announcement: return .orange
        case .system: return .gray
        }
    }

    var label: String {
        switch self {
        case .attendance: return String(localized: "notification.type.attendance")
        case .grade: return String(localized: "notification.type.grade")
        case .message: return String(localized: "notification.type.message")
        case .announcement: return String(localized: "notification.type.announcement")
        case .system: return String(localized: "notification.type.system")
        }
    }
}

/// Notifications list response
struct NotificationsResponse: Codable {
    let data: [AppNotification]
    let total: Int
}

// MARK: - View State

/// Notifications view state
enum NotificationsViewState {
    case idle
    case loading
    case loaded([AppNotification])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var notifications: [AppNotification] {
        if case .loaded(let list) = self { return list }
        return []
    }
}

// MARK: - Filter

/// Notification filter
enum NotificationFilter: Hashable {
    case all
    case unread
    case type(NotificationType)

    var label: String {
        switch self {
        case .all: return String(localized: "notification.filter.all")
        case .unread: return String(localized: "notification.filter.unread")
        case .type(let type): return type.label
        }
    }
}

// MARK: - Grouped Notifications

/// Notifications grouped by date
struct NotificationGroup: Identifiable {
    let id: String
    let title: String
    let notifications: [AppNotification]

    init(date: Date, notifications: [AppNotification]) {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            self.title = String(localized: "notification.group.today")
        } else if calendar.isDateInYesterday(date) {
            self.title = String(localized: "notification.group.yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.title = formatter.string(from: date)
        }
        self.id = title
        self.notifications = notifications
    }
}
