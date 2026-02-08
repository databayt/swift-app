import SwiftUI

/// Teacher dashboard with classes, pending attendance, and quick actions
/// Mirrors: src/components/platform/dashboard/teacher-dashboard.tsx
struct TeacherDashboard: View {
    @Environment(TenantContext.self) private var tenantContext

    @State private var viewModel = TeacherDashboardViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                classesCard
                pendingAttendanceCard
                quickActionsCard
            }
        }
        .task {
            guard let schoolId = tenantContext.schoolId else { return }
            await viewModel.load(schoolId: schoolId)
        }
    }

    // MARK: - Today's Classes

    @ViewBuilder
    private var classesCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.todayClasses"),
            systemImage: "person.3"
        ) {
            classesContent
        }
    }

    @ViewBuilder
    private var classesContent: some View {
        if viewModel.classes.isEmpty {
            Text(String(localized: "dashboard.noClasses"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 10) {
                ForEach(currentClasses) { classItem in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(classItem.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 4) {
                                Text("\(classItem.startTime) - \(classItem.endTime)")
                                if let room = classItem.room {
                                    Text("| \(room)")
                                }
                                if let yearLevel = classItem.yearLevel {
                                    Text("| \(yearLevel)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(String(format: String(localized: "dashboard.studentsCount"), classItem.studentCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: classItem.attendanceMarked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(classItem.attendanceMarked ? .green : .secondary)
                    }
                }
            }
        }
    }

    // MARK: - Pending Attendance

    @ViewBuilder
    private var pendingAttendanceCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.pendingAttendance"),
            systemImage: "exclamationmark.circle"
        ) {
            pendingContent
        }
    }

    @ViewBuilder
    private var pendingContent: some View {
        if viewModel.allAttendanceMarked {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(String(localized: "dashboard.allAttendanceMarked"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 8) {
                ForEach(currentPendingClasses) { classItem in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(classItem.displayName)
                                .font(.subheadline)
                            Text("\(classItem.startTime) - \(classItem.endTime)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(String(localized: "dashboard.markAttendance")) {
                            // Navigate to attendance marking
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.quickActions"),
            systemImage: "bolt"
        ) {
            HStack(spacing: 12) {
                quickActionButton(
                    title: String(localized: "dashboard.takeAttendance"),
                    systemImage: "checkmark.circle",
                    color: .blue
                )
                quickActionButton(
                    title: String(localized: "dashboard.enterGrades"),
                    systemImage: "pencil.line",
                    color: .purple
                )
                quickActionButton(
                    title: String(localized: "dashboard.messages"),
                    systemImage: "message",
                    color: .green
                )
            }
        }
    }

    // Helper properties to break @Observable binding inference for ForEach
    private var currentClasses: [DashboardClassItem] { viewModel.classes }
    private var currentPendingClasses: [DashboardClassItem] { viewModel.pendingClasses }

    private func quickActionButton(title: String, systemImage: String, color: Color) -> some View {
        Button {
            // Navigate to action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
