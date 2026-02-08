import Foundation
import SwiftData

// MARK: - Exam Result Model

/// Exam result model
/// Mirrors: prisma/models/exam.prisma ExamResult
@Model
final class ExamResultModel {
    @Attribute(.unique) var id: String
    var studentId: String
    var examId: String
    var marks: Double?
    var grade: String?
    var percentage: Double?
    var remarks: String?
    var schoolId: String

    var student: StudentModel?

    var lastSyncedAt: Date?

    init(
        id: String,
        studentId: String,
        examId: String,
        schoolId: String
    ) {
        self.id = id
        self.studentId = studentId
        self.examId = examId
        self.schoolId = schoolId
    }

    /// Convenience init from API response
    convenience init(from result: ExamResult, schoolId: String) {
        self.init(
            id: result.id,
            studentId: result.studentId,
            examId: result.examId,
            schoolId: schoolId
        )
        self.marks = result.marks
        self.grade = result.grade
        self.percentage = result.percentage
        self.remarks = result.remarks
    }

    /// Update from API response
    func update(from result: ExamResult) {
        self.marks = result.marks
        self.grade = result.grade
        self.percentage = result.percentage
        self.remarks = result.remarks
    }
}

// MARK: - Timetable Model

/// Timetable entry model
/// Mirrors: prisma/models/timetable.prisma
@Model
final class TimetableModel {
    @Attribute(.unique) var id: String
    var dayOfWeek: Int  // 0 = Sunday, 6 = Saturday
    var startTime: Date
    var endTime: Date
    var subjectId: String?
    var teacherId: String?
    var classroomId: String?
    var schoolId: String

    var subjectName: String?
    var teacherName: String?
    var classroomName: String?

    var lastSyncedAt: Date?

    init(
        id: String,
        dayOfWeek: Int,
        startTime: Date,
        endTime: Date,
        schoolId: String
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.schoolId = schoolId
    }

    /// Convenience init from API response
    convenience init(from entry: TimetableEntry, schoolId: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.date(from: entry.startTime) ?? Date()
        let end = formatter.date(from: entry.endTime) ?? Date()

        self.init(
            id: entry.id,
            dayOfWeek: entry.dayOfWeek ?? 0,
            startTime: start,
            endTime: end,
            schoolId: schoolId
        )
        self.subjectName = entry.subjectName
        self.teacherName = entry.teacherName
        self.classroomName = entry.classroomName
    }

    /// Update from API response
    func update(from entry: TimetableEntry) {
        self.dayOfWeek = entry.dayOfWeek ?? self.dayOfWeek
        self.subjectName = entry.subjectName
        self.teacherName = entry.teacherName
        self.classroomName = entry.classroomName

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let start = formatter.date(from: entry.startTime) {
            self.startTime = start
        }
        if let end = formatter.date(from: entry.endTime) {
            self.endTime = end
        }
    }
}

// MARK: - Message Models

/// Conversation model
/// Mirrors: prisma/models/messages.prisma
@Model
final class ConversationModel {
    @Attribute(.unique) var id: String
    var name: String?
    var isGroup: Bool
    var schoolId: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MessageModel.conversation)
    var messages: [MessageModel] = []

    var lastSyncedAt: Date?

    init(id: String, schoolId: String) {
        self.id = id
        self.schoolId = schoolId
        self.isGroup = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Convenience init from API response
    convenience init(from conversation: Conversation, schoolId: String) {
        self.init(id: conversation.id, schoolId: schoolId)
        self.name = conversation.name
        self.isGroup = conversation.isGroup
        self.createdAt = conversation.createdAt
        self.updatedAt = conversation.updatedAt
    }

    /// Update from API response
    func update(from conversation: Conversation) {
        self.name = conversation.name
        self.isGroup = conversation.isGroup
        self.updatedAt = conversation.updatedAt
    }
}

/// Message model
@Model
final class MessageModel {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var content: String
    var createdAt: Date
    var readAt: Date?

    var conversation: ConversationModel?

    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false

    init(
        id: String,
        conversationId: String,
        senderId: String,
        content: String
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - Notification Model

/// Notification model
/// Mirrors: prisma/models/notifications.prisma
@Model
final class NotificationModel {
    @Attribute(.unique) var id: String
    var userId: String
    var type: String
    var title: String
    var message: String
    var data: Data?  // JSON data
    var isRead: Bool
    var createdAt: Date
    var schoolId: String

    var lastSyncedAt: Date?

    init(
        id: String,
        userId: String,
        type: String,
        title: String,
        message: String,
        schoolId: String
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.schoolId = schoolId
        self.isRead = false
        self.createdAt = Date()
    }

    /// Convenience init from API response
    convenience init(from notification: AppNotification) {
        self.init(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            schoolId: notification.schoolId
        )
        self.isRead = notification.isRead
        self.createdAt = notification.createdAt
        if let data = notification.data?.data(using: .utf8) {
            self.data = data
        }
    }

    /// Update from API response
    func update(from notification: AppNotification) {
        self.title = notification.title
        self.message = notification.message
        self.isRead = notification.isRead
        if let data = notification.data?.data(using: .utf8) {
            self.data = data
        }
    }
}

// MARK: - Teacher Model

/// Teacher model
/// Mirrors: prisma/models/staff.prisma
@Model
final class TeacherModel {
    @Attribute(.unique) var id: String
    var userId: String
    var schoolId: String
    var employeeId: String?
    var departmentId: String?
    var status: String

    var lastSyncedAt: Date?

    init(
        id: String,
        userId: String,
        schoolId: String
    ) {
        self.id = id
        self.userId = userId
        self.schoolId = schoolId
        self.status = "ACTIVE"
    }
}

// MARK: - Guardian Model

/// Guardian model
/// Mirrors: prisma/models/students.prisma Guardian
@Model
final class GuardianModel {
    @Attribute(.unique) var id: String
    var userId: String
    var schoolId: String
    var relationship: String?
    var occupation: String?

    var lastSyncedAt: Date?

    init(
        id: String,
        userId: String,
        schoolId: String
    ) {
        self.id = id
        self.userId = userId
        self.schoolId = schoolId
    }
}

// MARK: - School Model

/// School model for SwiftData
@Model
final class SchoolModel {
    @Attribute(.unique) var id: String
    var name: String
    var nameAr: String?
    var domain: String
    var email: String?
    var phone: String?
    var logoUrl: String?
    var plan: String?

    var lastSyncedAt: Date?

    init(id: String, name: String, domain: String) {
        self.id = id
        self.name = name
        self.domain = domain
    }
}
