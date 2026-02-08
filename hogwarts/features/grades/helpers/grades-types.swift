import Foundation

/// Type definitions for Grades feature
/// Mirrors: src/components/platform/grades/types.ts

// MARK: - Filter Types

struct GradeFilters {
    var studentId: String?
    var classId: String?
    var subjectId: String?
    var examType: ExamType?
    var status: ExamStatus?
    var resultStatus: ResultStatus?
    var dateFrom: String?
    var dateTo: String?
    var page: Int = 1
    var pageSize: Int = 20
    var sortBy: SortField = .date
    var sortOrder: SortOrder = .descending

    enum SortField: String {
        case date = "examDate"
        case title = "title"
        case marks = "marks"
        case subject = "subjectId"
    }

    enum SortOrder: String {
        case ascending = "asc"
        case descending = "desc"
    }

    var queryParams: [String: String] {
        var params: [String: String] = [:]

        if let studentId = studentId { params["studentId"] = studentId }
        if let classId = classId { params["classId"] = classId }
        if let subjectId = subjectId { params["subjectId"] = subjectId }
        if let examType = examType { params["examType"] = examType.rawValue }
        if let status = status { params["status"] = status.rawValue }
        if let resultStatus = resultStatus { params["resultStatus"] = resultStatus.rawValue }
        if let dateFrom = dateFrom { params["dateFrom"] = dateFrom }
        if let dateTo = dateTo { params["dateTo"] = dateTo }

        params["page"] = String(page)
        params["pageSize"] = String(pageSize)
        params["sortBy"] = sortBy.rawValue
        params["sortOrder"] = sortOrder.rawValue

        return params
    }
}

// MARK: - View State

enum GradesViewState {
    case idle
    case loading
    case loaded([ExamResult])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var results: [ExamResult] {
        if case .loaded(let results) = self { return results }
        return []
    }
}

enum ExamsViewState {
    case idle
    case loading
    case loaded([Exam])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var exams: [Exam] {
        if case .loaded(let exams) = self { return exams }
        return []
    }
}

// MARK: - Form Modes

enum GradeFormMode {
    case createExam
    case editExam(Exam)
    case enterMarks(Exam)

    var title: String {
        switch self {
        case .createExam:
            return String(localized: "grade.form.createExamTitle")
        case .editExam:
            return String(localized: "grade.form.editExamTitle")
        case .enterMarks:
            return String(localized: "grade.form.enterMarksTitle")
        }
    }

    var exam: Exam? {
        switch self {
        case .editExam(let exam), .enterMarks(let exam):
            return exam
        default:
            return nil
        }
    }
}

// MARK: - Table Row

struct ExamResultRow: Identifiable, Hashable {
    let id: String
    let examTitle: String
    let subjectName: String
    let examType: ExamType
    let examDate: String
    let marks: Double?
    let totalMarks: Double
    let percentage: Double
    let grade: String
    let isPassing: Bool
    let status: ResultStatus

    init(from result: ExamResult) {
        self.id = result.id
        self.examTitle = result.exam?.title ?? ""
        self.subjectName = result.exam?.subject?.displayName ?? ""
        self.examType = result.exam?.examTypeEnum ?? .test
        self.examDate = result.exam?.examDate ?? ""
        self.marks = result.marks
        self.totalMarks = result.exam?.totalMarks ?? 0
        self.percentage = result.percentageValue
        self.grade = result.gradeLabel
        self.isPassing = result.isPassing
        self.status = result.resultStatusEnum
    }
}

/// Row for entering marks (editable)
struct GradeEntryRow: Identifiable {
    let id: String
    let studentId: String
    let studentName: String
    let grNumber: String
    var marks: String
    var remarks: String

    init(student: StudentInfo, existingResult: ExamResult? = nil) {
        self.id = student.id
        self.studentId = student.id
        self.studentName = student.fullName
        self.grNumber = student.grNumber
        self.marks = existingResult?.marks.map { String(format: "%.1f", $0) } ?? ""
        self.remarks = existingResult?.remarks ?? ""
    }
}

// MARK: - Report Card Types

struct ReportCard: Codable {
    let studentId: String
    let studentName: String
    let grNumber: String
    let yearLevel: String?
    let semester: String?
    let subjects: [SubjectGrade]
    let overallAverage: Double
    let gpa: Double
    let rank: Int?
    let totalStudents: Int?
    let attendance: ReportCardAttendance?
}

struct SubjectGrade: Codable, Identifiable {
    let id: String
    let subjectName: String
    let subjectNameAr: String?
    let exams: [ExamScore]
    let average: Double
    let grade: String

    var displayName: String {
        subjectNameAr ?? subjectName
    }
}

struct ExamScore: Codable, Identifiable {
    let id: String
    let examName: String
    let marks: Double
    let totalMarks: Double
    let percentage: Double
}

struct ReportCardAttendance: Codable {
    let totalDays: Int
    let presentDays: Int
    let absentDays: Int
    let lateDays: Int
    let attendanceRate: Double
}

// MARK: - Capabilities

struct GradeCapabilities {
    let canViewGrades: Bool
    let canEnterGrades: Bool
    let canCreateExams: Bool
    let canPublishGrades: Bool
    let canViewReportCard: Bool
    let canViewClassGrades: Bool

    static func forRole(_ role: UserRole) -> GradeCapabilities {
        switch role {
        case .developer, .admin:
            return GradeCapabilities(
                canViewGrades: true,
                canEnterGrades: true,
                canCreateExams: true,
                canPublishGrades: true,
                canViewReportCard: true,
                canViewClassGrades: true
            )
        case .teacher:
            return GradeCapabilities(
                canViewGrades: true,
                canEnterGrades: true,
                canCreateExams: true,
                canPublishGrades: true,
                canViewReportCard: true,
                canViewClassGrades: true
            )
        case .student:
            return GradeCapabilities(
                canViewGrades: true,
                canEnterGrades: false,
                canCreateExams: false,
                canPublishGrades: false,
                canViewReportCard: true,
                canViewClassGrades: false
            )
        case .guardian:
            return GradeCapabilities(
                canViewGrades: true,
                canEnterGrades: false,
                canCreateExams: false,
                canPublishGrades: false,
                canViewReportCard: true,
                canViewClassGrades: false
            )
        case .staff, .accountant, .user:
            return GradeCapabilities(
                canViewGrades: false,
                canEnterGrades: false,
                canCreateExams: false,
                canPublishGrades: false,
                canViewReportCard: false,
                canViewClassGrades: false
            )
        }
    }
}

// MARK: - Create Exam Request

struct CreateExamRequest: Encodable {
    let title: String
    let classId: String
    let subjectId: String
    let description: String?
    let examDate: String
    let totalMarks: Double
    let passingMarks: Double
    let examType: String
}

/// Submit marks request
struct SubmitMarksRequest: Encodable {
    let examId: String
    let results: [MarkEntry]

    struct MarkEntry: Encodable {
        let studentId: String
        let marks: Double
        let remarks: String?
    }
}
