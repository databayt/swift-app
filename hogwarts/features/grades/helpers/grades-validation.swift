import Foundation

/// Validation for Grades feature
/// Mirrors: src/components/platform/grades/validation.ts

struct GradesValidation {

    // MARK: - Exam Validation

    static func validateExamTitle(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }
        if value.count < 3 {
            return .invalid(String(localized: "validation.minLength", defaultValue: "Minimum 3 characters"))
        }
        if value.count > 100 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 100 characters"))
        }
        return .valid
    }

    static func validateTotalMarks(_ value: Double) -> ValidationResult {
        if value <= 0 {
            return .invalid(String(localized: "grade.validation.marksPositive"))
        }
        if value > 1000 {
            return .invalid(String(localized: "grade.validation.marksTooHigh"))
        }
        return .valid
    }

    static func validatePassingMarks(_ value: Double, totalMarks: Double) -> ValidationResult {
        if value < 0 {
            return .invalid(String(localized: "grade.validation.marksPositive"))
        }
        if value > totalMarks {
            return .invalid(String(localized: "grade.validation.passingExceedsTotal"))
        }
        return .valid
    }

    static func validateMarks(_ value: Double, totalMarks: Double) -> ValidationResult {
        if value < 0 {
            return .invalid(String(localized: "grade.validation.marksPositive"))
        }
        if value > totalMarks {
            return .invalid(String(localized: "grade.validation.marksExceedTotal"))
        }
        return .valid
    }

    static func validateRemarks(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .valid
        }
        if value.count > 500 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 500 characters"))
        }
        return .valid
    }

    // MARK: - Form Validation

    static func validateCreateExamForm(
        title: String,
        classId: String?,
        subjectId: String?,
        examDate: String,
        totalMarks: Double,
        passingMarks: Double
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let msg) = validateExamTitle(title) { errors["title"] = msg }
        if classId == nil || classId?.isEmpty == true { errors["classId"] = String(localized: "validation.required") }
        if subjectId == nil || subjectId?.isEmpty == true { errors["subjectId"] = String(localized: "validation.required") }
        if examDate.isEmpty { errors["examDate"] = String(localized: "validation.required") }
        if case .invalid(let msg) = validateTotalMarks(totalMarks) { errors["totalMarks"] = msg }
        if case .invalid(let msg) = validatePassingMarks(passingMarks, totalMarks: totalMarks) { errors["passingMarks"] = msg }

        return FormValidationResult(errors: errors)
    }

    static func validateMarksEntryForm(
        entries: [GradeEntryRow],
        totalMarks: Double
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        for entry in entries {
            if !entry.marks.isEmpty {
                if let marks = Double(entry.marks) {
                    if case .invalid(let msg) = validateMarks(marks, totalMarks: totalMarks) {
                        errors[entry.studentId] = msg
                    }
                } else {
                    errors[entry.studentId] = String(localized: "grade.validation.invalidMarks")
                }
            }
        }

        return FormValidationResult(errors: errors)
    }
}
