import SwiftUI
import SwiftData

/// Main app entry point
/// Mirrors: src/app/layout.tsx
@main
struct HogwartsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var authManager = AuthManager()
    @State private var tenantContext = TenantContext()
    @State private var biometricService = BiometricService()
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(tenantContext)
                .environment(biometricService)
                .modelContainer(DataContainer.shared.container)
                .preferredColorScheme(resolvedColorScheme)
        }
    }

    /// Resolve @AppStorage theme to ColorScheme
    private var resolvedColorScheme: ColorScheme? {
        switch AppTheme(rawValue: appTheme) {
        case .light: return .light
        case .dark: return .dark
        case .system, .none: return nil
        }
    }
}

/// Root content view with auth check
/// Mirrors: src/app/[lang]/layout.tsx
struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @Environment(BiometricService.self) private var biometricService

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if tenantContext.isValid {
                    if biometricService.isBiometricEnabled && !biometricService.isUnlocked {
                        BiometricPromptView()
                    } else {
                        MainTabView()
                    }
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
            // Auto-unlock if biometric is disabled
            if !biometricService.isBiometricEnabled {
                biometricService.isUnlocked = true
            }
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

/// Main tab navigation — role-based tabs
/// Mirrors: src/app/[lang]/s/[subdomain]/(platform)/layout.tsx
///
/// Tab layout per role:
/// Admin/Dev: Dashboard, Students, Messages, Notifications, Profile
/// Teacher:   Dashboard, Schedule, Messages, Notifications, Profile
/// Student:   Dashboard, Schedule, Messages, Notifications, Profile
/// Guardian:  Dashboard, Schedule, Messages, Notifications, Profile
struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var selectedTab: AppTab = .dashboard
    @State private var navigationState = NotificationNavigationState()

    private var role: UserRole {
        authManager.role
    }

    /// Whether this role sees the Students tab (admin/dev only)
    private var showStudentsTab: Bool {
        role.isAdmin
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardContent()
                .tabItem {
                    Label(
                        String(localized: "tab.dashboard"),
                        systemImage: "house"
                    )
                }
                .tag(AppTab.dashboard)

            if showStudentsTab {
                StudentsContent()
                    .tabItem {
                        Label(
                            String(localized: "tab.students"),
                            systemImage: "person.2"
                        )
                    }
                    .tag(AppTab.students)
            } else {
                TimetableContent()
                    .tabItem {
                        Label(
                            String(localized: "tab.schedule"),
                            systemImage: "calendar"
                        )
                    }
                    .tag(AppTab.schedule)
            }

            MessagesContent()
                .tabItem {
                    Label(
                        String(localized: "tab.messages"),
                        systemImage: "bubble.left.and.bubble.right"
                    )
                }
                .tag(AppTab.messages)

            NotificationsContent()
                .tabItem {
                    Label(
                        String(localized: "tab.notifications"),
                        systemImage: "bell"
                    )
                }
                .tag(AppTab.notifications)

            ProfileContent()
                .tabItem {
                    Label(
                        String(localized: "tab.profile"),
                        systemImage: "person.circle"
                    )
                }
                .tag(AppTab.profile)
        }
        .environment(navigationState)
        .overlay(alignment: .top) {
            SyncStatusBanner()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveNotification)) { notification in
            if let destination = NotificationRouter.destination(from: notification.userInfo ?? [:]) {
                navigationState.navigate(to: destination)
                selectedTab = navigationState.selectedTab
            }
        }
    }
}
