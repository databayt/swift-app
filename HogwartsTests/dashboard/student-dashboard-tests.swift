import Foundation
import Testing
@testable import Hogwarts

/// Tests for Student Dashboard (DASH-001)
@Suite("Student Dashboard")
struct StudentDashboardTests {

    // MARK: - Schedule Item

    @Test("Schedule item decodes from JSON")
    func scheduleItemDecode() throws {
        let json = """
        {
            "id": "schedule-1",
            "subject": "Mathematics",
            "subjectAr": "الرياضيات",
            "startTime": "08:00",
            "endTime": "08:45",
            "room": "A101",
            "teacherName": "Mr. Smith",
            "isCurrent": true
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardScheduleItem.self, from: json)
        #expect(item.id == "schedule-1")
        #expect(item.subject == "Mathematics")
        #expect(item.displayName == "الرياضيات")
        #expect(item.isCurrent == true)
        #expect(item.room == "A101")
    }

    @Test("Schedule item uses subject when no Arabic name")
    func scheduleItemFallbackName() throws {
        let json = """
        {
            "id": "s2",
            "subject": "Science",
            "startTime": "09:00",
            "endTime": "09:45"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardScheduleItem.self, from: json)
        #expect(item.displayName == "Science")
        #expect(item.subjectAr == nil)
    }

    // MARK: - Grade Item

    @Test("Grade item calculates percentage")
    func gradeItemPercentage() throws {
        let json = """
        {
            "id": "g1",
            "subject": "Math",
            "examName": "Midterm",
            "score": 85.0,
            "maxScore": 100.0,
            "date": "2026-02-01"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardGradeItem.self, from: json)
        #expect(item.percentage == 85.0)
    }

    @Test("Grade item handles zero max score")
    func gradeItemZeroMax() throws {
        let json = """
        {
            "id": "g2",
            "subject": "Art",
            "examName": "Quiz",
            "score": 0.0,
            "maxScore": 0.0,
            "date": "2026-02-01"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardGradeItem.self, from: json)
        #expect(item.percentage == 0)
    }

    // MARK: - Attendance Summary

    @Test("Attendance summary calculates rate")
    func attendanceSummaryRate() throws {
        let json = """
        {
            "totalDays": 100,
            "presentDays": 85,
            "absentDays": 10,
            "lateDays": 5
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(DashboardAttendanceSummary.self, from: json)
        #expect(summary.attendanceRate == 85.0)
    }

    @Test("Attendance summary handles zero total")
    func attendanceSummaryZeroTotal() throws {
        let json = """
        {
            "totalDays": 0,
            "presentDays": 0,
            "absentDays": 0,
            "lateDays": 0
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(DashboardAttendanceSummary.self, from: json)
        #expect(summary.attendanceRate == 0)
    }

    @Test("Attendance summary perfect record")
    func attendancePerfect() throws {
        let json = """
        {
            "totalDays": 50,
            "presentDays": 50,
            "absentDays": 0,
            "lateDays": 0
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(DashboardAttendanceSummary.self, from: json)
        #expect(summary.attendanceRate == 100.0)
    }
}
