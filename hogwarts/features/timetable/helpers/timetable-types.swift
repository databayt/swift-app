import SwiftUI

/// Type definitions for Timetable feature
/// Mirrors: src/components/platform/timetable/types.ts

// MARK: - API Response Types

/// A single timetable entry (period/class slot)
struct TimetableEntry: Codable, Identifiable, Hashable {
    let id: String
    let subjectName: String
    let startTime: String
    let endTime: String
    let subjectNameAr: String?
    let teacherName: String?
    let classroomName: String?
    let classId: String?
    let dayOfWeek: Int?
    let periodNumber: Int?

    var displayName: String {
        subjectNameAr ?? subjectName
    }

    var timeRange: String {
        "\(startTime) - \(endTime)"
    }
}

/// Weekly schedule API response
struct WeeklyScheduleResponse: Codable {
    let entries: [TimetableEntry]
    let termName: String?
    let className: String?
}

/// Class detail response
struct ClassDetailResponse: Codable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let subject: String?
    let subjectAr: String?
    let teacherName: String?
    let room: String?
    let studentCount: Int?
    let students: [ClassStudent]?

    var displayName: String {
        nameAr ?? name
    }

    var displaySubject: String? {
        subjectAr ?? subject
    }
}

/// Student in a class detail
struct ClassStudent: Codable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let grNumber: String?
    let imageUrl: String?

    var displayName: String {
        nameAr ?? name
    }
}

// MARK: - View State

/// Timetable view state
enum TimetableViewState {
    case idle
    case loading
    case loaded(WeeklyScheduleResponse)
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var entries: [TimetableEntry] {
        if case .loaded(let response) = self { return response.entries }
        return []
    }
}

/// Display mode for timetable
enum TimetableDisplayMode: String, CaseIterable {
    case week
    case day

    var label: String {
        switch self {
        case .week: return String(localized: "timetable.view.week")
        case .day: return String(localized: "timetable.view.day")
        }
    }

    var icon: String {
        switch self {
        case .week: return "calendar"
        case .day: return "list.bullet"
        }
    }
}

// MARK: - Day of Week

/// Day of week helper
enum DayOfWeek: Int, CaseIterable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var shortName: String {
        switch self {
        case .sunday: return String(localized: "day.sun")
        case .monday: return String(localized: "day.mon")
        case .tuesday: return String(localized: "day.tue")
        case .wednesday: return String(localized: "day.wed")
        case .thursday: return String(localized: "day.thu")
        case .friday: return String(localized: "day.fri")
        case .saturday: return String(localized: "day.sat")
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return String(localized: "day.sunday")
        case .monday: return String(localized: "day.monday")
        case .tuesday: return String(localized: "day.tuesday")
        case .wednesday: return String(localized: "day.wednesday")
        case .thursday: return String(localized: "day.thursday")
        case .friday: return String(localized: "day.friday")
        case .saturday: return String(localized: "day.saturday")
        }
    }

    /// Returns the DayOfWeek for today
    static var today: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar weekday: 1 = Sunday, 7 = Saturday
        return DayOfWeek(rawValue: weekday - 1) ?? .sunday
    }
}

// MARK: - Role-Based Capabilities

/// Role-specific timetable capabilities
struct TimetableCapabilities {
    let canViewWeekly: Bool
    let canViewClassDetail: Bool
    let canViewStudentList: Bool

    static func forRole(_ role: UserRole) -> TimetableCapabilities {
        switch role {
        case .developer, .admin:
            return TimetableCapabilities(
                canViewWeekly: true,
                canViewClassDetail: true,
                canViewStudentList: true
            )
        case .teacher, .staff:
            return TimetableCapabilities(
                canViewWeekly: true,
                canViewClassDetail: true,
                canViewStudentList: true
            )
        case .student:
            return TimetableCapabilities(
                canViewWeekly: true,
                canViewClassDetail: true,
                canViewStudentList: false
            )
        case .guardian:
            return TimetableCapabilities(
                canViewWeekly: true,
                canViewClassDetail: true,
                canViewStudentList: false
            )
        case .accountant, .user:
            return TimetableCapabilities(
                canViewWeekly: false,
                canViewClassDetail: false,
                canViewStudentList: false
            )
        }
    }
}
