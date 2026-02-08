import SwiftUI
import PhotosUI

/// Edit Profile form
/// Mirrors: src/components/platform/profile/edit-profile.tsx
struct EditProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Form {
            // Avatar
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: viewModel.editImageUrl)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Text(String(localized: "profile.edit.changePhoto"))
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
            }

            // Name fields
            Section(String(localized: "profile.edit.nameSection")) {
                TextField(
                    String(localized: "profile.edit.name"),
                    text: $viewModel.editName
                )
                .textContentType(.name)

                TextField(
                    String(localized: "profile.edit.nameAr"),
                    text: $viewModel.editNameAr
                )
                .environment(\.layoutDirection, .rightToLeft)
            }

            // Contact
            Section(String(localized: "profile.edit.contactSection")) {
                TextField(
                    String(localized: "profile.edit.phone"),
                    text: $viewModel.editPhone
                )
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

                // Email (read-only)
                if let email = viewModel.currentUser?.email {
                    HStack {
                        Text(String(localized: "profile.edit.email"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "profile.editProfile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        if await viewModel.updateProfile() {
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text(String(localized: "common.save"))
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .alert(
            String(localized: "error.title"),
            isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button(String(localized: "common.ok")) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}
