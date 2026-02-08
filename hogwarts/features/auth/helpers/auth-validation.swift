import Foundation

/// Client-side validation for auth forms
/// Mirrors: src/components/auth/validation.ts
struct AuthValidation {

    /// Validate email format
    static func validateEmail(_ email: String) -> ValidationResult {
        if email.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }

        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(email.startIndex..., in: email)
        let match = regex?.firstMatch(in: email, range: range)

        if match == nil {
            return .invalid(String(localized: "auth.error.invalidEmail"))
        }

        return .valid
    }

    /// Validate password is not empty
    static func validatePassword(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .invalid(String(localized: "auth.error.emptyPassword"))
        }
        return .valid
    }

    /// Validate login form fields
    static func validateLoginForm(email: String, password: String) -> LoginFormValidation {
        let emailResult = validateEmail(email)
        let passwordResult = validatePassword(password)
        return LoginFormValidation(
            email: emailResult,
            password: passwordResult
        )
    }
}

// MARK: - Types

/// Reuses ValidationResult from students-validation.swift (shared type)

struct LoginFormValidation {
    let email: ValidationResult
    let password: ValidationResult

    var isValid: Bool {
        email.isValid && password.isValid
    }
}
