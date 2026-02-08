import SwiftUI

/// ViewModel for teacher dashboard
/// Fetches today's classes and tracks attendance marking
@Observable
@MainActor
final class TeacherDashboardViewModel {
    private let actions = DashboardActions()

    var classes: [DashboardClassItem] = []
    var isLoading = false
    var error: Error?
    var lastUpdated: Date?

    /// Classes that haven't had attendance marked
    var pendingClasses: [DashboardClassItem] {
        classes.filter { !$0.attendanceMarked }
    }

    /// Whether all classes have attendance marked
    var allAttendanceMarked: Bool {
        !classes.isEmpty && pendingClasses.isEmpty
    }

    /// Load teacher dashboard data
    func load(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            classes = try await actions.fetchTodayClasses(schoolId: schoolId)
            lastUpdated = Date()
        } catch {
            self.error = error
        }
    }
}
