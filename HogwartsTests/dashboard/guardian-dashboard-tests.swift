import Foundation
import Testing
@testable import Hogwarts

/// Tests for Guardian Dashboard (DASH-003)
@Suite("Guardian Dashboard")
struct GuardianDashboardTests {

    // MARK: - Child Model

    @Test("Child decodes from JSON")
    func childDecode() throws {
        let json = """
        {
            "id": "child-1",
            "name": "Ahmad Ali",
            "nameAr": "أحمد علي",
            "imageUrl": "https://example.com/photo.jpg",
            "yearLevel": "Grade 5"
        }
        """.data(using: .utf8)!

        let child = try JSONDecoder().decode(DashboardChild.self, from: json)
        #expect(child.id == "child-1")
        #expect(child.displayName == "أحمد علي")
        #expect(child.yearLevel == "Grade 5")
    }

    @Test("Child uses name when no Arabic name")
    func childFallbackName() throws {
        let json = """
        {
            "id": "child-2",
            "name": "Sara Ahmed"
        }
        """.data(using: .utf8)!

        let child = try JSONDecoder().decode(DashboardChild.self, from: json)
        #expect(child.displayName == "Sara Ahmed")
        #expect(child.nameAr == nil)
        #expect(child.imageUrl == nil)
    }

    // MARK: - Message Preview

    @Test("Message preview decodes from JSON")
    func messagePreviewDecode() throws {
        let json = """
        {
            "id": "msg-1",
            "senderName": "Mr. Smith",
            "subject": "Math homework",
            "preview": "Please complete exercises 1-5...",
            "date": "2026-02-08",
            "isRead": false
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(DashboardMessagePreview.self, from: json)
        #expect(message.id == "msg-1")
        #expect(message.senderName == "Mr. Smith")
        #expect(!message.isRead)
    }

    @Test("Read message decodes correctly")
    func readMessageDecode() throws {
        let json = """
        {
            "id": "msg-2",
            "senderName": "Ms. Johnson",
            "subject": "Field trip",
            "preview": "Permission slip attached",
            "date": "2026-02-07",
            "isRead": true
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(DashboardMessagePreview.self, from: json)
        #expect(message.isRead)
    }

    // MARK: - ViewModel

    @Test("Guardian view model initial state")
    @MainActor
    func initialState() {
        let vm = GuardianDashboardViewModel()
        #expect(vm.children.isEmpty)
        #expect(vm.selectedChild == nil)
        #expect(vm.schedule.isEmpty)
        #expect(vm.grades.isEmpty)
        #expect(vm.attendance == nil)
        #expect(vm.messages.isEmpty)
        #expect(!vm.isLoading)
    }

    // MARK: - Children List Decoding

    @Test("Multiple children decode as array")
    func multipleChildrenDecode() throws {
        let json = """
        [
            {"id": "c1", "name": "Child One"},
            {"id": "c2", "name": "Child Two", "nameAr": "الطفل الثاني"}
        ]
        """.data(using: .utf8)!

        let children = try JSONDecoder().decode([DashboardChild].self, from: json)
        #expect(children.count == 2)
        #expect(children[0].displayName == "Child One")
        #expect(children[1].displayName == "الطفل الثاني")
    }
}
