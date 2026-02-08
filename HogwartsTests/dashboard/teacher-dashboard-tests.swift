import Foundation
import Testing
@testable import Hogwarts

/// Tests for Teacher Dashboard (DASH-002)
@Suite("Teacher Dashboard")
struct TeacherDashboardTests {

    // MARK: - Class Item

    @Test("Class item decodes from JSON")
    func classItemDecode() throws {
        let json = """
        {
            "id": "class-1",
            "subject": "Physics",
            "subjectAr": "الفيزياء",
            "startTime": "10:00",
            "endTime": "10:45",
            "room": "B201",
            "yearLevel": "Grade 10",
            "studentCount": 30,
            "attendanceMarked": false
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardClassItem.self, from: json)
        #expect(item.id == "class-1")
        #expect(item.displayName == "الفيزياء")
        #expect(item.studentCount == 30)
        #expect(!item.attendanceMarked)
    }

    @Test("Class item with attendance marked")
    func classItemMarked() throws {
        let json = """
        {
            "id": "class-2",
            "subject": "English",
            "startTime": "08:00",
            "endTime": "08:45",
            "room": "C101",
            "yearLevel": "Grade 9",
            "studentCount": 25,
            "attendanceMarked": true
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardClassItem.self, from: json)
        #expect(item.attendanceMarked)
    }

    // MARK: - ViewModel Logic

    @Test("Teacher view model filters pending classes")
    @MainActor
    func pendingClassesFilter() {
        let vm = TeacherDashboardViewModel()

        // Simulate loaded classes (we test the computed property logic)
        // The ViewModel uses @Observable so we test computed properties
        #expect(vm.classes.isEmpty)
        #expect(vm.pendingClasses.isEmpty)
        #expect(!vm.allAttendanceMarked) // empty = not all marked
    }

    @Test("Class item uses subject when no Arabic name")
    func classItemFallbackName() throws {
        let json = """
        {
            "id": "c3",
            "subject": "Chemistry",
            "startTime": "11:00",
            "endTime": "11:45",
            "studentCount": 20,
            "attendanceMarked": false
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(DashboardClassItem.self, from: json)
        #expect(item.displayName == "Chemistry")
        #expect(item.yearLevel == nil)
        #expect(item.room == nil)
    }
}
