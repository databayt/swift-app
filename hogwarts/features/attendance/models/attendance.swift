import Foundation
import SwiftData

/// Attendance model for SwiftData persistence
/// Mirrors: prisma/models/attendance.prisma
@Model
final class AttendanceModel {
    @Attribute(.unique) var id: String
    var studentId: String
    var classId: String?
    var periodId: String?
    var date: Date
    var status: String
    var method: String?
    var notes: String?
    var schoolId: String
    var markedById: String?
    var markedAt: Date?

    // Relationships
    var student: StudentModel?

    // Sync metadata
    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false

    // Computed properties
    var attendanceStatus: AttendanceStatus {
        AttendanceStatus(rawValue: status) ?? .present
    }

    var attendanceMethod: AttendanceMethod? {
        guard let method = method else { return nil }
        return AttendanceMethod(rawValue: method)
    }

    init(
        id: String = UUID().uuidString,
        studentId: String,
        date: Date,
        status: AttendanceStatus,
        schoolId: String,
        method: AttendanceMethod? = nil
    ) {
        self.id = id
        self.studentId = studentId
        self.date = date
        self.status = status.rawValue
        self.schoolId = schoolId
        self.method = method?.rawValue
        self.markedAt = Date()
    }

    /// Convenience init from API response
    convenience init(from attendance: Attendance, schoolId: String) {
        self.init(
            id: attendance.id,
            studentId: attendance.studentId,
            date: attendance.date,
            status: attendance.attendanceStatus,
            schoolId: schoolId,
            method: attendance.attendanceMethod
        )
        self.classId = attendance.classId
        self.periodId = attendance.periodId
        self.notes = attendance.notes
        self.markedById = attendance.markedById
        self.markedAt = attendance.markedAt
    }

    /// Update from API response
    func update(from attendance: Attendance) {
        self.status = attendance.status
        self.method = attendance.method
        self.classId = attendance.classId
        self.periodId = attendance.periodId
        self.notes = attendance.notes
        self.markedById = attendance.markedById
        self.markedAt = attendance.markedAt
    }
}

// MARK: - Attendance Status

/// Attendance status enum
/// Mirrors: prisma enum AttendanceStatus
enum AttendanceStatus: String, Codable, CaseIterable, Identifiable {
    case present = "PRESENT"
    case absent = "ABSENT"
    case late = "LATE"
    case excused = "EXCUSED"
    case sick = "SICK"
    case holiday = "HOLIDAY"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .present: return String(localized: "attendance.status.present")
        case .absent: return String(localized: "attendance.status.absent")
        case .late: return String(localized: "attendance.status.late")
        case .excused: return String(localized: "attendance.status.excused")
        case .sick: return String(localized: "attendance.status.sick")
        case .holiday: return String(localized: "attendance.status.holiday")
        }
    }

    var icon: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .absent: return "xmark.circle.fill"
        case .late: return "clock.fill"
        case .excused: return "doc.text.fill"
        case .sick: return "cross.case.fill"
        case .holiday: return "calendar.badge.clock"
        }
    }

    var color: String {
        switch self {
        case .present: return "green"
        case .absent: return "red"
        case .late: return "orange"
        case .excused: return "blue"
        case .sick: return "purple"
        case .holiday: return "gray"
        }
    }
}

// MARK: - Attendance Method

/// How attendance was marked
/// Mirrors: prisma enum AttendanceMethod
enum AttendanceMethod: String, Codable, CaseIterable {
    case manual = "MANUAL"
    case qrCode = "QR_CODE"
    case barcode = "BARCODE"
    case rfid = "RFID"
    case fingerprint = "FINGERPRINT"
    case faceRecognition = "FACE_RECOGNITION"
    case nfc = "NFC"
    case geofence = "GEOFENCE"
    case bluetooth = "BLUETOOTH"

    var displayName: String {
        switch self {
        case .manual: return String(localized: "attendance.method.manual")
        case .qrCode: return String(localized: "attendance.method.qrCode")
        case .barcode: return String(localized: "attendance.method.barcode")
        case .rfid: return String(localized: "attendance.method.rfid")
        case .fingerprint: return String(localized: "attendance.method.fingerprint")
        case .faceRecognition: return String(localized: "attendance.method.faceRecognition")
        case .nfc: return String(localized: "attendance.method.nfc")
        case .geofence: return String(localized: "attendance.method.geofence")
        case .bluetooth: return String(localized: "attendance.method.bluetooth")
        }
    }
}

// MARK: - API Response Models

/// Attendance response from API
struct Attendance: Codable, Identifiable, Hashable {
    let id: String
    let studentId: String
    let classId: String?
    let periodId: String?
    let date: Date
    let status: String
    let method: String?
    let notes: String?
    let schoolId: String
    let markedById: String?
    let markedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    // Included relations
    let student: StudentInfo?
    let class_: ClassInfo?
    let period: PeriodInfo?
    let markedBy: UserInfo?

    var attendanceStatus: AttendanceStatus {
        AttendanceStatus(rawValue: status) ?? .present
    }

    var attendanceMethod: AttendanceMethod? {
        guard let method = method else { return nil }
        return AttendanceMethod(rawValue: method)
    }

    enum CodingKeys: String, CodingKey {
        case id, studentId, classId, periodId, date, status, method
        case notes, schoolId, markedById, markedAt, createdAt, updatedAt
        case student, period, markedBy
        case class_ = "class"
    }
}

/// Student info for attendance (simplified)
struct StudentInfo: Codable, Hashable {
    let id: String
    let grNumber: String
    let givenName: String?
    let surname: String?
    let photoUrl: String?

    var fullName: String {
        [givenName, surname].compactMap { $0 }.joined(separator: " ")
    }
}

/// Class info for attendance
struct ClassInfo: Codable, Hashable {
    let id: String
    let name: String
    let nameAr: String?
}

/// Period info for attendance
struct PeriodInfo: Codable, Hashable {
    let id: String
    let name: String
    let startTime: String?
    let endTime: String?
}

/// User info for markedBy
struct UserInfo: Codable, Hashable {
    let id: String
    let name: String?
    let email: String
}

/// Paginated attendance response
struct AttendanceResponse: Codable {
    let data: [Attendance]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - Attendance Statistics

/// Attendance statistics for a student/class
struct AttendanceStats: Codable {
    let totalDays: Int
    let presentDays: Int
    let absentDays: Int
    let lateDays: Int
    let excusedDays: Int
    let sickDays: Int

    var attendanceRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(presentDays + lateDays) / Double(totalDays) * 100
    }

    var presentPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(presentDays) / Double(totalDays) * 100
    }

    var absentPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(absentDays) / Double(totalDays) * 100
    }
}

// MARK: - Attendance Excuse

/// Attendance excuse model
struct AttendanceExcuse: Codable, Identifiable {
    let id: String
    let studentId: String
    let date: Date
    let reason: String
    let documentUrl: String?
    let status: ExcuseStatus
    let submittedById: String
    let reviewedById: String?
    let reviewedAt: Date?
    let createdAt: Date?

    enum ExcuseStatus: String, Codable {
        case pending = "PENDING"
        case approved = "APPROVED"
        case rejected = "REJECTED"

        var displayName: String {
            switch self {
            case .pending: return String(localized: "excuse.status.pending")
            case .approved: return String(localized: "excuse.status.approved")
            case .rejected: return String(localized: "excuse.status.rejected")
            }
        }
    }
}

// MARK: - QR Session

/// QR code session for attendance
struct QRSession: Codable {
    let id: String
    let classId: String
    let periodId: String?
    let code: String
    let expiresAt: Date
    let schoolId: String

    var isExpired: Bool {
        Date() > expiresAt
    }
}

/// QR check-in response
struct QRCheckInResponse: Codable {
    let success: Bool
    let message: String
    let attendance: Attendance?
}
