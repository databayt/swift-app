import Foundation

/// Grade models for exam results
/// Mirrors: prisma/models/grades.prisma

// MARK: - Enums

enum ExamType: String, Codable, CaseIterable {
    case midterm = "MIDTERM"
    case final_ = "FINAL"
    case quiz = "QUIZ"
    case test = "TEST"
    case practical = "PRACTICAL"
    case assignment = "ASSIGNMENT"

    var displayName: String {
        switch self {
        case .midterm: return String(localized: "grade.examType.midterm")
        case .final_: return String(localized: "grade.examType.final")
        case .quiz: return String(localized: "grade.examType.quiz")
        case .test: return String(localized: "grade.examType.test")
        case .practical: return String(localized: "grade.examType.practical")
        case .assignment: return String(localized: "grade.examType.assignment")
        }
    }
}

enum ExamStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case scheduled = "SCHEDULED"
    case completed = "COMPLETED"
    case published = "PUBLISHED"

    var displayName: String {
        switch self {
        case .draft: return String(localized: "grade.status.draft")
        case .scheduled: return String(localized: "grade.status.scheduled")
        case .completed: return String(localized: "grade.status.completed")
        case .published: return String(localized: "grade.status.published")
        }
    }
}

enum ResultStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case graded = "GRADED"
    case published = "PUBLISHED"

    var displayName: String {
        switch self {
        case .pending: return String(localized: "grade.resultStatus.pending")
        case .graded: return String(localized: "grade.resultStatus.graded")
        case .published: return String(localized: "grade.resultStatus.published")
        }
    }
}

// MARK: - API Response Models

struct SubjectInfo: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameAr: String?

    var displayName: String {
        nameAr ?? name
    }
}

struct Exam: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let classId: String
    let subjectId: String
    let schoolId: String
    let description: String?
    let examDate: String
    let totalMarks: Double
    let passingMarks: Double
    let examType: String
    let status: String
    let createdAt: String?
    let updatedAt: String?
    let subject: SubjectInfo?

    var examTypeEnum: ExamType {
        ExamType(rawValue: examType) ?? .test
    }

    var examStatusEnum: ExamStatus {
        ExamStatus(rawValue: status) ?? .draft
    }

    static func == (lhs: Exam, rhs: Exam) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ExamResult: Codable, Identifiable, Hashable {
    let id: String
    let examId: String
    let studentId: String
    let schoolId: String
    let marks: Double?
    let percentage: Double?
    let grade: String?
    let status: String
    let remarks: String?
    let createdAt: String?
    let updatedAt: String?
    let exam: Exam?
    let student: StudentInfo?

    var resultStatusEnum: ResultStatus {
        ResultStatus(rawValue: status) ?? .pending
    }

    var isPassing: Bool {
        guard let marks = marks, let exam = exam else { return false }
        return marks >= exam.passingMarks
    }

    var percentageValue: Double {
        if let percentage = percentage { return percentage }
        guard let marks = marks, let exam = exam, exam.totalMarks > 0 else { return 0 }
        return (marks / exam.totalMarks) * 100
    }

    var gradeLabel: String {
        grade ?? GradeCalculator.letterGrade(for: percentageValue)
    }

    static func == (lhs: ExamResult, rhs: ExamResult) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Paginated exams response
struct ExamsResponse: Codable {
    let data: [Exam]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

/// Paginated exam results response
struct ExamResultsResponse: Codable {
    let data: [ExamResult]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - Grade Calculator

struct GradeCalculator {
    static func letterGrade(for percentage: Double) -> String {
        switch percentage {
        case 90...: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "B+"
        case 75..<80: return "B"
        case 70..<75: return "C+"
        case 65..<70: return "C"
        case 60..<65: return "D+"
        case 50..<60: return "D"
        default: return "F"
        }
    }

    static func gpa(for percentage: Double) -> Double {
        switch percentage {
        case 90...: return 4.0
        case 85..<90: return 3.7
        case 80..<85: return 3.3
        case 75..<80: return 3.0
        case 70..<75: return 2.7
        case 65..<70: return 2.3
        case 60..<65: return 2.0
        case 50..<60: return 1.0
        default: return 0.0
        }
    }
}
