import SwiftUI

/// ViewModel for Admin Dashboard
/// Mirrors: src/components/platform/dashboard/admin.tsx
@Observable
@MainActor
final class AdminDashboardViewModel {
    private let actions = DashboardActions()
    private var tenantContext: TenantContext?

    // State
    var isLoading = true
    var error: Error?

    // Stats
    var studentCount = 0
    var teacherCount = 0
    var attendanceRate: Double = 0
    var averageGrade: Double = 0

    // Attendance today
    var todayAttendance: AdminTodayAttendance?

    // Grade performance
    var gradePerformance: AdminGradePerformance?

    // Recent activity
    var recentActivity: [AdminActivityItem] = []

    // MARK: - Setup

    func setup(tenantContext: TenantContext) {
        self.tenantContext = tenantContext
    }

    // MARK: - Load

    func load() async {
        guard let schoolId = tenantContext?.schoolId else { return }

        isLoading = true

        do {
            async let statsResult = fetchStats(schoolId: schoolId)
            async let attendanceResult = fetchTodayAttendance(schoolId: schoolId)
            async let gradeResult = fetchGradePerformance(schoolId: schoolId)
            async let activityResult = fetchRecentActivity(schoolId: schoolId)

            _ = await (statsResult, attendanceResult, gradeResult, activityResult)
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    // MARK: - Fetch Methods

    private func fetchStats(schoolId: String) async {
        do {
            let stats = try await APIClient.shared.get(
                "/dashboard/admin/stats",
                query: ["schoolId": schoolId],
                as: AdminDashboardStats.self
            )
            studentCount = stats.studentCount
            teacherCount = stats.teacherCount
            attendanceRate = stats.attendanceRate
            averageGrade = stats.averageGrade
        } catch {
            print("Failed to load admin stats: \(error)")
        }
    }

    private func fetchTodayAttendance(schoolId: String) async {
        do {
            todayAttendance = try await APIClient.shared.get(
                "/dashboard/admin/attendance-today",
                query: ["schoolId": schoolId],
                as: AdminTodayAttendance.self
            )
        } catch {
            print("Failed to load today attendance: \(error)")
        }
    }

    private func fetchGradePerformance(schoolId: String) async {
        do {
            gradePerformance = try await APIClient.shared.get(
                "/dashboard/admin/grade-performance",
                query: ["schoolId": schoolId],
                as: AdminGradePerformance.self
            )
        } catch {
            print("Failed to load grade performance: \(error)")
        }
    }

    private func fetchRecentActivity(schoolId: String) async {
        do {
            recentActivity = try await APIClient.shared.get(
                "/dashboard/admin/activity",
                query: ["schoolId": schoolId, "limit": "20"],
                as: [AdminActivityItem].self
            )
        } catch {
            print("Failed to load recent activity: \(error)")
        }
    }
}
