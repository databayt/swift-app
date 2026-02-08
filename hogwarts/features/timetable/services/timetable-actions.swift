import Foundation

/// Server actions for Timetable feature
/// Mirrors: src/components/platform/timetable/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class TimetableActions: Sendable {

    private let api = APIClient.shared

    // MARK: - Read Actions

    /// Get weekly schedule
    /// GET /timetable?schoolId=X&termId=Y&classId=Z
    func getWeeklySchedule(
        schoolId: String,
        termId: String? = nil,
        classId: String? = nil
    ) async throws -> WeeklyScheduleResponse {
        var params: [String: String] = ["schoolId": schoolId]

        if let termId {
            params["termId"] = termId
        }
        if let classId {
            params["classId"] = classId
        }

        return try await api.get("/timetable", query: params, as: WeeklyScheduleResponse.self)
    }

    /// Get today's schedule
    /// GET /timetable/today?schoolId=X
    func getDailySchedule(
        schoolId: String,
        date: Date? = nil
    ) async throws -> [TimetableEntry] {
        var params: [String: String] = ["schoolId": schoolId]

        if let date {
            let formatter = ISO8601DateFormatter()
            params["date"] = formatter.string(from: date)
        }

        return try await api.get("/timetable/today", query: params, as: [TimetableEntry].self)
    }

    /// Get class details
    /// GET /classes/{id}?schoolId=X
    func getClassDetails(
        classId: String,
        schoolId: String
    ) async throws -> ClassDetailResponse {
        return try await api.get(
            "/classes/\(classId)",
            query: ["schoolId": schoolId],
            as: ClassDetailResponse.self
        )
    }
}
