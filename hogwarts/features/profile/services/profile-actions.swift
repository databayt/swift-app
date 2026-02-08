import Foundation

/// Server actions for Profile feature
/// Mirrors: src/components/platform/profile/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class ProfileActions: Sendable {

    private let api = APIClient.shared

    // MARK: - Profile

    /// Get current user profile
    func getProfile(schoolId: String) async throws -> User {
        return try await api.get(
            "/profile",
            query: ["schoolId": schoolId],
            as: User.self
        )
    }

    /// Update profile fields
    func updateProfile(
        _ request: UpdateProfileRequest,
        schoolId: String
    ) async throws -> User {
        struct UpdateRequest: Encodable {
            let profile: UpdateProfileRequest
            let schoolId: String
        }

        let body = UpdateRequest(profile: request, schoolId: schoolId)
        return try await api.put("/profile", body: body, as: User.self)
    }

    // MARK: - Notification Preferences

    /// Get notification preferences
    func getNotificationPreferences(schoolId: String) async throws -> NotificationPreferences {
        return try await api.get(
            "/notifications/preferences",
            query: ["schoolId": schoolId],
            as: NotificationPreferences.self
        )
    }

    /// Update notification preferences
    func updateNotificationPreferences(
        _ preferences: NotificationPreferences,
        schoolId: String
    ) async throws {
        struct PreferencesRequest: Encodable {
            let preferences: NotificationPreferences
            let schoolId: String
        }

        let body = PreferencesRequest(preferences: preferences, schoolId: schoolId)
        _ = try await api.put("/notifications/preferences", body: body, as: NotificationPreferences.self)
    }
}
