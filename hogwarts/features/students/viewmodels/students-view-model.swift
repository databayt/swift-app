import SwiftUI

/// ViewModel for Students list
/// Mirrors: Logic from content.tsx + table.tsx
@Observable
@MainActor
final class StudentsViewModel {
    // Dependencies
    private let actions = StudentsActions()
    private var tenantContext: TenantContext?

    // State
    var viewState: StudentsViewState = .idle
    var filters = StudentFilters()
    var selectedStudent: Student?
    var isShowingForm = false
    var formMode: StudentFormMode = .create
    var yearLevels: [YearLevel] = []
    var selectedYearLevelId: String?
    var isNavigatingToDetail = false
    var detailStudent: Student?

    // Pagination
    var currentPage = 1
    var totalPages = 1
    var totalCount = 0

    // Error handling
    var error: Error?
    var showError = false

    // Computed
    var students: [Student] {
        viewState.students
    }

    var rows: [StudentRow] {
        students.map { StudentRow(from: $0) }
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var isEmpty: Bool {
        if case .empty = viewState { return true }
        return false
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext) {
        self.tenantContext = tenantContext
        Task { await loadYearLevels() }
    }

    // MARK: - Actions

    /// Load students with current filters
    func loadStudents() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(StudentsError.unauthorized)
            return
        }

        viewState = .loading

        do {
            filters.page = currentPage
            let response = try await actions.getStudents(schoolId: schoolId, filters: filters)

            if response.data.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(response.data)
            }

            totalPages = response.totalPages
            totalCount = response.total
        } catch {
            viewState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Refresh students (pull-to-refresh)
    func refresh() async {
        currentPage = 1
        await loadStudents()
    }

    /// Load next page
    func loadNextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        await loadStudents()
    }

    /// Search students
    func search(_ query: String) async {
        filters.search = query.isEmpty ? nil : query
        currentPage = 1
        await loadStudents()
    }

    /// Filter by status
    func filterByStatus(_ status: StudentStatus?) {
        filters.status = status
        currentPage = 1
        Task { await loadStudents() }
    }

    /// Filter by year level
    func filterByYearLevel(_ yearLevelId: String?) {
        filters.yearLevelId = yearLevelId
        currentPage = 1
        Task { await loadStudents() }
    }

    /// Sort students
    func sort(by field: StudentFilters.SortField, order: StudentFilters.SortOrder) {
        filters.sortBy = field
        filters.sortOrder = order
        Task { await loadStudents() }
    }

    /// Clear all filters
    func clearFilters() {
        filters = StudentFilters()
        currentPage = 1
        Task { await loadStudents() }
    }

    /// Load year levels for filter
    func loadYearLevels() async {
        guard let schoolId = tenantContext?.schoolId else { return }
        do {
            yearLevels = try await actions.getYearLevels(schoolId: schoolId)
        } catch {
            // Year levels are non-critical, don't show error
            print("Failed to load year levels: \(error)")
        }
    }

    // MARK: - CRUD Actions

    /// Show create form
    func showCreateForm() {
        formMode = .create
        isShowingForm = true
    }

    /// Show edit form
    func showEditForm(for student: Student) {
        formMode = .edit(student)
        selectedStudent = student
        isShowingForm = true
    }

    /// Delete student
    func deleteStudent(_ student: Student) async {
        guard let schoolId = tenantContext?.schoolId else { return }

        do {
            try await actions.deleteStudent(id: student.id, schoolId: schoolId)
            await loadStudents()
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Delete students (batch)
    func deleteStudents(_ students: [Student]) async {
        for student in students {
            await deleteStudent(student)
        }
    }

    // MARK: - Form Submission

    /// Handle form submission
    func submitForm(_ request: StudentCreateRequest) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            switch formMode {
            case .create:
                _ = try await actions.createStudent(request, schoolId: schoolId)
            case .edit(let student):
                let updateRequest = StudentUpdateRequest(
                    givenName: request.givenName,
                    surname: request.surname,
                    givenNameAr: request.givenNameAr,
                    surnameAr: request.surnameAr,
                    dateOfBirth: request.dateOfBirth,
                    gender: request.gender,
                    nationality: request.nationality,
                    email: request.email,
                    phone: request.phone,
                    address: request.address,
                    yearLevelId: request.yearLevelId,
                    batchId: request.batchId,
                    status: nil,
                    photoUrl: nil,
                    bloodType: nil,
                    allergies: nil,
                    medicalConditions: nil
                )
                _ = try await actions.updateStudent(id: student.id, updateRequest, schoolId: schoolId)
            }

            isShowingForm = false
            await loadStudents()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }
}
