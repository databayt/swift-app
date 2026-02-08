import Foundation

/// Dashboard data types shared across role-specific dashboards
/// Mirrors: src/components/platform/dashboard/types.ts

// MARK: - Schedule

struct DashboardScheduleItem: Codable, Identifiable {
    let id: String
    let subject: String
    let subjectAr: String?
    let startTime: String
    let endTime: String
    let room: String?
    let teacherName: String?
    let isCurrent: Bool?

    var displayName: String {
        subjectAr ?? subject
    }
}

// MARK: - Grades

struct DashboardGradeItem: Codable, Identifiable {
    let id: String
    let subject: String
    let subjectAr: String?
    let examName: String
    let score: Double
    let maxScore: Double
    let date: String

    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }

    var displaySubject: String {
        subjectAr ?? subject
    }
}

// MARK: - Attendance Summary

struct DashboardAttendanceSummary: Codable {
    let totalDays: Int
    let presentDays: Int
    let absentDays: Int
    let lateDays: Int

    var attendanceRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(presentDays) / Double(totalDays) * 100
    }
}

// MARK: - Teacher Dashboard

struct DashboardClassItem: Codable, Identifiable {
    let id: String
    let subject: String
    let subjectAr: String?
    let startTime: String
    let endTime: String
    let room: String?
    let yearLevel: String?
    let studentCount: Int
    let attendanceMarked: Bool

    var displayName: String {
        subjectAr ?? subject
    }
}

// MARK: - Guardian Dashboard

struct DashboardChild: Codable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let imageUrl: String?
    let yearLevel: String?

    var displayName: String {
        nameAr ?? name
    }
}

struct DashboardMessagePreview: Codable, Identifiable {
    let id: String
    let senderName: String
    let subject: String
    let preview: String
    let date: String
    let isRead: Bool
}
