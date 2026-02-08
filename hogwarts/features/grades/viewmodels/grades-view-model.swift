import SwiftUI

/// ViewModel for Grades feature
/// Mirrors: Logic from content.tsx + role-based views
@Observable
@MainActor
final class GradesViewModel {
    // Dependencies
    private let actions = GradesActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var viewState: GradesViewState = .idle
    var examsState: ExamsViewState = .idle
    var filters = GradeFilters()
    var selectedExam: Exam?
    var reportCard: ReportCard?

    // Form state
    var isShowingForm = false
    var formMode: GradeFormMode = .createExam
    var gradeEntryRows: [GradeEntryRow] = []

    // Pagination
    var currentPage = 1
    var totalPages = 1
    var totalCount = 0

    // Error handling
    var error: Error?
    var showError = false

    // Success
    var successMessage: String?
    var showSuccess = false

    // Navigation
    var isShowingReportCard = false

    // MARK: - Computed Properties

    var results: [ExamResult] {
        viewState.results
    }

    var rows: [ExamResultRow] {
        results.map { ExamResultRow(from: $0) }
    }

    var exams: [Exam] {
        examsState.exams
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var capabilities: GradeCapabilities {
        guard let role = authManager?.role else {
            return GradeCapabilities.forRole(.user)
        }
        return GradeCapabilities.forRole(role)
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext, authManager: AuthManager) {
        self.tenantContext = tenantContext
        self.authManager = authManager
    }

    // MARK: - Load Actions

    /// Load exam results based on role
    func loadResults() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(GradesError.unauthorized)
            return
        }

        viewState = .loading

        do {
            filters.page = currentPage

            if !capabilities.canViewClassGrades {
                if let studentId = getStudentId() {
                    filters.studentId = studentId
                }
            }

            let response = try await actions.getStudentResults(
                studentId: filters.studentId ?? "",
                schoolId: schoolId,
                filters: filters
            )

            if response.data.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(response.data)
            }

            totalPages = response.totalPages
            totalCount = response.total

            // Auto-load report card for student/guardian roles (for GPA card)
            if !capabilities.canEnterGrades && reportCard == nil {
                await loadReportCard()
            }
        } catch {
            viewState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Load exams (for teachers)
    func loadExams() async {
        guard let schoolId = tenantContext?.schoolId else { return }

        examsState = .loading

        do {
            let response = try await actions.getExams(schoolId: schoolId, filters: filters)
            if response.data.isEmpty {
                examsState = .empty
            } else {
                examsState = .loaded(response.data)
            }
        } catch {
            examsState = .error(error)
        }
    }

    /// Load report card
    func loadReportCard(studentId: String? = nil) async {
        guard let schoolId = tenantContext?.schoolId else { return }
        let sid = studentId ?? getStudentId() ?? ""

        do {
            reportCard = try await actions.getReportCard(studentId: sid, schoolId: schoolId)
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Refresh
    func refresh() async {
        currentPage = 1
        await loadResults()
    }

    /// Load next page
    func loadNextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        await loadResults()
    }

    // MARK: - Filter Actions

    func filterByExamType(_ type: ExamType?) {
        filters.examType = type
        currentPage = 1
        Task { await loadResults() }
    }

    func filterBySubject(_ subjectId: String?) {
        filters.subjectId = subjectId
        currentPage = 1
        Task { await loadResults() }
    }

    func clearFilters() {
        filters = GradeFilters()
        currentPage = 1
        Task { await loadResults() }
    }

    // MARK: - Form Actions

    func showCreateExamForm() {
        formMode = .createExam
        isShowingForm = true
    }

    func showEditExamForm(for exam: Exam) {
        formMode = .editExam(exam)
        isShowingForm = true
    }

    func showEnterMarksForm(for exam: Exam) {
        formMode = .enterMarks(exam)
        selectedExam = exam
        isShowingForm = true
    }

    /// Create exam
    func createExam(_ request: CreateExamRequest) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            _ = try await actions.createExam(request, schoolId: schoolId)
            successMessage = String(localized: "grade.success.examCreated")
            showSuccess = true
            isShowingForm = false
            await loadExams()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    /// Submit marks
    func submitMarks(_ request: SubmitMarksRequest) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            _ = try await actions.submitMarks(request, schoolId: schoolId)
            successMessage = String(localized: "grade.success.marksSubmitted")
            showSuccess = true
            isShowingForm = false
            await loadResults()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    /// Publish results
    func publishResults(examId: String) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            _ = try await actions.publishResults(examId: examId, schoolId: schoolId)
            successMessage = String(localized: "grade.success.published")
            showSuccess = true
            await loadExams()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    // MARK: - Report Card

    func showReportCard(studentId: String? = nil) {
        isShowingReportCard = true
        Task { await loadReportCard(studentId: studentId) }
    }

    // MARK: - Helpers

    private func getStudentId() -> String? {
        return authManager?.currentUser?.id
    }
}
