import SwiftUI

/// Profile and settings view
/// Mirrors: src/components/platform/profile/content.tsx
struct ProfileContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @Environment(\.locale) private var locale

    @State private var viewModel = ProfileViewModel()
    @State private var showLogoutAlert = false
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: authManager.currentUser?.imageUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.displayName ?? String(localized: "profile.defaultName"))
                                .font(.headline)
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(authManager.role.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                                .accessibilityLabel(String(localized: "a11y.profile.role \(authManager.role.displayName)"))
                        }
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                }

                // Settings
                Section(String(localized: "profile.settings")) {
                    NavigationLink {
                        EditProfileView(viewModel: viewModel)
                    } label: {
                        Label(String(localized: "profile.editProfile"), systemImage: "person")
                    }

                    NavigationLink {
                        NotificationPreferencesView()
                            .environment(tenantContext)
                    } label: {
                        Label(String(localized: "profile.notifications"), systemImage: "bell")
                    }

                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        Label(String(localized: "profile.language"), systemImage: "globe")
                    }

                    // Biometric toggle (if available)
                    biometricToggleRow
                }

                // Appearance (inline theme picker)
                Section(String(localized: "profile.appearance")) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            appTheme = theme.rawValue
                        } label: {
                            HStack {
                                Label(theme.displayName, systemImage: theme.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if appTheme == theme.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .accessibilityLabel(String(localized: "a11y.button.theme \(theme.displayName)"))
                        .accessibilityHint(appTheme == theme.rawValue ? String(localized: "a11y.profile.themeSelected") : String(localized: "a11y.profile.themeTapToSelect"))
                    }
                }

                // Support
                Section(String(localized: "profile.support")) {
                    NavigationLink {
                        Text(String(localized: "profile.help"))
                    } label: {
                        Label(String(localized: "profile.help"), systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        Text(String(localized: "profile.about"))
                    } label: {
                        Label(String(localized: "profile.about"), systemImage: "info.circle")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Label(String(localized: "profile.logout"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel(String(localized: "a11y.button.logout"))
                }
            }
            .navigationTitle(String(localized: "profile.title"))
            .alert(
                String(localized: "profile.logout.title"),
                isPresented: $showLogoutAlert
            ) {
                Button(String(localized: "common.cancel"), role: .cancel) {}
                Button(String(localized: "profile.logout"), role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text(String(localized: "profile.logout.message"))
            }
            .task {
                viewModel.setup(authManager: authManager, tenantContext: tenantContext)
            }
        }
    }

    // MARK: - Biometric Toggle

    @ViewBuilder
    private var biometricToggleRow: some View {
        if let biometricService = try? getBiometricService(), biometricService.isBiometricAvailable {
            Toggle(isOn: Binding(
                get: { biometricService.isBiometricEnabled },
                set: { enabled in
                    if enabled {
                        try? biometricService.enableBiometric()
                    } else {
                        biometricService.disableBiometric()
                    }
                }
            )) {
                Label(biometricService.biometricName, systemImage: biometricService.biometricIcon)
            }
            .accessibilityLabel(String(localized: "a11y.profile.biometricToggle \(biometricService.biometricName)"))
            .accessibilityHint(biometricService.isBiometricEnabled ? String(localized: "a11y.profile.biometricEnabled") : String(localized: "a11y.profile.biometricDisabled"))
        }
    }

    /// Try to get BiometricService from environment
    /// Returns nil if not injected (graceful degradation)
    @Environment(BiometricService.self) private var biometricServiceEnv
    private func getBiometricService() throws -> BiometricService {
        biometricServiceEnv
    }
}

struct LanguageSettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "ar"

    var body: some View {
        List {
            Button {
                selectedLanguage = "ar"
            } label: {
                HStack {
                    Text("العربية")
                    Spacer()
                    if selectedLanguage == "ar" {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .foregroundStyle(.primary)

            Button {
                selectedLanguage = "en"
            } label: {
                HStack {
                    Text("English")
                    Spacer()
                    if selectedLanguage == "en" {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle(String(localized: "profile.language"))
    }
}

#Preview {
    ProfileContent()
        .environment(AuthManager())
        .environment(TenantContext())
        .environment(BiometricService())
}
