import SwiftUI

/// Student dashboard with schedule, grades, and attendance
/// Mirrors: src/components/platform/dashboard/student-dashboard.tsx
struct StudentDashboard: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    @State private var viewModel = StudentDashboardViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                scheduleCard
                gradesCard
                attendanceCard
            }
        }
        .task {
            guard let schoolId = tenantContext.schoolId,
                  let userId = authManager.currentUser?.id else { return }
            await viewModel.load(schoolId: schoolId, studentId: userId)
        }
    }

    // MARK: - Schedule Card

    @ViewBuilder
    private var scheduleCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.todaySchedule"),
            systemImage: "calendar"
        ) {
            scheduleContent
        }
    }

    @ViewBuilder
    private var scheduleContent: some View {
        if viewModel.schedule.isEmpty {
            Text(String(localized: "dashboard.noClasses"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 8) {
                ForEach(currentSchedule) { item in
                    HStack {
                        Circle()
                            .fill(item.isCurrent == true ? Color.green : Color.clear)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.subheadline)
                                .fontWeight(item.isCurrent == true ? .semibold : .regular)

                            HStack(spacing: 4) {
                                Text("\(item.startTime) - \(item.endTime)")
                                if let room = item.room {
                                    Text("| \(room)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if item.isCurrent == true {
                            Text(String(localized: "dashboard.currentClass"))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Grades Card

    @ViewBuilder
    private var gradesCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.recentGrades"),
            systemImage: "chart.bar"
        ) {
            gradesContent
        }
    }

    @ViewBuilder
    private var gradesContent: some View {
        if viewModel.grades.isEmpty {
            Text(String(localized: "dashboard.noGrades"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 8) {
                ForEach(currentGrades) { grade in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(grade.displaySubject)
                                .font(.subheadline)
                            Text(grade.examName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(grade.score))/\(Int(grade.maxScore))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(grade.percentage >= 60 ? Color.primary : Color.red)
                    }
                }
            }
        }
    }

    // MARK: - Attendance Card

    @ViewBuilder
    private var attendanceCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.attendance"),
            systemImage: "checkmark.circle"
        ) {
            attendanceContent
        }
    }

    @ViewBuilder
    private var attendanceContent: some View {
        if let attendance = viewModel.attendance {
            VStack(spacing: 12) {
                HStack {
                    Text(String(localized: "dashboard.attendanceRate"))
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(attendance.attendanceRate))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(attendance.attendanceRate >= 80 ? .green : .orange)
                }

                HStack(spacing: 16) {
                    attendanceStat(
                        label: String(localized: "dashboard.present"),
                        count: attendance.presentDays,
                        color: .green
                    )
                    attendanceStat(
                        label: String(localized: "dashboard.absent"),
                        count: attendance.absentDays,
                        color: .red
                    )
                    attendanceStat(
                        label: String(localized: "dashboard.late"),
                        count: attendance.lateDays,
                        color: .orange
                    )
                }
            }
        } else {
            Text(String(localized: "dashboard.noClasses"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // Helper properties to break @Observable binding inference for ForEach
    private var currentSchedule: [DashboardScheduleItem] { viewModel.schedule }
    private var currentGrades: [DashboardGradeItem] { viewModel.grades }

    private func attendanceStat(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
