import SwiftUI

/// ViewModel for guardian dashboard
/// Manages children list and per-child dashboard data
@Observable
@MainActor
final class GuardianDashboardViewModel {
    private let actions = DashboardActions()

    var children: [DashboardChild] = []
    var selectedChild: DashboardChild?
    var schedule: [DashboardScheduleItem] = []
    var grades: [DashboardGradeItem] = []
    var attendance: DashboardAttendanceSummary?
    var messages: [DashboardMessagePreview] = []
    var isLoading = false
    var error: Error?
    var lastUpdated: Date?

    /// Load children list and select first/only child
    func load(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            children = try await actions.fetchChildren(schoolId: schoolId)
            if let first = children.first {
                selectedChild = first
                await loadChildData(schoolId: schoolId, childId: first.id)
            }
        } catch {
            self.error = error
        }
    }

    /// Switch selected child and reload data
    func selectChild(_ child: DashboardChild, schoolId: String) async {
        selectedChild = child
        await loadChildData(schoolId: schoolId, childId: child.id)
    }

    /// Load dashboard data for a specific child in parallel
    private func loadChildData(schoolId: String, childId: String) async {
        do {
            async let scheduleData = actions.fetchTodaySchedule(schoolId: schoolId)
            async let gradesData = actions.fetchRecentGrades(schoolId: schoolId, studentId: childId)
            async let attendanceData = actions.fetchAttendanceSummary(schoolId: schoolId, studentId: childId)
            async let messagesData = actions.fetchRecentMessages(schoolId: schoolId)

            let (s, g, a, m) = try await (scheduleData, gradesData, attendanceData, messagesData)
            schedule = s
            grades = g
            attendance = a
            messages = m
            lastUpdated = Date()
        } catch {
            self.error = error
        }
    }
}
