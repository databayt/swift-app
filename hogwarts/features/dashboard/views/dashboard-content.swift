import SwiftUI

/// Dashboard view - role-specific
/// Mirrors: src/components/platform/dashboard/content.tsx
struct DashboardContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader

                    // Role-specific content
                    roleSpecificContent
                }
                .padding()
            }
            .navigationTitle(String(localized: "dashboard.title"))
            .refreshable {
                // Refresh dashboard data
            }
        }
    }

    @ViewBuilder
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "dashboard.welcome"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(authManager.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            AsyncImage(url: URL(string: authManager.currentUser?.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var roleSpecificContent: some View {
        switch authManager.role {
        case .student:
            StudentDashboardContent()
        case .teacher:
            TeacherDashboardContent()
        case .guardian:
            GuardianDashboardContent()
        case .admin, .developer:
            AdminDashboardContent()
        default:
            DefaultDashboardContent()
        }
    }
}

// MARK: - Role-Specific Views

struct StudentDashboardContent: View {
    var body: some View {
        VStack(spacing: 16) {
            // Today's schedule
            DashboardCard(
                title: String(localized: "dashboard.todaySchedule"),
                systemImage: "calendar"
            ) {
                Text("Schedule content")
            }

            // Recent grades
            DashboardCard(
                title: String(localized: "dashboard.recentGrades"),
                systemImage: "chart.bar"
            ) {
                Text("Grades content")
            }

            // Attendance summary
            DashboardCard(
                title: String(localized: "dashboard.attendance"),
                systemImage: "checkmark.circle"
            ) {
                Text("Attendance content")
            }
        }
    }
}

struct TeacherDashboardContent: View {
    var body: some View {
        VStack(spacing: 16) {
            DashboardCard(
                title: String(localized: "dashboard.todayClasses"),
                systemImage: "person.3"
            ) {
                Text("Classes content")
            }

            DashboardCard(
                title: String(localized: "dashboard.pendingGrades"),
                systemImage: "pencil.and.list.clipboard"
            ) {
                Text("Pending grades")
            }
        }
    }
}

struct GuardianDashboardContent: View {
    var body: some View {
        VStack(spacing: 16) {
            DashboardCard(
                title: String(localized: "dashboard.children"),
                systemImage: "person.2"
            ) {
                Text("Children overview")
            }
        }
    }
}

struct AdminDashboardContent: View {
    var body: some View {
        VStack(spacing: 16) {
            DashboardCard(
                title: String(localized: "dashboard.schoolOverview"),
                systemImage: "building.2"
            ) {
                Text("School metrics")
            }
        }
    }
}

struct DefaultDashboardContent: View {
    var body: some View {
        Text(String(localized: "dashboard.welcome"))
    }
}

// MARK: - Dashboard Card

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            content()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    DashboardContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
