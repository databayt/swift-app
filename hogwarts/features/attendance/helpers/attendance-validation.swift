import Foundation

/// Validation for Attendance feature
/// Mirrors: src/components/platform/attendance/validation.ts

struct AttendanceValidation {

    // MARK: - Field Validation

    /// Validate attendance date
    static func validateDate(_ value: Date) -> ValidationResult {
        let now = Date()
        let calendar = Calendar.current

        // Cannot mark attendance for future dates
        if calendar.startOfDay(for: value) > calendar.startOfDay(for: now) {
            return .invalid(String(localized: "attendance.validation.dateInFuture"))
        }

        // Cannot mark attendance for dates more than 30 days in the past
        if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now),
           value < thirtyDaysAgo {
            return .invalid(String(localized: "attendance.validation.dateTooOld"))
        }

        return .valid
    }

    /// Validate attendance status
    static func validateStatus(_ value: AttendanceStatus?) -> ValidationResult {
        guard value != nil else {
            return .invalid(String(localized: "validation.required"))
        }
        return .valid
    }

    /// Validate notes (optional)
    static func validateNotes(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .valid // Notes are optional
        }

        if value.count > 500 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 500 characters"))
        }
        return .valid
    }

    /// Validate excuse reason
    static func validateExcuseReason(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "validation.required"))
        }
        if value.count < 10 {
            return .invalid(String(localized: "attendance.validation.reasonTooShort"))
        }
        if value.count > 1000 {
            return .invalid(String(localized: "validation.maxLength", defaultValue: "Maximum 1000 characters"))
        }
        return .valid
    }

    /// Validate excuse date
    static func validateExcuseDate(_ value: Date) -> ValidationResult {
        let now = Date()
        let calendar = Calendar.current

        // Excuse date should be in the past or today
        if calendar.startOfDay(for: value) > calendar.startOfDay(for: now) {
            return .invalid(String(localized: "attendance.validation.excuseDateInFuture"))
        }

        // Cannot submit excuse for dates more than 7 days in the past
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
           value < sevenDaysAgo {
            return .invalid(String(localized: "attendance.validation.excuseDateTooOld"))
        }

        return .valid
    }

    /// Validate QR code format
    static func validateQRCode(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(String(localized: "attendance.validation.qrCodeEmpty"))
        }

        // QR code should be a valid UUID or session token format
        // Allow UUIDs and alphanumeric tokens
        let validPattern = #"^[A-Za-z0-9\-]{8,64}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", validPattern)

        if !predicate.evaluate(with: value) {
            return .invalid(String(localized: "attendance.validation.qrCodeInvalid"))
        }

        return .valid
    }

    /// Validate document URL (optional)
    static func validateDocumentUrl(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .valid // Document is optional
        }

        guard URL(string: value) != nil else {
            return .invalid(String(localized: "validation.invalidUrl"))
        }

        return .valid
    }

    /// Validate class selection
    static func validateClassId(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .invalid(String(localized: "attendance.validation.classRequired"))
        }
        return .valid
    }

    /// Validate student selection
    static func validateStudentId(_ value: String?) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .invalid(String(localized: "attendance.validation.studentRequired"))
        }
        return .valid
    }

    // MARK: - Form Validation

    /// Validate mark attendance form (single student)
    static func validateMarkForm(
        studentId: String?,
        date: Date,
        status: AttendanceStatus?,
        notes: String?
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let message) = validateStudentId(studentId) {
            errors["studentId"] = message
        }
        if case .invalid(let message) = validateDate(date) {
            errors["date"] = message
        }
        if case .invalid(let message) = validateStatus(status) {
            errors["status"] = message
        }
        if case .invalid(let message) = validateNotes(notes) {
            errors["notes"] = message
        }

        return FormValidationResult(errors: errors)
    }

    /// Validate bulk mark attendance form (class)
    static func validateBulkMarkForm(
        classId: String?,
        date: Date,
        records: [AttendanceMarkRow]
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let message) = validateClassId(classId) {
            errors["classId"] = message
        }
        if case .invalid(let message) = validateDate(date) {
            errors["date"] = message
        }

        // Validate that at least one student has a status
        let hasRecords = !records.isEmpty
        if !hasRecords {
            errors["records"] = String(localized: "attendance.validation.noStudents")
        }

        return FormValidationResult(errors: errors)
    }

    /// Validate excuse submission form
    static func validateExcuseForm(
        studentId: String?,
        date: Date,
        reason: String,
        documentUrl: String?
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let message) = validateStudentId(studentId) {
            errors["studentId"] = message
        }
        if case .invalid(let message) = validateExcuseDate(date) {
            errors["date"] = message
        }
        if case .invalid(let message) = validateExcuseReason(reason) {
            errors["reason"] = message
        }
        if case .invalid(let message) = validateDocumentUrl(documentUrl) {
            errors["documentUrl"] = message
        }

        return FormValidationResult(errors: errors)
    }

    /// Validate QR check-in
    static func validateQRCheckIn(
        qrCode: String,
        studentId: String?
    ) -> FormValidationResult {
        var errors: [String: String] = [:]

        if case .invalid(let message) = validateQRCode(qrCode) {
            errors["qrCode"] = message
        }
        if case .invalid(let message) = validateStudentId(studentId) {
            errors["studentId"] = message
        }

        return FormValidationResult(errors: errors)
    }
}

// MARK: - Attendance-Specific Validation Helpers

extension AttendanceValidation {

    /// Check if attendance can be modified for a given date
    static func canModifyAttendance(for date: Date, role: UserRole) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Admins and developers can modify any attendance
        if role == .admin || role == .developer {
            return true
        }

        // Teachers can only modify attendance from the past 7 days
        if role == .teacher {
            if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                return date >= sevenDaysAgo
            }
        }

        return false
    }

    /// Check if excuse can be submitted for a given date
    static func canSubmitExcuse(for date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Can only submit excuse for past 7 days
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
            let startOfExcuseDate = calendar.startOfDay(for: date)
            let startOfNow = calendar.startOfDay(for: now)
            return startOfExcuseDate >= sevenDaysAgo && startOfExcuseDate <= startOfNow
        }

        return false
    }

    /// Check if QR check-in is available (within time window)
    static func canQRCheckIn(session: QRSession) -> Bool {
        !session.isExpired
    }
}
