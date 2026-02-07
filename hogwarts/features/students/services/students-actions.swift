import Foundation

/// Server actions for Students feature
/// Mirrors: src/components/platform/students/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class StudentsActions: Sendable {

    private let api = APIClient.shared
    private let syncEngine = SyncEngine.shared

    // MARK: - Read Actions

    /// Get students with filters and pagination
    /// Mirrors: getStudents() server action
    func getStudents(
        schoolId: String,
        filters: StudentFilters = StudentFilters()
    ) async throws -> StudentsResponse {
        var params = filters.queryParams
        params["schoolId"] = schoolId

        return try await api.get("/students", query: params, as: StudentsResponse.self)
    }

    /// Get single student by ID
    /// Mirrors: getStudent(id) server action
    func getStudent(id: String, schoolId: String) async throws -> Student {
        return try await api.get("/students/\(id)", query: ["schoolId": schoolId], as: Student.self)
    }

    /// Search students
    func searchStudents(
        query: String,
        schoolId: String,
        limit: Int = 10
    ) async throws -> [Student] {
        let params = [
            "search": query,
            "schoolId": schoolId,
            "pageSize": String(limit)
        ]

        let response = try await api.get("/students", query: params, as: StudentsResponse.self)
        return response.data
    }

    // MARK: - Write Actions

    /// Create new student
    /// Mirrors: createStudent() server action
    func createStudent(
        _ request: StudentCreateRequest,
        schoolId: String
    ) async throws -> Student {
        // Validate input
        let validation = StudentsValidation.validateCreateForm(
            grNumber: request.grNumber,
            givenName: request.givenName,
            surname: request.surname,
            email: request.email,
            phone: request.phone,
            dateOfBirth: request.dateOfBirth
        )

        guard validation.isValid else {
            throw StudentsError.validationFailed(validation.errors)
        }

        // Create request with schoolId
        struct CreateRequest: Encodable {
            let student: StudentCreateRequest
            let schoolId: String
        }

        let body = CreateRequest(student: request, schoolId: schoolId)
        return try await api.post("/students", body: body, as: Student.self)
    }

    /// Update student
    /// Mirrors: updateStudent() server action
    func updateStudent(
        id: String,
        _ request: StudentUpdateRequest,
        schoolId: String
    ) async throws -> Student {
        // Validate input
        let validation = StudentsValidation.validateUpdateForm(
            givenName: request.givenName,
            surname: request.surname,
            email: request.email,
            phone: request.phone,
            dateOfBirth: request.dateOfBirth
        )

        guard validation.isValid else {
            throw StudentsError.validationFailed(validation.errors)
        }

        struct UpdateRequest: Encodable {
            let student: StudentUpdateRequest
            let schoolId: String
        }

        let body = UpdateRequest(student: request, schoolId: schoolId)
        return try await api.put("/students/\(id)", body: body, as: Student.self)
    }

    /// Delete student
    /// Mirrors: deleteStudent() server action
    func deleteStudent(id: String, schoolId: String) async throws {
        try await api.delete("/students/\(id)?schoolId=\(schoolId)")
    }

    // MARK: - Offline Actions

    /// Create student (offline-capable)
    /// Queues action if offline
    @MainActor
    func createStudentOffline(
        _ request: StudentCreateRequest,
        schoolId: String
    ) async throws -> Student? {
        if NetworkMonitor.shared.isConnected {
            return try await createStudent(request, schoolId: schoolId)
        }

        // Queue for later
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/students",
            method: .post,
            payload: payload
        )

        return nil
    }

    /// Update student (offline-capable)
    @MainActor
    func updateStudentOffline(
        id: String,
        _ request: StudentUpdateRequest,
        schoolId: String
    ) async throws -> Student? {
        if NetworkMonitor.shared.isConnected {
            return try await updateStudent(id: id, request, schoolId: schoolId)
        }

        // Queue for later
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/students/\(id)",
            method: .put,
            payload: payload
        )

        return nil
    }
}

// MARK: - Errors

enum StudentsError: LocalizedError {
    case validationFailed([String: String])
    case notFound
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return errors.values.joined(separator: ", ")
        case .notFound:
            return String(localized: "student.error.notFound")
        case .unauthorized:
            return String(localized: "error.unauthorized")
        case .serverError(let message):
            return message
        }
    }
}
