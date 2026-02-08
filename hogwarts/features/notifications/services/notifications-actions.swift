import Foundation

/// Server actions for Notifications feature
/// Mirrors: src/components/platform/notifications/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class NotificationsActions: Sendable {

    private let api = APIClient.shared

    // MARK: - Read Actions

    /// Get notifications list
    /// GET /notifications?schoolId=X
    func getNotifications(schoolId: String) async throws -> [AppNotification] {
        try await api.get(
            "/notifications",
            query: ["schoolId": schoolId],
            as: [AppNotification].self
        )
    }

    // MARK: - Write Actions

    /// Mark notification as read
    /// PUT /notifications/{id}/read
    func markAsRead(
        notificationId: String,
        schoolId: String
    ) async throws {
        struct ReadRequest: Encodable {
            let schoolId: String
        }

        let _: EmptyResponse = try await api.put(
            "/notifications/\(notificationId)/read",
            body: ReadRequest(schoolId: schoolId)
        )
    }

    /// Mark all notifications as read
    /// PUT /notifications/read-all?schoolId=X
    func markAllAsRead(schoolId: String) async throws {
        struct ReadAllRequest: Encodable {
            let schoolId: String
        }

        let _: EmptyResponse = try await api.put(
            "/notifications/read-all",
            body: ReadAllRequest(schoolId: schoolId)
        )
    }

    /// Delete a notification
    /// DELETE /notifications/{id}
    func deleteNotification(
        notificationId: String,
        schoolId: String
    ) async throws {
        try await api.delete("/notifications/\(notificationId)?schoolId=\(schoolId)")
    }
}
