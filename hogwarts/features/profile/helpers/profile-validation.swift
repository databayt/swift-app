import Foundation

/// Validation for Profile feature
/// Mirrors: src/components/platform/profile/validation.ts
struct ProfileValidation {

    struct ValidationResult {
        let isValid: Bool
        let errors: [String: String]
    }

    /// Validate profile update fields
    static func validateUpdateProfile(
        name: String?,
        nameAr: String?,
        phone: String?
    ) -> ValidationResult {
        var errors: [String: String] = [:]

        if let name = name, name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["name"] = String(localized: "profile.validation.nameRequired")
        }

        if let name = name, name.count > 100 {
            errors["name"] = String(localized: "profile.validation.nameTooLong")
        }

        if let nameAr = nameAr, nameAr.count > 100 {
            errors["nameAr"] = String(localized: "profile.validation.nameTooLong")
        }

        if let phone = phone, !phone.isEmpty {
            let phoneRegex = #"^\+?[\d\s-]{7,15}$"#
            if phone.range(of: phoneRegex, options: .regularExpression) == nil {
                errors["phone"] = String(localized: "profile.validation.phoneInvalid")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}
