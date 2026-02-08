import SwiftUI

/// Admin Dashboard View
/// Mirrors: src/components/platform/dashboard/admin.tsx
struct AdminDashboard: View {
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = AdminDashboardViewModel()

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 20) {
                    // Stats grid (2x2)
                    statsGrid

                    // Attendance overview
                    attendanceOverview

                    // Grade performance
                    gradePerformanceCard

                    // Recent activity
                    recentActivityCard

                    // Quick navigation
                    quickNavigation
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            viewModel.setup(tenantContext: tenantContext)
            await viewModel.load()
        }
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: String(localized: "dashboard.admin.students"),
                value: "\(viewModel.studentCount)",
                icon: "person.2",
                color: .blue
            )

            StatCard(
                title: String(localized: "dashboard.admin.teachers"),
                value: "\(viewModel.teacherCount)",
                icon: "person.3",
                color: .green
            )

            StatCard(
                title: String(localized: "dashboard.admin.attendance"),
                value: "\(Int(viewModel.attendanceRate))%",
                icon: "checkmark.circle",
                color: viewModel.attendanceRate >= 90 ? .green : .orange
            )

            StatCard(
                title: String(localized: "dashboard.admin.avgGrade"),
                value: "\(Int(viewModel.averageGrade))%",
                icon: "chart.bar",
                color: viewModel.averageGrade >= 75 ? .green : .orange
            )
        }
    }

    // MARK: - Attendance Overview

    @ViewBuilder
    private var attendanceOverview: some View {
        if let attendance = viewModel.todayAttendance {
            DashboardCard(
                title: String(localized: "dashboard.admin.todayAttendance"),
                systemImage: "calendar.badge.checkmark"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("\(Int(attendance.rate))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(attendance.rate >= 90 ? .green : .orange)
                        Spacer()
                        Text(String(localized: "dashboard.admin.ofStudents \(attendance.totalStudents)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.secondary.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(attendance.rate >= 90 ? .green : .orange)
                                .frame(width: geometry.size.width * min(attendance.rate / 100, 1.0))
                        }
                    }
                    .frame(height: 8)

                    HStack(spacing: 16) {
                        AttendancePill(count: attendance.presentCount, label: String(localized: "attendance.status.present"), color: .green)
                        AttendancePill(count: attendance.absentCount, label: String(localized: "attendance.status.absent"), color: .red)
                        AttendancePill(count: attendance.lateCount, label: String(localized: "attendance.status.late"), color: .orange)
                    }
                }
            }
        }
    }

    // MARK: - Grade Performance

    @ViewBuilder
    private var gradePerformanceCard: some View {
        if let performance = viewModel.gradePerformance {
            DashboardCard(
                title: String(localized: "dashboard.admin.gradePerformance"),
                systemImage: "chart.bar"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(localized: "dashboard.admin.avgScore"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(performance.averageScore))%")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(String(localized: "dashboard.admin.passRate"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(performance.passRate))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(performance.passRate >= 80 ? .green : .orange)
                        }
                    }

                    // Distribution bars
                    HStack(spacing: 4) {
                        GradeBar(count: performance.excellentCount, label: "A", color: .green)
                        GradeBar(count: performance.goodCount, label: "B", color: .blue)
                        GradeBar(count: performance.averageCount, label: "C", color: .orange)
                        GradeBar(count: performance.failCount, label: "F", color: .red)
                    }
                    .frame(height: 60)
                }
            }
        }
    }

    // MARK: - Recent Activity

    @ViewBuilder
    private var recentActivityCard: some View {
        DashboardCard(
            title: String(localized: "dashboard.admin.recentActivity"),
            systemImage: "clock"
        ) {
            if viewModel.recentActivity.isEmpty {
                Text(String(localized: "dashboard.admin.noActivity"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentActivity.prefix(5)) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.activityIcon)
                                .foregroundStyle(item.activityColor)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(item.timestamp)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)

                        if item.id != viewModel.recentActivity.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Navigation

    @ViewBuilder
    private var quickNavigation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.admin.quickNav"))
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickNavItem(title: String(localized: "students.title"), icon: "person.2", color: .blue)
                QuickNavItem(title: String(localized: "attendance.title"), icon: "checkmark.circle", color: .green)
                QuickNavItem(title: String(localized: "grades.title"), icon: "chart.bar", color: .purple)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

// MARK: - Grade Bar

struct GradeBar: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(height: max(CGFloat(count) * 3, 4))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Attendance Pill

struct AttendancePill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Quick Nav Item

struct QuickNavItem: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    AdminDashboard()
        .environment(TenantContext())
}
