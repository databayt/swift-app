import SwiftUI
import SwiftData
import os

/// ViewModel for Attendance feature
/// Mirrors: Logic from content.tsx + role-based views
@Observable
@MainActor
final class AttendanceViewModel {
    // Dependencies
    private let actions = AttendanceActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var viewState: AttendanceViewState = .idle
    var classAttendanceState: ClassAttendanceState = .idle
    var qrScannerState: QRScannerState = .idle
    var filters = AttendanceFilters()
    var selectedDate = Date()
    var stats: AttendanceStats?

    // Form state
    var isShowingForm = false
    var formMode: AttendanceFormMode?
    var markRows: [AttendanceMarkRow] = []

    // QR state
    var isShowingQRScanner = false
    var qrSession: QRSession?

    // Excuse state
    var pendingExcuses: [AttendanceExcuse] = []
    var studentExcuses: [AttendanceExcuse] = []
    var isShowingExcuseForm = false
    var selectedExcuse: AttendanceExcuse?

    // Teacher classes
    var teacherClasses: [TeacherClassItem] = []
    var selectedClassId: String?

    // Pagination
    var currentPage = 1
    var totalPages = 1
    var totalCount = 0

    // Error handling
    var error: Error?
    var showError = false

    // Success message
    var successMessage: String?
    var showSuccess = false

    // MARK: - Computed Properties

    var attendance: [Attendance] {
        viewState.attendance
    }

    var rows: [AttendanceRow] {
        attendance.map { AttendanceRow(from: $0) }
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var isEmpty: Bool {
        if case .empty = viewState { return true }
        return false
    }

    var capabilities: AttendanceCapabilities {
        guard let role = authManager?.role else {
            return AttendanceCapabilities.forRole(.user)
        }
        return AttendanceCapabilities.forRole(role)
    }

    var statsDisplay: AttendanceStatsDisplay? {
        guard let stats = stats else { return nil }
        return AttendanceStatsDisplay(from: stats)
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext, authManager: AuthManager) {
        self.tenantContext = tenantContext
        self.authManager = authManager
    }

    // MARK: - Load Actions

    /// Load attendance records with current filters (offline-first)
    func loadAttendance() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(AttendanceError.unauthorized)
            return
        }

        viewState = .loading

        do {
            filters.page = currentPage

            // For students/guardians, filter by their student ID
            if !capabilities.canViewClassAttendance {
                if let studentId = getStudentId() {
                    filters.studentId = studentId
                }
            }

            let response = try await actions.getAttendance(schoolId: schoolId, filters: filters)

            if response.data.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(response.data)
            }

            totalPages = response.totalPages
            totalCount = response.total

            // Cache to SwiftData
            cacheAttendance(response.data, schoolId: schoolId)
        } catch {
            // Offline fallback: read from SwiftData
            let cached = loadCachedAttendance(schoolId: schoolId)
            if !cached.isEmpty {
                viewState = .loaded(cached)
                totalCount = cached.count
            } else {
                viewState = .error(error)
                self.error = error
                showError = true
            }
        }
    }

    /// Load attendance for a specific date
    func loadAttendanceForDate(_ date: Date) async {
        selectedDate = date
        filters.dateFrom = Calendar.current.startOfDay(for: date)
        filters.dateTo = Calendar.current.date(byAdding: .day, value: 1, to: filters.dateFrom!)
        currentPage = 1
        await loadAttendance()
    }

    /// Load student statistics
    func loadStats() async {
        guard let schoolId = tenantContext?.schoolId,
              let studentId = getStudentId() else {
            return
        }

        do {
            stats = try await actions.getStats(studentId: studentId, schoolId: schoolId)
        } catch {
            // Stats are non-critical, don't show error
            Logger.attendance.error("Failed to load stats: \(error)")
        }
    }

    /// Load class attendance for marking
    func loadClassAttendance(classId: String, date: Date) async {
        guard let schoolId = tenantContext?.schoolId else {
            classAttendanceState = .error(AttendanceError.unauthorized)
            return
        }

        classAttendanceState = .loading

        do {
            let existingRecords = try await actions.getClassAttendance(
                classId: classId,
                date: date,
                schoolId: schoolId
            )

            let students = try await actions.getClassStudents(classId: classId, schoolId: schoolId)
            let classInfo: ClassInfo
            if let teacherClass = teacherClasses.first(where: { $0.id == classId }) {
                classInfo = ClassInfo(id: classId, name: teacherClass.name, nameAr: teacherClass.nameAr)
            } else {
                classInfo = ClassInfo(id: classId, name: "Class", nameAr: nil)
            }

            let data = ClassAttendanceState.ClassAttendanceData(
                classInfo: classInfo,
                students: students,
                existingRecords: existingRecords,
                date: date
            )

            classAttendanceState = .loaded(data)

            // Prepare mark rows
            markRows = students.map { student in
                let existing = existingRecords.first { $0.studentId == student.id }
                return AttendanceMarkRow(student: student, existingRecord: existing)
            }
        } catch {
            classAttendanceState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Load excuses for the current student (guardian view)
    func loadStudentExcuses() async {
        guard let schoolId = tenantContext?.schoolId,
              let studentId = getStudentId() else {
            return
        }

        do {
            studentExcuses = try await actions.getStudentExcuses(
                studentId: studentId,
                schoolId: schoolId
            )
        } catch {
            // Non-critical — don't block UI
            Logger.attendance.error("Failed to load student excuses: \(error)")
        }
    }

    /// Load pending excuses for review
    func loadPendingExcuses() async {
        guard let schoolId = tenantContext?.schoolId,
              capabilities.canReviewExcuse else {
            return
        }

        do {
            pendingExcuses = try await actions.getPendingExcuses(schoolId: schoolId)
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Load teacher's assigned classes
    func loadTeacherClasses() async {
        guard let schoolId = tenantContext?.schoolId,
              capabilities.canMarkAttendance else {
            return
        }

        do {
            teacherClasses = try await actions.getTeacherClasses(schoolId: schoolId)
            if selectedClassId == nil, let first = teacherClasses.first {
                selectedClassId = first.id
            }
        } catch {
            Logger.attendance.error("Failed to load teacher classes: \(error)")
        }
    }

    /// Refresh attendance (pull-to-refresh)
    func refresh() async {
        currentPage = 1
        await loadAttendance()
        await loadStats()
    }

    /// Load next page
    func loadNextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        await loadAttendance()
    }

    // MARK: - Filter Actions

    /// Filter by date range
    func filterByDateRange(from: Date?, to: Date?) {
        filters.dateFrom = from
        filters.dateTo = to
        currentPage = 1
        Task { await loadAttendance() }
    }

    /// Filter by status
    func filterByStatus(_ status: AttendanceStatus?) {
        filters.status = status
        currentPage = 1
        Task { await loadAttendance() }
    }

    /// Filter by class
    func filterByClass(_ classId: String?) {
        filters.classId = classId
        currentPage = 1
        Task { await loadAttendance() }
    }

    /// Clear all filters
    func clearFilters() {
        filters = AttendanceFilters()
        currentPage = 1
        Task { await loadAttendance() }
    }

    // MARK: - Mark Attendance Actions

    /// Show mark attendance form for single student
    func showMarkForm(studentId: String) {
        formMode = .markSingle(studentId: studentId)
        isShowingForm = true
    }

    /// Show mark attendance form for class
    func showMarkClassForm(classId: String) {
        formMode = .markClass(classId: classId)
        Task { await loadClassAttendance(classId: classId, date: selectedDate) }
        isShowingForm = true
    }

    /// Mark attendance for single student
    func markAttendance(
        studentId: String,
        status: AttendanceStatus,
        notes: String? = nil
    ) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            let request = AttendanceMarkRequest(
                studentId: studentId,
                date: selectedDate,
                status: status.rawValue,
                classId: filters.classId,
                periodId: filters.periodId,
                method: AttendanceMethod.manual.rawValue,
                notes: notes
            )

            _ = try await actions.markAttendance(request, schoolId: schoolId)

            successMessage = String(localized: "attendance.success.marked")
            showSuccess = true
            isShowingForm = false
            await loadAttendance()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    /// Bulk mark attendance for class
    func bulkMarkAttendance() async -> Bool {
        guard let schoolId = tenantContext?.schoolId,
              let classId = filters.classId else { return false }

        do {
            let records = markRows.map { row in
                AttendanceBulkMarkRequest.AttendanceRecord(
                    studentId: row.studentId,
                    status: row.status.rawValue,
                    notes: row.notes
                )
            }

            let request = AttendanceBulkMarkRequest(
                classId: classId,
                periodId: filters.periodId,
                date: selectedDate,
                records: records
            )

            _ = try await actions.bulkMarkAttendance(request, schoolId: schoolId)

            successMessage = String(localized: "attendance.success.bulkMarked")
            showSuccess = true
            isShowingForm = false
            await loadAttendance()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    /// Update mark row status
    func updateMarkRowStatus(for studentId: String, status: AttendanceStatus) {
        if let index = markRows.firstIndex(where: { $0.studentId == studentId }) {
            markRows[index].status = status
        }
    }

    /// Update mark row notes
    func updateMarkRowNotes(for studentId: String, notes: String?) {
        if let index = markRows.firstIndex(where: { $0.studentId == studentId }) {
            markRows[index].notes = notes
        }
    }

    /// Mark all students with status
    func markAll(status: AttendanceStatus) {
        for index in markRows.indices {
            markRows[index].status = status
        }
    }

    // MARK: - QR Check-in Actions

    /// Show QR scanner
    func showQRScanner() {
        qrScannerState = .idle
        isShowingQRScanner = true
    }

    /// Process scanned QR code
    func processQRCode(_ code: String) async {
        guard let schoolId = tenantContext?.schoolId,
              let studentId = getStudentId() else {
            qrScannerState = .error(AttendanceError.unauthorized)
            return
        }

        qrScannerState = .processing

        do {
            let request = QRCheckInRequest(qrCode: code, studentId: studentId)
            let response = try await actions.qrCheckIn(request, schoolId: schoolId)

            if response.success, let attendance = response.attendance {
                qrScannerState = .success(attendance)
                successMessage = String(localized: "attendance.success.checkedIn")
                showSuccess = true
                await loadAttendance()
            } else {
                qrScannerState = .error(AttendanceError.qrInvalid)
            }
        } catch {
            qrScannerState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Create QR session for class (Teacher)
    func createQRSession(classId: String, periodId: String?) async {
        guard let schoolId = tenantContext?.schoolId,
              capabilities.canMarkAttendance else {
            return
        }

        do {
            qrSession = try await actions.createQRSession(
                classId: classId,
                periodId: periodId,
                schoolId: schoolId
            )
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Excuse Actions

    /// Show excuse submission form
    func showExcuseForm(studentId: String, date: Date) {
        formMode = .submitExcuse(studentId: studentId, date: date)
        isShowingExcuseForm = true
    }

    /// Submit excuse
    func submitExcuse(
        studentId: String,
        date: Date,
        reason: String,
        documentUrl: String?
    ) async -> Bool {
        guard let schoolId = tenantContext?.schoolId else { return false }

        do {
            let request = ExcuseSubmitRequest(
                studentId: studentId,
                date: date,
                reason: reason,
                documentUrl: documentUrl
            )

            _ = try await actions.submitExcuse(request, schoolId: schoolId)

            successMessage = String(localized: "attendance.success.excuseSubmitted")
            showSuccess = true
            isShowingExcuseForm = false
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    /// Review excuse (approve/reject)
    func reviewExcuse(
        excuse: AttendanceExcuse,
        approved: Bool,
        notes: String?
    ) async -> Bool {
        guard let schoolId = tenantContext?.schoolId,
              capabilities.canReviewExcuse else { return false }

        do {
            let request = ExcuseReviewRequest(
                excuseId: excuse.id,
                status: approved ? "APPROVED" : "REJECTED",
                reviewNotes: notes
            )

            _ = try await actions.reviewExcuse(request, schoolId: schoolId)

            successMessage = String(localized: approved
                ? "attendance.success.excuseApproved"
                : "attendance.success.excuseRejected")
            showSuccess = true
            await loadPendingExcuses()
            return true
        } catch {
            self.error = error
            showError = true
            return false
        }
    }

    // MARK: - SwiftData Cache

    /// Cache attendance to SwiftData
    private func cacheAttendance(_ records: [Attendance], schoolId: String) {
        let context = DataContainer.shared.modelContext
        for record in records {
            let recordId = record.id
            let descriptor = FetchDescriptor<AttendanceModel>(
                predicate: #Predicate { $0.id == recordId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: record)
                existing.lastSyncedAt = Date()
            } else {
                let model = AttendanceModel(from: record, schoolId: schoolId)
                model.lastSyncedAt = Date()
                context.insert(model)
            }
        }
        try? context.save()
    }

    /// Load cached attendance from SwiftData
    private func loadCachedAttendance(schoolId: String) -> [Attendance] {
        let context = DataContainer.shared.modelContext
        var descriptor = FetchDescriptor<AttendanceModel>(
            predicate: #Predicate { $0.schoolId == schoolId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        guard let models = try? context.fetch(descriptor) else { return [] }
        return models.map { Attendance(from: $0) }
    }

    // MARK: - Helpers

    /// Get student ID for current user (student/guardian)
    private func getStudentId() -> String? {
        // For students, return their student ID
        // For guardians, return the selected child's ID
        // This would need to be configured based on auth setup
        return authManager?.currentUser?.id
    }
}
