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
            StudentDashboard()
        case .teacher:
            TeacherDashboard()
        case .guardian:
            GuardianDashboard()
        case .admin, .developer:
            AdminDashboard()
        default:
            DefaultDashboardContent()
        }
    }
}

// MARK: - Placeholder Views (Default — Sprint 2)

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
                    .foregroundStyle(Color.accentColor)
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
