import SwiftUI

/// ViewModel for student dashboard
/// Fetches schedule, grades, and attendance in parallel
@Observable
@MainActor
final class StudentDashboardViewModel {
    private let actions = DashboardActions()

    var schedule: [DashboardScheduleItem] = []
    var grades: [DashboardGradeItem] = []
    var attendance: DashboardAttendanceSummary?
    var isLoading = false
    var error: Error?
    var lastUpdated: Date?

    /// Load all dashboard data in parallel
    func load(schoolId: String, studentId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let scheduleData = actions.fetchTodaySchedule(schoolId: schoolId)
            async let gradesData = actions.fetchRecentGrades(schoolId: schoolId, studentId: studentId)
            async let attendanceData = actions.fetchAttendanceSummary(schoolId: schoolId, studentId: studentId)

            let (s, g, a) = try await (scheduleData, gradesData, attendanceData)
            schedule = s
            grades = g
            attendance = a
            lastUpdated = Date()
        } catch {
            self.error = error
        }
    }
}
