import SwiftUI

/// ViewModel for login form
/// Manages form state, validation, loading, and error handling
@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var error: Error?
    var showError = false

    /// Field-level validation (shown after first submit attempt)
    var emailError: String?
    var passwordError: String?
    var hasAttemptedSubmit = false

    /// Whether the form can be submitted
    var canSubmit: Bool {
        !isLoading && !email.isEmpty && !password.isEmpty
    }

    /// Validate fields and update error messages
    func validate() -> Bool {
        let result = AuthValidation.validateLoginForm(email: email, password: password)
        emailError = result.email.errorMessage
        passwordError = result.password.errorMessage
        hasAttemptedSubmit = true
        return result.isValid
    }

    /// Sign in with email/password
    func login(authManager: AuthManager, tenantContext: TenantContext) async {
        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await authManager.signIn(email: email, password: password)
            if let schoolId = session.schoolId {
                tenantContext.setTenant(schoolId: schoolId)
            }
        } catch {
            self.error = error
            showError = true
            password = ""
        }
    }

    /// Clear validation errors on field edit
    func onEmailChanged() {
        if hasAttemptedSubmit {
            emailError = AuthValidation.validateEmail(email).errorMessage
        }
    }

    func onPasswordChanged() {
        if hasAttemptedSubmit {
            passwordError = AuthValidation.validatePassword(password).errorMessage
        }
    }
}
