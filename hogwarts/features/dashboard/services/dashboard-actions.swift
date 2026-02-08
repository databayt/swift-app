import Foundation

/// Dashboard API actions
/// Mirrors: src/components/platform/dashboard/actions.ts
struct DashboardActions {
    private let api = APIClient.shared

    /// Fetch today's schedule for a student
    func fetchTodaySchedule(schoolId: String) async throws -> [DashboardScheduleItem] {
        try await api.get("/timetable/today?schoolId=\(schoolId)", as: [DashboardScheduleItem].self)
    }

    /// Fetch recent grades for a student
    func fetchRecentGrades(schoolId: String, studentId: String) async throws -> [DashboardGradeItem] {
        try await api.get(
            "/grades/recent?schoolId=\(schoolId)&studentId=\(studentId)&limit=5",
            as: [DashboardGradeItem].self
        )
    }

    /// Fetch attendance summary for a student
    func fetchAttendanceSummary(schoolId: String, studentId: String) async throws -> DashboardAttendanceSummary {
        try await api.get(
            "/attendance/summary?schoolId=\(schoolId)&studentId=\(studentId)",
            as: DashboardAttendanceSummary.self
        )
    }

    /// Fetch today's classes for a teacher
    func fetchTodayClasses(schoolId: String) async throws -> [DashboardClassItem] {
        try await api.get("/timetable/today/teacher?schoolId=\(schoolId)", as: [DashboardClassItem].self)
    }

    /// Fetch guardian's children
    func fetchChildren(schoolId: String) async throws -> [DashboardChild] {
        try await api.get("/auth/children?schoolId=\(schoolId)", as: [DashboardChild].self)
    }

    /// Fetch recent messages
    func fetchRecentMessages(schoolId: String, limit: Int = 5) async throws -> [DashboardMessagePreview] {
        try await api.get("/messages/recent?schoolId=\(schoolId)&limit=\(limit)", as: [DashboardMessagePreview].self)
    }
}
