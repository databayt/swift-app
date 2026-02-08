import Foundation

/// Type definitions for Attendance feature
/// Mirrors: src/components/platform/attendance/types.ts

// MARK: - Request Types

/// Mark attendance request (single student)
struct AttendanceMarkRequest: Encodable {
    let studentId: String
    let date: Date
    let status: String
    let classId: String?
    let periodId: String?
    let method: String?
    let notes: String?
}

/// Bulk mark attendance request (multiple students)
struct AttendanceBulkMarkRequest: Encodable {
    let classId: String
    let periodId: String?
    let date: Date
    let records: [AttendanceRecord]

    struct AttendanceRecord: Encodable {
        let studentId: String
        let status: String
        let notes: String?
    }
}

/// QR check-in request
struct QRCheckInRequest: Encodable {
    let qrCode: String
    let studentId: String
}

/// Submit excuse request
struct ExcuseSubmitRequest: Encodable {
    let studentId: String
    let date: Date
    let reason: String
    let documentUrl: String?
}

/// Review excuse request (Admin/Teacher)
struct ExcuseReviewRequest: Encodable {
    let excuseId: String
    let status: String // APPROVED or REJECTED
    let reviewNotes: String?
}

// MARK: - Filter Types

/// Attendance list filters
/// Mirrors: Search params in content.tsx
struct AttendanceFilters {
    var studentId: String?
    var classId: String?
    var periodId: String?
    var status: AttendanceStatus?
    var dateFrom: Date?
    var dateTo: Date?
    var page: Int = 1
    var pageSize: Int = 20
    var sortBy: SortField = .date
    var sortOrder: SortOrder = .descending

    enum SortField: String {
        case date = "date"
        case status = "status"
        case studentName = "student.givenName"
        case markedAt = "markedAt"
    }

    enum SortOrder: String {
        case ascending = "asc"
        case descending = "desc"
    }

    /// Convert to query parameters
    var queryParams: [String: String] {
        var params: [String: String] = [:]

        if let studentId = studentId {
            params["studentId"] = studentId
        }
        if let classId = classId {
            params["classId"] = classId
        }
        if let periodId = periodId {
            params["periodId"] = periodId
        }
        if let status = status {
            params["status"] = status.rawValue
        }
        if let dateFrom = dateFrom {
            params["dateFrom"] = ISO8601DateFormatter().string(from: dateFrom)
        }
        if let dateTo = dateTo {
            params["dateTo"] = ISO8601DateFormatter().string(from: dateTo)
        }

        params["page"] = String(page)
        params["pageSize"] = String(pageSize)
        params["sortBy"] = sortBy.rawValue
        params["sortOrder"] = sortOrder.rawValue

        return params
    }
}

/// Excuse list filters
struct ExcuseFilters {
    var studentId: String?
    var status: AttendanceExcuse.ExcuseStatus?
    var dateFrom: Date?
    var dateTo: Date?
    var page: Int = 1
    var pageSize: Int = 20
}

// MARK: - SwiftData Conversion

extension Attendance {
    /// Create API model from SwiftData model (for offline reads)
    init(from model: AttendanceModel) {
        self.init(
            id: model.id,
            studentId: model.studentId,
            classId: model.classId,
            periodId: model.periodId,
            date: model.date,
            status: model.status,
            method: model.method,
            notes: model.notes,
            schoolId: model.schoolId,
            markedById: model.markedById,
            markedAt: model.markedAt,
            createdAt: nil,
            updatedAt: nil,
            student: nil,
            class_: nil,
            period: nil,
            markedBy: nil
        )
    }
}

// MARK: - View State

/// Attendance list view state
enum AttendanceViewState {
    case idle
    case loading
    case loaded([Attendance])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var attendance: [Attendance] {
        if case .loaded(let records) = self { return records }
        return []
    }
}

/// Class attendance view state (for teachers)
enum ClassAttendanceState {
    case idle
    case loading
    case loaded(ClassAttendanceData)
    case error(Error)

    struct ClassAttendanceData {
        let classInfo: ClassInfo
        let students: [StudentInfo]
        let existingRecords: [Attendance]
        let date: Date
    }
}

/// QR scanner state
enum QRScannerState {
    case idle
    case scanning
    case processing
    case success(Attendance)
    case error(Error)
}

// MARK: - Form Modes

/// Attendance form mode
enum AttendanceFormMode {
    case markSingle(studentId: String)
    case markClass(classId: String)
    case submitExcuse(studentId: String, date: Date)
    case reviewExcuse(excuse: AttendanceExcuse)

    var title: String {
        switch self {
        case .markSingle:
            return String(localized: "attendance.form.markTitle")
        case .markClass:
            return String(localized: "attendance.form.markClassTitle")
        case .submitExcuse:
            return String(localized: "attendance.form.excuseTitle")
        case .reviewExcuse:
            return String(localized: "attendance.form.reviewTitle")
        }
    }
}

// MARK: - Table Row

/// Row type for attendance table
/// Mirrors: Column definitions in columns.tsx
struct AttendanceRow: Identifiable, Hashable {
    let id: String
    let studentId: String
    let studentName: String
    let studentPhoto: String?
    let grNumber: String
    let date: Date
    let status: AttendanceStatus
    let method: AttendanceMethod?
    let className: String?
    let periodName: String?
    let notes: String?
    let markedAt: Date?
    let markedByName: String?

    init(from attendance: Attendance) {
        self.id = attendance.id
        self.studentId = attendance.studentId
        self.studentName = attendance.student?.fullName ?? ""
        self.studentPhoto = attendance.student?.photoUrl
        self.grNumber = attendance.student?.grNumber ?? ""
        self.date = attendance.date
        self.status = attendance.attendanceStatus
        self.method = attendance.attendanceMethod
        self.className = attendance.class_?.name
        self.periodName = attendance.period?.name
        self.notes = attendance.notes
        self.markedAt = attendance.markedAt
        self.markedByName = attendance.markedBy?.name
    }
}

/// Row for marking attendance (editable)
struct AttendanceMarkRow: Identifiable {
    let id: String
    let studentId: String
    let studentName: String
    let studentPhoto: String?
    let grNumber: String
    var status: AttendanceStatus
    var notes: String?
    var existingRecordId: String?

    init(student: StudentInfo, existingRecord: Attendance? = nil) {
        self.id = student.id
        self.studentId = student.id
        self.studentName = student.fullName
        self.studentPhoto = student.photoUrl
        self.grNumber = student.grNumber
        self.status = existingRecord?.attendanceStatus ?? .present
        self.notes = existingRecord?.notes
        self.existingRecordId = existingRecord?.id
    }
}

// MARK: - Statistics Display

/// Attendance stats display data
struct AttendanceStatsDisplay {
    let totalDays: Int
    let presentDays: Int
    let absentDays: Int
    let lateDays: Int
    let excusedDays: Int
    let sickDays: Int
    let attendanceRate: Double

    init(from stats: AttendanceStats) {
        self.totalDays = stats.totalDays
        self.presentDays = stats.presentDays
        self.absentDays = stats.absentDays
        self.lateDays = stats.lateDays
        self.excusedDays = stats.excusedDays
        self.sickDays = stats.sickDays
        self.attendanceRate = stats.attendanceRate
    }

    /// Status breakdown for charts
    var breakdown: [(status: AttendanceStatus, count: Int, percentage: Double)] {
        guard totalDays > 0 else { return [] }
        return [
            (.present, presentDays, Double(presentDays) / Double(totalDays) * 100),
            (.absent, absentDays, Double(absentDays) / Double(totalDays) * 100),
            (.late, lateDays, Double(lateDays) / Double(totalDays) * 100),
            (.excused, excusedDays, Double(excusedDays) / Double(totalDays) * 100),
            (.sick, sickDays, Double(sickDays) / Double(totalDays) * 100)
        ].filter { $0.count > 0 }
    }
}

// MARK: - Role-Based Configurations

/// Role-specific attendance capabilities
struct AttendanceCapabilities {
    let canMarkAttendance: Bool
    let canViewClassAttendance: Bool
    let canViewOwnAttendance: Bool
    let canSubmitExcuse: Bool
    let canReviewExcuse: Bool
    let canQRCheckIn: Bool
    let canOverrideRecords: Bool
    let canViewReports: Bool

    static func forRole(_ role: UserRole) -> AttendanceCapabilities {
        switch role {
        case .developer, .admin:
            return AttendanceCapabilities(
                canMarkAttendance: true,
                canViewClassAttendance: true,
                canViewOwnAttendance: true,
                canSubmitExcuse: false,
                canReviewExcuse: true,
                canQRCheckIn: false,
                canOverrideRecords: true,
                canViewReports: true
            )
        case .teacher, .staff:
            return AttendanceCapabilities(
                canMarkAttendance: true,
                canViewClassAttendance: true,
                canViewOwnAttendance: false,
                canSubmitExcuse: false,
                canReviewExcuse: true,
                canQRCheckIn: false,
                canOverrideRecords: false,
                canViewReports: true
            )
        case .student:
            return AttendanceCapabilities(
                canMarkAttendance: false,
                canViewClassAttendance: false,
                canViewOwnAttendance: true,
                canSubmitExcuse: false,
                canReviewExcuse: false,
                canQRCheckIn: true,
                canOverrideRecords: false,
                canViewReports: false
            )
        case .guardian:
            return AttendanceCapabilities(
                canMarkAttendance: false,
                canViewClassAttendance: false,
                canViewOwnAttendance: true,
                canSubmitExcuse: true,
                canReviewExcuse: false,
                canQRCheckIn: false,
                canOverrideRecords: false,
                canViewReports: false
            )
        case .accountant, .user:
            return AttendanceCapabilities(
                canMarkAttendance: false,
                canViewClassAttendance: false,
                canViewOwnAttendance: false,
                canSubmitExcuse: false,
                canReviewExcuse: false,
                canQRCheckIn: false,
                canOverrideRecords: false,
                canViewReports: false
            )
        }
    }
}

// MARK: - Teacher Class Types

/// Info about a class assigned to a teacher
struct TeacherClassItem: Codable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let yearLevel: String?
    let studentCount: Int

    var displayName: String {
        nameAr ?? name
    }
}
