import Foundation

/// Server actions for Grades feature
/// Mirrors: src/components/platform/grades/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class GradesActions: Sendable {

    private let api = APIClient.shared
    private let syncEngine = SyncEngine.shared

    // MARK: - Read Actions

    /// Get exams with filters and pagination
    func getExams(
        schoolId: String,
        filters: GradeFilters = GradeFilters()
    ) async throws -> ExamsResponse {
        var params = filters.queryParams
        params["schoolId"] = schoolId

        return try await api.get("/grades/exams", query: params, as: ExamsResponse.self)
    }

    /// Get exam results for a specific exam
    func getExamResults(
        examId: String,
        schoolId: String
    ) async throws -> [ExamResult] {
        return try await api.get(
            "/grades/exams/\(examId)/results",
            query: ["schoolId": schoolId],
            as: [ExamResult].self
        )
    }

    /// Get exam results for a student
    func getStudentResults(
        studentId: String,
        schoolId: String,
        filters: GradeFilters = GradeFilters()
    ) async throws -> ExamResultsResponse {
        var params = filters.queryParams
        params["schoolId"] = schoolId
        params["studentId"] = studentId

        return try await api.get("/grades/results", query: params, as: ExamResultsResponse.self)
    }

    /// Get report card for a student
    func getReportCard(
        studentId: String,
        schoolId: String,
        semester: String? = nil
    ) async throws -> ReportCard {
        var params: [String: String] = ["schoolId": schoolId]
        if let semester = semester { params["semester"] = semester }

        return try await api.get(
            "/grades/report-card/\(studentId)",
            query: params,
            as: ReportCard.self
        )
    }

    /// Get subjects for a class
    func getSubjects(
        classId: String,
        schoolId: String
    ) async throws -> [SubjectInfo] {
        return try await api.get(
            "/subjects",
            query: ["classId": classId, "schoolId": schoolId],
            as: [SubjectInfo].self
        )
    }

    // MARK: - Write Actions

    /// Create a new exam
    func createExam(
        _ request: CreateExamRequest,
        schoolId: String
    ) async throws -> Exam {
        let validation = GradesValidation.validateCreateExamForm(
            title: request.title,
            classId: request.classId,
            subjectId: request.subjectId,
            examDate: request.examDate,
            totalMarks: request.totalMarks,
            passingMarks: request.passingMarks
        )

        guard validation.isValid else {
            throw GradesError.validationFailed(validation.errors)
        }

        struct CreateRequest: Encodable {
            let exam: CreateExamRequest
            let schoolId: String
        }

        let body = CreateRequest(exam: request, schoolId: schoolId)
        return try await api.post("/grades/exams", body: body, as: Exam.self)
    }

    /// Submit marks for an exam
    func submitMarks(
        _ request: SubmitMarksRequest,
        schoolId: String
    ) async throws -> [ExamResult] {
        struct MarksRequest: Encodable {
            let marks: SubmitMarksRequest
            let schoolId: String
        }

        let body = MarksRequest(marks: request, schoolId: schoolId)
        return try await api.post("/grades/results/bulk", body: body, as: [ExamResult].self)
    }

    /// Publish exam results
    func publishResults(
        examId: String,
        schoolId: String
    ) async throws -> Exam {
        struct PublishRequest: Encodable {
            let schoolId: String
        }

        let body = PublishRequest(schoolId: schoolId)
        return try await api.put("/grades/exams/\(examId)/publish", body: body, as: Exam.self)
    }

    // MARK: - Offline Actions

    @MainActor
    func submitMarksOffline(
        _ request: SubmitMarksRequest,
        schoolId: String
    ) async throws -> [ExamResult]? {
        if NetworkMonitor.shared.isConnected {
            return try await submitMarks(request, schoolId: schoolId)
        }

        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/grades/results/bulk",
            method: .post,
            payload: payload
        )

        return nil
    }
}

// MARK: - Errors

enum GradesError: LocalizedError {
    case validationFailed([String: String])
    case notFound
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return errors.values.joined(separator: ", ")
        case .notFound:
            return String(localized: "grade.error.notFound")
        case .unauthorized:
            return String(localized: "error.unauthorized")
        case .serverError(let message):
            return message
        }
    }
}
