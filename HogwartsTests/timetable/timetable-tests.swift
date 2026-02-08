import Foundation
import Testing
@testable import Hogwarts

/// Tests for Timetable feature types, DayOfWeek, and capabilities
@Suite("Timetable")
struct TimetableTests {

    // MARK: - TimetableEntry

    @Test("TimetableEntry displayName returns nameAr when available")
    func entryDisplayNameAr() {
        let entry = TimetableEntry(
            id: "tt_1", subjectName: "Mathematics",
            startTime: "08:00", endTime: "09:00",
            subjectNameAr: "الرياضيات", teacherName: nil,
            classroomName: nil, classId: nil,
            dayOfWeek: 1, periodNumber: 1
        )
        #expect(entry.displayName == "الرياضيات")
    }

    @Test("TimetableEntry displayName falls back to subjectName")
    func entryDisplayNameFallback() {
        let entry = TimetableEntry(
            id: "tt_1", subjectName: "Mathematics",
            startTime: "08:00", endTime: "09:00",
            subjectNameAr: nil, teacherName: nil,
            classroomName: nil, classId: nil,
            dayOfWeek: 1, periodNumber: 1
        )
        #expect(entry.displayName == "Mathematics")
    }

    @Test("TimetableEntry timeRange formats correctly")
    func entryTimeRange() {
        let entry = TimetableEntry(
            id: "tt_1", subjectName: "Science",
            startTime: "08:00", endTime: "09:00",
            subjectNameAr: nil, teacherName: nil,
            classroomName: nil, classId: nil,
            dayOfWeek: 1, periodNumber: 1
        )
        #expect(entry.timeRange == "08:00 - 09:00")
    }

    // MARK: - DayOfWeek

    @Test("DayOfWeek rawValues are 0-6")
    func dayOfWeekRawValues() {
        #expect(DayOfWeek.sunday.rawValue == 0)
        #expect(DayOfWeek.monday.rawValue == 1)
        #expect(DayOfWeek.tuesday.rawValue == 2)
        #expect(DayOfWeek.wednesday.rawValue == 3)
        #expect(DayOfWeek.thursday.rawValue == 4)
        #expect(DayOfWeek.friday.rawValue == 5)
        #expect(DayOfWeek.saturday.rawValue == 6)
    }

    @Test("DayOfWeek has 7 cases")
    func dayOfWeekCaseCount() {
        #expect(DayOfWeek.allCases.count == 7)
    }

    @Test("DayOfWeek today returns a valid case")
    func dayOfWeekToday() {
        let today = DayOfWeek.today
        #expect(DayOfWeek.allCases.contains(today))
    }

    @Test("DayOfWeek can be initialized from rawValue")
    func dayOfWeekFromRawValue() {
        let day = DayOfWeek(rawValue: 3)
        #expect(day == .wednesday)
    }

    @Test("DayOfWeek invalid rawValue returns nil")
    func dayOfWeekInvalidRawValue() {
        let day = DayOfWeek(rawValue: 99)
        #expect(day == nil)
    }

    // MARK: - TimetableDisplayMode

    @Test("TimetableDisplayMode rawValues")
    func displayModeRawValues() {
        #expect(TimetableDisplayMode.week.rawValue == "week")
        #expect(TimetableDisplayMode.day.rawValue == "day")
    }

    @Test("TimetableDisplayMode has 2 cases")
    func displayModeCaseCount() {
        #expect(TimetableDisplayMode.allCases.count == 2)
    }

    @Test("TimetableDisplayMode icons are correct")
    func displayModeIcons() {
        #expect(TimetableDisplayMode.week.icon == "calendar")
        #expect(TimetableDisplayMode.day.icon == "list.bullet")
    }

    // MARK: - TimetableViewState

    @Test("TimetableViewState loading isLoading is true")
    func viewStateLoading() {
        let state = TimetableViewState.loading
        #expect(state.isLoading)
    }

    @Test("TimetableViewState idle isLoading is false")
    func viewStateIdle() {
        let state = TimetableViewState.idle
        #expect(!state.isLoading)
    }

    @Test("TimetableViewState idle returns empty entries")
    func viewStateIdleEntries() {
        let state = TimetableViewState.idle
        #expect(state.entries.isEmpty)
    }

    // MARK: - TimetableCapabilities

    @Test("Admin timetable capabilities allow all")
    func adminCapabilities() {
        let caps = TimetableCapabilities.forRole(.admin)
        #expect(caps.canViewWeekly)
        #expect(caps.canViewClassDetail)
        #expect(caps.canViewStudentList)
    }

    @Test("Student timetable capabilities restrict student list")
    func studentCapabilities() {
        let caps = TimetableCapabilities.forRole(.student)
        #expect(caps.canViewWeekly)
        #expect(caps.canViewClassDetail)
        #expect(!caps.canViewStudentList)
    }

    @Test("Accountant timetable capabilities deny all")
    func accountantCapabilities() {
        let caps = TimetableCapabilities.forRole(.accountant)
        #expect(!caps.canViewWeekly)
        #expect(!caps.canViewClassDetail)
        #expect(!caps.canViewStudentList)
    }

    // MARK: - ClassDetailResponse

    @Test("ClassDetailResponse displayName returns nameAr when available")
    func classDetailDisplayNameAr() {
        let detail = ClassDetailResponse(
            id: "cls_1", name: "Grade 10A",
            nameAr: "الصف العاشر أ", subject: nil,
            subjectAr: nil, teacherName: nil,
            room: nil, studentCount: nil, students: nil
        )
        #expect(detail.displayName == "الصف العاشر أ")
    }

    @Test("ClassDetailResponse displayName falls back to name")
    func classDetailDisplayNameFallback() {
        let detail = ClassDetailResponse(
            id: "cls_1", name: "Grade 10A",
            nameAr: nil, subject: nil,
            subjectAr: nil, teacherName: nil,
            room: nil, studentCount: nil, students: nil
        )
        #expect(detail.displayName == "Grade 10A")
    }

    @Test("ClassDetailResponse displaySubject returns subjectAr when available")
    func classDetailDisplaySubjectAr() {
        let detail = ClassDetailResponse(
            id: "cls_1", name: "Grade 10A",
            nameAr: nil, subject: "Mathematics",
            subjectAr: "الرياضيات", teacherName: nil,
            room: nil, studentCount: nil, students: nil
        )
        #expect(detail.displaySubject == "الرياضيات")
    }
}
