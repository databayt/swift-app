import Foundation

/// Server actions for Attendance feature
/// Mirrors: src/components/platform/attendance/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class AttendanceActions: Sendable {

    private let api = APIClient.shared
    private let syncEngine = SyncEngine.shared

    // MARK: - Read Actions

    /// Get attendance records with filters and pagination
    /// Mirrors: getAttendance() server action
    func getAttendance(
        schoolId: String,
        filters: AttendanceFilters = AttendanceFilters()
    ) async throws -> AttendanceResponse {
        var params = filters.queryParams
        params["schoolId"] = schoolId

        return try await api.get("/attendance", query: params, as: AttendanceResponse.self)
    }

    /// Get single attendance record by ID
    func getAttendanceRecord(id: String, schoolId: String) async throws -> Attendance {
        return try await api.get(
            "/attendance/\(id)",
            query: ["schoolId": schoolId],
            as: Attendance.self
        )
    }

    /// Get attendance for a specific student
    func getStudentAttendance(
        studentId: String,
        schoolId: String,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) async throws -> [Attendance] {
        var params: [String: String] = [
            "studentId": studentId,
            "schoolId": schoolId
        ]

        let formatter = ISO8601DateFormatter()
        if let dateFrom = dateFrom {
            params["dateFrom"] = formatter.string(from: dateFrom)
        }
        if let dateTo = dateTo {
            params["dateTo"] = formatter.string(from: dateTo)
        }

        let response = try await api.get("/attendance", query: params, as: AttendanceResponse.self)
        return response.data
    }

    /// Get attendance for a specific class on a date
    func getClassAttendance(
        classId: String,
        date: Date,
        schoolId: String
    ) async throws -> [Attendance] {
        let formatter = ISO8601DateFormatter()
        let params: [String: String] = [
            "classId": classId,
            "date": formatter.string(from: date),
            "schoolId": schoolId
        ]

        let response = try await api.get("/attendance", query: params, as: AttendanceResponse.self)
        return response.data
    }

    /// Get attendance statistics for a student
    /// Mirrors: getAttendanceStats() server action
    func getStats(
        studentId: String,
        schoolId: String,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) async throws -> AttendanceStats {
        var params: [String: String] = [
            "studentId": studentId,
            "schoolId": schoolId
        ]

        let formatter = ISO8601DateFormatter()
        if let dateFrom = dateFrom {
            params["dateFrom"] = formatter.string(from: dateFrom)
        }
        if let dateTo = dateTo {
            params["dateTo"] = formatter.string(from: dateTo)
        }

        return try await api.get("/attendance/stats", query: params, as: AttendanceStats.self)
    }

    // MARK: - Write Actions

    /// Mark attendance for a single student
    /// Mirrors: markAttendance() server action
    func markAttendance(
        _ request: AttendanceMarkRequest,
        schoolId: String
    ) async throws -> Attendance {
        // Validate input
        let validation = AttendanceValidation.validateMarkForm(
            studentId: request.studentId,
            date: request.date,
            status: AttendanceStatus(rawValue: request.status),
            notes: request.notes
        )

        guard validation.isValid else {
            throw AttendanceError.validationFailed(validation.errors)
        }

        struct MarkRequest: Encodable {
            let attendance: AttendanceMarkRequest
            let schoolId: String
        }

        let body = MarkRequest(attendance: request, schoolId: schoolId)
        return try await api.post("/attendance", body: body, as: Attendance.self)
    }

    /// Bulk mark attendance for a class
    /// Mirrors: bulkMarkAttendance() server action
    func bulkMarkAttendance(
        _ request: AttendanceBulkMarkRequest,
        schoolId: String
    ) async throws -> [Attendance] {
        struct BulkMarkRequest: Encodable {
            let attendance: AttendanceBulkMarkRequest
            let schoolId: String
        }

        let body = BulkMarkRequest(attendance: request, schoolId: schoolId)
        return try await api.post("/attendance/bulk", body: body, as: [Attendance].self)
    }

    /// Update existing attendance record
    func updateAttendance(
        id: String,
        status: AttendanceStatus,
        notes: String?,
        schoolId: String
    ) async throws -> Attendance {
        struct UpdateRequest: Encodable {
            let status: String
            let notes: String?
            let schoolId: String
        }

        let body = UpdateRequest(status: status.rawValue, notes: notes, schoolId: schoolId)
        return try await api.put("/attendance/\(id)", body: body, as: Attendance.self)
    }

    /// Delete attendance record (Admin only)
    func deleteAttendance(id: String, schoolId: String) async throws {
        try await api.delete("/attendance/\(id)?schoolId=\(schoolId)")
    }

    // MARK: - QR Check-in

    /// QR code check-in for students
    /// Mirrors: qrCheckIn() server action
    func qrCheckIn(
        _ request: QRCheckInRequest,
        schoolId: String
    ) async throws -> QRCheckInResponse {
        // Validate QR code format
        let validation = AttendanceValidation.validateQRCheckIn(
            qrCode: request.qrCode,
            studentId: request.studentId
        )

        guard validation.isValid else {
            throw AttendanceError.validationFailed(validation.errors)
        }

        struct CheckInRequest: Encodable {
            let qrCode: String
            let studentId: String
            let schoolId: String
        }

        let body = CheckInRequest(
            qrCode: request.qrCode,
            studentId: request.studentId,
            schoolId: schoolId
        )

        return try await api.post("/attendance/qr", body: body, as: QRCheckInResponse.self)
    }

    /// Create QR session for a class (Teacher)
    func createQRSession(
        classId: String,
        periodId: String?,
        expiresInMinutes: Int = 15,
        schoolId: String
    ) async throws -> QRSession {
        struct CreateSessionRequest: Encodable {
            let classId: String
            let periodId: String?
            let expiresInMinutes: Int
            let schoolId: String
        }

        let body = CreateSessionRequest(
            classId: classId,
            periodId: periodId,
            expiresInMinutes: expiresInMinutes,
            schoolId: schoolId
        )

        return try await api.post("/attendance/qr/session", body: body, as: QRSession.self)
    }

    // MARK: - Excuses

    /// Submit excuse for absence
    /// Mirrors: submitExcuse() server action
    func submitExcuse(
        _ request: ExcuseSubmitRequest,
        schoolId: String
    ) async throws -> AttendanceExcuse {
        // Validate input
        let validation = AttendanceValidation.validateExcuseForm(
            studentId: request.studentId,
            date: request.date,
            reason: request.reason,
            documentUrl: request.documentUrl
        )

        guard validation.isValid else {
            throw AttendanceError.validationFailed(validation.errors)
        }

        struct ExcuseRequest: Encodable {
            let excuse: ExcuseSubmitRequest
            let schoolId: String
        }

        let body = ExcuseRequest(excuse: request, schoolId: schoolId)
        return try await api.post("/attendance/excuse", body: body, as: AttendanceExcuse.self)
    }

    /// Review excuse (Approve/Reject)
    /// Mirrors: reviewExcuse() server action
    func reviewExcuse(
        _ request: ExcuseReviewRequest,
        schoolId: String
    ) async throws -> AttendanceExcuse {
        struct ReviewRequest: Encodable {
            let status: String
            let reviewNotes: String?
            let schoolId: String
        }

        let body = ReviewRequest(
            status: request.status,
            reviewNotes: request.reviewNotes,
            schoolId: schoolId
        )

        return try await api.put(
            "/attendance/excuse/\(request.excuseId)",
            body: body,
            as: AttendanceExcuse.self
        )
    }

    /// Get pending excuses for review (Teacher/Admin)
    func getPendingExcuses(
        schoolId: String,
        filters: ExcuseFilters = ExcuseFilters()
    ) async throws -> [AttendanceExcuse] {
        var params: [String: String] = [
            "schoolId": schoolId,
            "status": AttendanceExcuse.ExcuseStatus.pending.rawValue
        ]

        if let studentId = filters.studentId {
            params["studentId"] = studentId
        }

        let formatter = ISO8601DateFormatter()
        if let dateFrom = filters.dateFrom {
            params["dateFrom"] = formatter.string(from: dateFrom)
        }
        if let dateTo = filters.dateTo {
            params["dateTo"] = formatter.string(from: dateTo)
        }

        params["page"] = String(filters.page)
        params["pageSize"] = String(filters.pageSize)

        return try await api.get("/attendance/excuse", query: params, as: [AttendanceExcuse].self)
    }

    // MARK: - Offline Actions

    /// Mark attendance (offline-capable)
    /// Queues action if offline
    @MainActor
    func markAttendanceOffline(
        _ request: AttendanceMarkRequest,
        schoolId: String
    ) async throws -> Attendance? {
        if NetworkMonitor.shared.isConnected {
            return try await markAttendance(request, schoolId: schoolId)
        }

        // Queue for later
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/attendance",
            method: .post,
            payload: payload
        )

        return nil
    }

    /// Bulk mark attendance (offline-capable)
    @MainActor
    func bulkMarkAttendanceOffline(
        _ request: AttendanceBulkMarkRequest,
        schoolId: String
    ) async throws -> [Attendance]? {
        if NetworkMonitor.shared.isConnected {
            return try await bulkMarkAttendance(request, schoolId: schoolId)
        }

        // Queue for later
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/attendance/bulk",
            method: .post,
            payload: payload
        )

        return nil
    }

    /// Submit excuse (offline-capable)
    @MainActor
    func submitExcuseOffline(
        _ request: ExcuseSubmitRequest,
        schoolId: String
    ) async throws -> AttendanceExcuse? {
        if NetworkMonitor.shared.isConnected {
            return try await submitExcuse(request, schoolId: schoolId)
        }

        // Queue for later
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/attendance/excuse",
            method: .post,
            payload: payload
        )

        return nil
    }
}

// MARK: - Errors

enum AttendanceError: LocalizedError {
    case validationFailed([String: String])
    case notFound
    case unauthorized
    case qrExpired
    case qrInvalid
    case alreadyMarked
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return errors.values.joined(separator: ", ")
        case .notFound:
            return String(localized: "attendance.error.notFound")
        case .unauthorized:
            return String(localized: "error.unauthorized")
        case .qrExpired:
            return String(localized: "attendance.error.qrExpired")
        case .qrInvalid:
            return String(localized: "attendance.error.qrInvalid")
        case .alreadyMarked:
            return String(localized: "attendance.error.alreadyMarked")
        case .serverError(let message):
            return message
        }
    }
}
