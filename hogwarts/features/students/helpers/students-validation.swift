import Foundation

/// Validation for Students feature
/// Mirrors: src/components/platform/students/validation.ts

struct StudentsValidation {

    // MARK: - Field Validation

    /// Validate GR number
    static func validateGrNumber(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }
        if value.count < 3 {
            return .invalid(String(localized: "validation.minLength", defaultValue: "Minimum 3 characters"))
        }
        if value.count > 20 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 20 characters"))
        }
        return .valid
    }

    /// Validate given name
    static func validateGivenName(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }
        if value.count < 2 {
            return .invalid(String(localized: "validation.minLength", defaultValue: "Minimum 2 characters"))
        }
        if value.count > 50 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 50 characters"))
        }
        return .valid
    }

    /// Validate surname
    static func validateSurname(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }
        if value.count < 2 {
            return .invalid(String(localized: "validation.minLength", defaultValue: "Minimum 2 characters"))
        }
        if value.count > 50 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 50 characters"))
        }
        return .valid
    }

    /// Validate email (optional)
    static func validateEmail(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .valid // Email is optional
        }

        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !predicate.evaluate(with: value) {
            return .invalid(String(localized: "validation.invalidEmail"))
        }
        return .valid
    }

    /// Validate phone (optional)
    static func validatePhone(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .valid // Phone is optional
        }

        // Allow various phone formats
        let phoneRegex = #"^[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        if !predicate.evaluate(with: value) {
            return .invalid(String(localized: "validation.invalidPhone"))
        }
        return .valid
    }

    /// Validate date of birth (optional)
    static func validateDateOfBirth(_ value: Date?) -> ValidationResult {
        guard let value = value else {
            return .valid // Date is optional
        }

        let now = Date()
        let calendar = Calendar.current

        // Must be in the past
        if value > now {
            return .invalid(String(localized: "validation.dateInFuture"))
        }

        // Must be reasonable age (3-100 years)
        let ageComponents = calendar.dateComponents([.year], from: value, to: now)
        guard let age = ageComponents.year else {
            return .invalid(String(localized: "validation.invalidDate"))
        }

        if age < 3 {
            return .invalid(String(localized: "validation.ageTooYoung"))
        }
        if age > 100 {
            return .invalid(String(localized: "validation.ageTooOld"))
        }

        return .valid
    }

    // MARK: - Form Validation

    /// Validate entire create form
    static func validateCreateForm(
        grNumber: String,
        givenName: String,
        surname: String,
        email: String?,
        phone: String?,
        dateOfBirth: Date?
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let message) = validateGrNumber(grNumber) {
            errors["grNumber"] = message
        }
        if case .invalid(let message) = validateGivenName(givenName) {
            errors["givenName"] = message
        }
        if case .invalid(let message) = validateSurname(surname) {
            errors["surname"] = message
        }
        if case .invalid(let message) = validateEmail(email) {
            errors["email"] = message
        }
        if case .invalid(let message) = validatePhone(phone) {
            errors["phone"] = message
        }
        if case .invalid(let message) = validateDateOfBirth(dateOfBirth) {
            errors["dateOfBirth"] = message
        }

        return FormValidationResult(errors: errors)
    }

    /// Validate entire update form
    static func validateUpdateForm(
        givenName: String?,
        surname: String?,
        email: String?,
        phone: String?,
        dateOfBirth: Date?
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if let givenName = givenName {
            if case .invalid(let message) = validateGivenName(givenName) {
                errors["givenName"] = message
            }
        }
        if let surname = surname {
            if case .invalid(let message) = validateSurname(surname) {
                errors["surname"] = message
            }
        }
        if case .invalid(let message) = validateEmail(email) {
            errors["email"] = message
        }
        if case .invalid(let message) = validatePhone(phone) {
            errors["phone"] = message
        }
        if case .invalid(let message) = validateDateOfBirth(dateOfBirth) {
            errors["dateOfBirth"] = message
        }

        return FormValidationResult(errors: errors)
    }
}

// MARK: - Validation Types

enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

struct FormValidationResult {
    let errors: [String: String]

    var isValid: Bool {
        errors.isEmpty
    }

    func error(for field: String) -> String? {
        errors[field]
    }
}
