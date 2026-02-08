import SwiftUI

/// Guardian dashboard with child selector, schedule, grades, attendance, and messages
/// Mirrors: src/components/platform/dashboard/guardian-dashboard.tsx
struct GuardianDashboard: View {
    @Environment(TenantContext.self) private var tenantContext

    @State private var viewModel = GuardianDashboardViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading && viewModel.children.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ChildSelector(
                    children: viewModel.children,
                    selectedChild: viewModel.selectedChild
                ) { child in
                    Task {
                        guard let schoolId = tenantContext.schoolId else { return }
                        await viewModel.selectChild(child, schoolId: schoolId)
                    }
                }

                if viewModel.children.count == 1, let child = viewModel.selectedChild {
                    HStack {
                        Text(child.displayName)
                            .font(.headline)
                        if let yearLevel = child.yearLevel {
                            Text("- \(yearLevel)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                scheduleCard
                gradesCard
                attendanceCard
                messagesCard
            }
        }
        .task {
            guard let schoolId = tenantContext.schoolId else { return }
            await viewModel.load(schoolId: schoolId)
        }
    }

    // MARK: - Schedule

    @ViewBuilder
    private var scheduleCard: some View {
        DashboardCard(title: String(localized: "dashboard.todaySchedule"), systemImage: "calendar") {
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
                            Text("\(item.startTime) - \(item.endTime)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let teacher = item.teacherName {
                            Text(teacher)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Grades

    @ViewBuilder
    private var gradesCard: some View {
        DashboardCard(title: String(localized: "dashboard.recentGrades"), systemImage: "chart.bar") {
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
                ForEach(currentGrades) { (grade: DashboardGradeItem) in
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

    // MARK: - Attendance

    @ViewBuilder
    private var attendanceCard: some View {
        DashboardCard(title: String(localized: "dashboard.attendance"), systemImage: "checkmark.circle") {
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
                    statView(String(localized: "dashboard.present"), attendance.presentDays, .green)
                    statView(String(localized: "dashboard.absent"), attendance.absentDays, .red)
                    statView(String(localized: "dashboard.late"), attendance.lateDays, .orange)
                }
            }
        }
    }

    // Helper properties to break @Observable binding inference for ForEach
    private var currentSchedule: [DashboardScheduleItem] { viewModel.schedule }
    private var currentGrades: [DashboardGradeItem] { viewModel.grades }
    private var currentMessages: [DashboardMessagePreview] { viewModel.messages }

    private func statView(_ label: String, _ count: Int, _ color: Color) -> some View {
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

    // MARK: - Messages

    @ViewBuilder
    private var messagesCard: some View {
        DashboardCard(title: String(localized: "dashboard.recentMessages"), systemImage: "message") {
            messagesContent
        }
    }

    @ViewBuilder
    private var messagesContent: some View {
        if viewModel.messages.isEmpty {
            Text(String(localized: "dashboard.noMessages"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 8) {
                ForEach(currentMessages) { message in
                    HStack {
                        Circle()
                            .fill(message.isRead ? Color.clear : Color.blue)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(message.senderName)
                                .font(.subheadline)
                                .fontWeight(message.isRead ? .regular : .semibold)
                            Text(message.preview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(message.date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
