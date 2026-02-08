import SwiftUI
import SwiftData

/// Main app entry point
/// Mirrors: src/app/layout.tsx
@main
struct HogwartsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var authManager = AuthManager()
    @State private var tenantContext = TenantContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(tenantContext)
                .modelContainer(DataContainer.shared.container)
        }
    }
}

/// Root content view with auth check
/// Mirrors: src/app/[lang]/layout.tsx
struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if tenantContext.isValid {
                    MainTabView()
                } else {
                    SchoolSelectionView()
                }
            } else {
                LoginView()
            }
        }
        .task {
            await authManager.restoreSession()
            restoreLastSchool()
        }
    }

    /// Restore last selected school from keychain on session restore
    private func restoreLastSchool() {
        if authManager.isAuthenticated,
           let lastSchoolId = KeychainService().get(.lastSchoolId),
           let sessionSchoolId = authManager.session?.schoolId,
           lastSchoolId == sessionSchoolId {
            tenantContext.setTenant(schoolId: lastSchoolId)
        } else if authManager.isAuthenticated,
                  let schoolId = authManager.session?.schoolId {
            tenantContext.setTenant(schoolId: schoolId)
        }
    }
}

/// Main tab navigation
/// Mirrors: src/app/[lang]/s/[subdomain]/(platform)/layout.tsx
struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        TabView {
            DashboardContent()
                .tabItem {
                    Label("dashboard", systemImage: "house")
                }

            StudentsContent()
                .tabItem {
                    Label("students", systemImage: "person.2")
                }

            AttendanceContent()
                .tabItem {
                    Label("attendance", systemImage: "checkmark.circle")
                }

            GradesContent()
                .tabItem {
                    Label("grades", systemImage: "chart.bar")
                }

            ProfileContent()
                .tabItem {
                    Label("profile", systemImage: "person.circle")
                }
        }
    }
}
