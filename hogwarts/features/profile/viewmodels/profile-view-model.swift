import SwiftUI

/// ViewModel for Profile feature
/// Mirrors: Logic from profile content.tsx
@Observable
@MainActor
final class ProfileViewModel {
    // Dependencies
    private let actions = ProfileActions()
    private var authManager: AuthManager?
    private var tenantContext: TenantContext?

    // State
    var isLoading = false
    var isSaving = false

    // Edit form state
    var editName = ""
    var editNameAr = ""
    var editPhone = ""
    var editImageUrl = ""

    // Error handling
    var error: Error?
    var showError = false

    // Success
    var successMessage: String?
    var showSuccess = false

    // MARK: - Computed

    var currentUser: User? {
        authManager?.currentUser
    }

    var role: UserRole {
        authManager?.role ?? .user
    }

    var schoolId: String? {
        tenantContext?.schoolId
    }

    // MARK: - Setup

    func setup(authManager: AuthManager, tenantContext: TenantContext) {
        self.authManager = authManager
        self.tenantContext = tenantContext
    }

    // MARK: - Load

    /// Load profile and populate edit fields
    func loadProfile() async {
        guard let schoolId = schoolId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await actions.getProfile(schoolId: schoolId)
            editName = user.name ?? ""
            editNameAr = user.nameAr ?? ""
            editPhone = user.phone ?? ""
            editImageUrl = user.imageUrl ?? ""
        } catch {
            // Use cached data from authManager if API fails
            if let user = currentUser {
                editName = user.name ?? ""
                editNameAr = user.nameAr ?? ""
                editPhone = user.phone ?? ""
                editImageUrl = user.imageUrl ?? ""
            }
        }
    }

    // MARK: - Update

    /// Update profile with current edit fields
    func updateProfile() async -> Bool {
        guard let schoolId = schoolId else { return false }

        let validation = ProfileValidation.validateUpdateProfile(
            name: editName,
            nameAr: editNameAr.isEmpty ? nil : editNameAr,
            phone: editPhone.isEmpty ? nil : editPhone
        )

        guard validation.isValid else {
            let message = validation.errors.values.joined(separator: "\n")
            error = ProfileError.validationFailed(message)
            showError = true
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let request = UpdateProfileRequest(
                name: editName.trimmingCharacters(in: .whitespaces),
                nameAr: editNameAr.isEmpty ? nil : editNameAr.trimmingCharacters(in: .whitespaces),
                phone: editPhone.isEmpty ? nil : editPhone.trimmingCharacters(in: .whitespaces),
                imageUrl: editImageUrl.isEmpty ? nil : editImageUrl
            )

            _ = try await actions.updateProfile(request, schoolId: schoolId)

            successMessage = String(localized: "profile.success.updated")
            showSuccess = true
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    // MARK: - Auth Actions

    /// Sign out
    func signOut() {
        authManager?.signOut()
    }
}

// MARK: - Errors

enum ProfileError: LocalizedError {
    case validationFailed(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .serverError(let message):
            return message
        }
    }
}
