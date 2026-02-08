import Foundation
import Testing
@testable import Hogwarts

/// Tests for Notifications feature types, router, and filter
@Suite("Notifications")
struct NotificationsTests {

    // MARK: - NotificationType

    @Test("NotificationType rawValues are correct")
    func notificationTypeRawValues() {
        #expect(NotificationType.attendance.rawValue == "attendance")
        #expect(NotificationType.grade.rawValue == "grade")
        #expect(NotificationType.message.rawValue == "message")
        #expect(NotificationType.announcement.rawValue == "announcement")
        #expect(NotificationType.system.rawValue == "system")
    }

    @Test("NotificationType has 5 cases")
    func notificationTypeCaseCount() {
        #expect(NotificationType.allCases.count == 5)
    }

    @Test("NotificationType icons are non-empty")
    func notificationTypeIcons() {
        for type in NotificationType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    @Test("NotificationType specific icons")
    func notificationTypeSpecificIcons() {
        #expect(NotificationType.attendance.icon == "checkmark.circle")
        #expect(NotificationType.grade.icon == "chart.bar")
        #expect(NotificationType.message.icon == "bubble.left")
        #expect(NotificationType.announcement.icon == "megaphone")
        #expect(NotificationType.system.icon == "gear")
    }

    // MARK: - AppNotification

    @Test("AppNotification notificationType parses known type")
    func appNotificationTypeKnown() {
        let notification = AppNotification(
            id: "n_1", userId: "u_1", type: "grade",
            title: "New Grade", message: "You received a grade",
            schoolId: "school_1", data: nil, isRead: false,
            createdAt: Date()
        )
        #expect(notification.notificationType == .grade)
    }

    @Test("AppNotification notificationType defaults to system for unknown type")
    func appNotificationTypeUnknown() {
        let notification = AppNotification(
            id: "n_1", userId: "u_1", type: "unknown_type",
            title: "Something", message: "...",
            schoolId: "school_1", data: nil, isRead: false,
            createdAt: Date()
        )
        #expect(notification.notificationType == .system)
    }

    // MARK: - NotificationRouter

    @Test("NotificationRouter routes attendance type to attendance destination")
    func routerAttendance() {
        let notification = AppNotification(
            id: "n_1", userId: "u_1", type: "attendance",
            title: "Attendance", message: "Marked present",
            schoolId: "school_1", data: "{\"id\": \"att_123\"}",
            isRead: false, createdAt: Date()
        )
        let dest = NotificationRouter.destination(from: notification)
        if case .attendance(let recordId) = dest {
            #expect(recordId == "att_123")
        } else {
            #expect(Bool(false), "Expected .attendance destination")
        }
    }

    @Test("NotificationRouter routes message type to message destination")
    func routerMessage() {
        let notification = AppNotification(
            id: "n_1", userId: "u_1", type: "message",
            title: "New Message", message: "Hello",
            schoolId: "school_1", data: "{\"id\": \"conv_456\"}",
            isRead: false, createdAt: Date()
        )
        let dest = NotificationRouter.destination(from: notification)
        if case .message(let conversationId) = dest {
            #expect(conversationId == "conv_456")
        } else {
            #expect(Bool(false), "Expected .message destination")
        }
    }

    @Test("NotificationRouter routes system type to dashboard")
    func routerSystem() {
        let notification = AppNotification(
            id: "n_1", userId: "u_1", type: "system",
            title: "System", message: "Maintenance",
            schoolId: "school_1", data: nil,
            isRead: false, createdAt: Date()
        )
        let dest = NotificationRouter.destination(from: notification)
        if case .dashboard = dest {
            // Expected
        } else {
            #expect(Bool(false), "Expected .dashboard destination")
        }
    }

    @Test("NotificationRouter from userInfo parses type and id")
    func routerFromUserInfo() {
        let userInfo: [AnyHashable: Any] = [
            "type": "grade",
            "id": "result_789"
        ]
        let dest = NotificationRouter.destination(from: userInfo)
        #expect(dest != nil)
        if case .grade(let resultId) = dest {
            #expect(resultId == "result_789")
        } else {
            #expect(Bool(false), "Expected .grade destination")
        }
    }

    @Test("NotificationRouter from userInfo returns nil for missing type")
    func routerFromUserInfoNilType() {
        let userInfo: [AnyHashable: Any] = [:]
        let dest = NotificationRouter.destination(from: userInfo)
        #expect(dest == nil)
    }

    @Test("NotificationRouter from userInfo returns dashboard for unknown type")
    func routerFromUserInfoUnknown() {
        let userInfo: [AnyHashable: Any] = [
            "type": "unknown"
        ]
        let dest = NotificationRouter.destination(from: userInfo)
        if case .dashboard = dest {
            // Expected
        } else {
            #expect(Bool(false), "Expected .dashboard destination")
        }
    }

    // MARK: - NotificationFilter

    @Test("NotificationFilter all label is not empty")
    func filterAllLabel() {
        let filter = NotificationFilter.all
        // Just ensure it does not crash and returns something
        #expect(!filter.label.isEmpty)
    }

    @Test("NotificationFilter unread label is not empty")
    func filterUnreadLabel() {
        let filter = NotificationFilter.unread
        #expect(!filter.label.isEmpty)
    }

    // MARK: - NotificationsViewState

    @Test("NotificationsViewState loading isLoading is true")
    func viewStateLoading() {
        let state = NotificationsViewState.loading
        #expect(state.isLoading)
    }

    @Test("NotificationsViewState idle returns empty notifications")
    func viewStateIdleEmpty() {
        let state = NotificationsViewState.idle
        #expect(state.notifications.isEmpty)
    }
}
