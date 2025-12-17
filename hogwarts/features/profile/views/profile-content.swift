import SwiftUI

/// Profile and settings view
/// Mirrors: src/components/platform/profile/content.tsx
struct ProfileContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.locale) private var locale

    @State private var showLogoutAlert = false

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

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.displayName ?? "User")
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
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Settings
                Section(String(localized: "profile.settings")) {
                    NavigationLink {
                        Text("Edit Profile")
                    } label: {
                        Label(String(localized: "profile.editProfile"), systemImage: "person")
                    }

                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label(String(localized: "profile.notifications"), systemImage: "bell")
                    }

                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        Label(String(localized: "profile.language"), systemImage: "globe")
                    }

                    NavigationLink {
                        Text("Appearance")
                    } label: {
                        Label(String(localized: "profile.appearance"), systemImage: "paintbrush")
                    }
                }

                // Support
                Section(String(localized: "profile.support")) {
                    NavigationLink {
                        Text("Help")
                    } label: {
                        Label(String(localized: "profile.help"), systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        Text("About")
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
                }
            }
            .navigationTitle(String(localized: "profile.title"))
            .alert(
                String(localized: "profile.logout.title"),
                isPresented: $showLogoutAlert
            ) {
                Button(String(localized: "common.cancel"), role: .cancel) {}
                Button(String(localized: "profile.logout"), role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text(String(localized: "profile.logout.message"))
            }
        }
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
                            .foregroundStyle(.accentColor)
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
                            .foregroundStyle(.accentColor)
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
}
