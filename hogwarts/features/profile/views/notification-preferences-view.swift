import SwiftUI
import UserNotifications

/// Notification preferences settings
/// Mirrors: src/components/platform/profile/notification-preferences.tsx
struct NotificationPreferencesView: View {
    @Environment(TenantContext.self) private var tenantContext

    @State private var preferences = NotificationPreferences.default
    @State private var isLoading = true
    @State private var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    private let actions = ProfileActions()

    var body: some View {
        List {
            // Push notification status
            Section {
                pushStatusRow
            } footer: {
                if pushAuthorizationStatus == .denied {
                    Text(String(localized: "notification.prefs.deniedFooter"))
                }
            }

            // Per-type toggles
            Section(String(localized: "notification.prefs.categories")) {
                ForEach(NotificationType.allCases, id: \.rawValue) { type in
                    Toggle(isOn: binding(for: type)) {
                        Label(type.label, systemImage: type.icon)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .navigationTitle(String(localized: "profile.notifications"))
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadPreferences()
            await checkPushAuthorization()
        }
    }

    // MARK: - Push Status

    @ViewBuilder
    private var pushStatusRow: some View {
        HStack {
            Label(
                String(localized: "notification.prefs.pushNotifications"),
                systemImage: "bell.badge"
            )
            Spacer()
            switch pushAuthorizationStatus {
            case .authorized, .provisional:
                Text(String(localized: "notification.prefs.enabled"))
                    .foregroundStyle(.green)
            case .denied:
                Button(String(localized: "notification.prefs.openSettings")) {
                    openSystemSettings()
                }
                .foregroundStyle(.blue)
            case .notDetermined:
                Button(String(localized: "notification.prefs.enable")) {
                    Task { await requestPushPermission() }
                }
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Bindings

    private func binding(for type: NotificationType) -> Binding<Bool> {
        Binding(
            get: {
                switch type {
                case .attendance: return preferences.attendance
                case .grade: return preferences.grade
                case .message: return preferences.message
                case .announcement: return preferences.announcement
                case .system: return preferences.system
                }
            },
            set: { newValue in
                switch type {
                case .attendance: preferences.attendance = newValue
                case .grade: preferences.grade = newValue
                case .message: preferences.message = newValue
                case .announcement: preferences.announcement = newValue
                case .system: preferences.system = newValue
                }
                Task { await savePreferences() }
            }
        )
    }

    // MARK: - Actions

    private func loadPreferences() async {
        guard let schoolId = tenantContext.schoolId else {
            isLoading = false
            return
        }

        do {
            preferences = try await actions.getNotificationPreferences(schoolId: schoolId)
        } catch {
            // Use defaults on failure
        }
        isLoading = false
    }

    private func savePreferences() async {
        guard let schoolId = tenantContext.schoolId else { return }

        do {
            try await actions.updateNotificationPreferences(preferences, schoolId: schoolId)
        } catch {
            // Silently fail — preferences will resync on next load
        }
    }

    private func checkPushAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        pushAuthorizationStatus = settings.authorizationStatus
    }

    private func requestPushPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            pushAuthorizationStatus = granted ? .authorized : .denied
        } catch {
            pushAuthorizationStatus = .denied
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
