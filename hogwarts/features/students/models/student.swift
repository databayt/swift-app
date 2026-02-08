import Foundation
import SwiftData

/// Student model
/// Mirrors: prisma/models/students.prisma
@Model
final class StudentModel {
    @Attribute(.unique) var id: String
    var grNumber: String
    var userId: String
    var schoolId: String
    var yearLevelId: String?
    var batchId: String?
    var status: String

    // Personal info
    var givenName: String?
    var surname: String?
    var givenNameAr: String?
    var surnameAr: String?
    var dateOfBirth: Date?
    var gender: String?
    var nationality: String?
    var photoUrl: String?

    // Contact
    var email: String?
    var phone: String?
    var address: String?

    // Medical
    var bloodType: String?
    var allergies: String?
    var medicalConditions: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \AttendanceModel.student)
    var attendanceRecords: [AttendanceModel] = []

    @Relationship(deleteRule: .cascade, inverse: \ExamResultModel.student)
    var examResults: [ExamResultModel] = []

    // Sync metadata
    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false

    // Computed properties
    var fullName: String {
        [givenName, surname].compactMap { $0 }.joined(separator: " ")
    }

    var fullNameAr: String {
        [givenNameAr, surnameAr].compactMap { $0 }.joined(separator: " ")
    }

    var studentStatus: StudentStatus {
        StudentStatus(rawValue: status) ?? .active
    }

    init(
        id: String,
        grNumber: String,
        userId: String,
        schoolId: String,
        status: StudentStatus = .active
    ) {
        self.id = id
        self.grNumber = grNumber
        self.userId = userId
        self.schoolId = schoolId
        self.status = status.rawValue
    }

    /// Convenience init from API response
    convenience init(from student: Student, schoolId: String) {
        self.init(
            id: student.id,
            grNumber: student.grNumber,
            userId: student.userId,
            schoolId: schoolId,
            status: student.studentStatus
        )
        self.yearLevelId = student.yearLevelId
        self.batchId = student.batchId
        self.givenName = student.givenName
        self.surname = student.surname
        self.givenNameAr = student.givenNameAr
        self.surnameAr = student.surnameAr
        self.dateOfBirth = student.dateOfBirth
        self.gender = student.gender
        self.nationality = student.nationality
        self.photoUrl = student.photoUrl
        self.email = student.email
        self.phone = student.phone
        self.address = student.address
        self.bloodType = student.bloodType
        self.allergies = student.allergies
        self.medicalConditions = student.medicalConditions
    }

    /// Update from API response
    func update(from student: Student) {
        self.grNumber = student.grNumber
        self.status = student.status
        self.yearLevelId = student.yearLevelId
        self.batchId = student.batchId
        self.givenName = student.givenName
        self.surname = student.surname
        self.givenNameAr = student.givenNameAr
        self.surnameAr = student.surnameAr
        self.dateOfBirth = student.dateOfBirth
        self.gender = student.gender
        self.nationality = student.nationality
        self.photoUrl = student.photoUrl
        self.email = student.email
        self.phone = student.phone
        self.address = student.address
        self.bloodType = student.bloodType
        self.allergies = student.allergies
        self.medicalConditions = student.medicalConditions
    }
}

// MARK: - Enums

enum StudentStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case graduated = "GRADUATED"
    case transferred = "TRANSFERRED"
    case suspended = "SUSPENDED"

    var displayName: String {
        switch self {
        case .active: return String(localized: "student.status.active")
        case .inactive: return String(localized: "student.status.inactive")
        case .graduated: return String(localized: "student.status.graduated")
        case .transferred: return String(localized: "student.status.transferred")
        case .suspended: return String(localized: "student.status.suspended")
        }
    }
}

// MARK: - API Response Models

/// Student response from API
/// Used for decoding API responses
struct Student: Codable, Identifiable, Hashable {
    let id: String
    let grNumber: String
    let userId: String
    let schoolId: String
    let yearLevelId: String?
    let batchId: String?
    let status: String
    let givenName: String?
    let surname: String?
    let givenNameAr: String?
    let surnameAr: String?
    let dateOfBirth: Date?
    let gender: String?
    let nationality: String?
    let photoUrl: String?
    let email: String?
    let phone: String?
    let address: String?
    let bloodType: String?
    let allergies: String?
    let medicalConditions: String?
    let createdAt: Date?
    let updatedAt: Date?

    // Included relations
    let user: User?
    let yearLevel: YearLevel?

    var fullName: String {
        [givenName, surname].compactMap { $0 }.joined(separator: " ")
    }

    var studentStatus: StudentStatus {
        StudentStatus(rawValue: status) ?? .active
    }
}

struct YearLevel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameAr: String?
    let order: Int?
}

/// Paginated students response
struct StudentsResponse: Codable {
    let data: [Student]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}
