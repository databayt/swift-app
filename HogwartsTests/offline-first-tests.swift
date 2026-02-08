import Foundation
import Testing
@testable import Hogwarts

/// Tests for offline-first type conversions and view states
@Suite("Offline First")
struct OfflineFirstTests {

    // MARK: - TimetableEntry ↔ TimetableModel Conversion

    @Test("TimetableModel initializes from TimetableEntry")
    func timetableModelFromEntry() {
        let entry = TimetableEntry(
            id: "tt_1",
            subjectName: "Mathematics",
            startTime: "08:00",
            endTime: "09:00",
            subjectNameAr: nil,
            teacherName: "Prof. McGonagall",
            classroomName: "Room 101",
            classId: nil,
            dayOfWeek: 1,
            periodNumber: 1
        )

        let model = TimetableModel(from: entry, schoolId: "school_1")
        #expect(model.id == "tt_1")
        #expect(model.subjectName == "Mathematics")
        #expect(model.teacherName == "Prof. McGonagall")
        #expect(model.classroomName == "Room 101")
        #expect(model.dayOfWeek == 1)
        #expect(model.schoolId == "school_1")
    }

    @Test("TimetableEntry initializes from TimetableModel")
    func timetableEntryFromModel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.date(from: "10:30")!
        let end = formatter.date(from: "11:30")!

        let model = TimetableModel(
            id: "tt_2",
            dayOfWeek: 3,
            startTime: start,
            endTime: end,
            schoolId: "school_1"
        )
        model.subjectName = "Potions"
        model.teacherName = "Prof. Snape"
        model.classroomName = "Dungeon"

        let entry = TimetableEntry(from: model)
        #expect(entry.id == "tt_2")
        #expect(entry.subjectName == "Potions")
        #expect(entry.teacherName == "Prof. Snape")
        #expect(entry.classroomName == "Dungeon")
        #expect(entry.dayOfWeek == 3)
        #expect(entry.startTime == "10:30")
        #expect(entry.endTime == "11:30")
    }

    @Test("TimetableModel update from entry changes fields")
    func timetableModelUpdate() {
        let model = TimetableModel(
            id: "tt_3",
            dayOfWeek: 0,
            startTime: Date(),
            endTime: Date(),
            schoolId: "school_1"
        )
        model.subjectName = "Old Subject"

        let entry = TimetableEntry(
            id: "tt_3",
            subjectName: "New Subject",
            startTime: "14:00",
            endTime: "15:00",
            subjectNameAr: nil,
            teacherName: "New Teacher",
            classroomName: "New Room",
            classId: nil,
            dayOfWeek: 2,
            periodNumber: nil
        )

        model.update(from: entry)
        #expect(model.subjectName == "New Subject")
        #expect(model.teacherName == "New Teacher")
        #expect(model.classroomName == "New Room")
        #expect(model.dayOfWeek == 2)
    }

    // MARK: - Conversation ↔ ConversationModel Conversion

    @Test("ConversationModel initializes from Conversation")
    func conversationModelFromConversation() {
        let now = Date()
        let conv = Conversation(
            id: "conv_1",
            name: "Study Group",
            isGroup: true,
            participants: [],
            lastMessage: nil,
            unreadCount: 5,
            createdAt: now,
            updatedAt: now
        )

        let model = ConversationModel(from: conv, schoolId: "school_1")
        #expect(model.id == "conv_1")
        #expect(model.name == "Study Group")
        #expect(model.isGroup == true)
        #expect(model.schoolId == "school_1")
    }

    @Test("Conversation initializes from ConversationModel")
    func conversationFromModel() {
        let model = ConversationModel(id: "conv_2", schoolId: "school_1")
        model.name = "Direct Chat"
        model.isGroup = false

        let conv = Conversation(from: model)
        #expect(conv.id == "conv_2")
        #expect(conv.name == "Direct Chat")
        #expect(conv.isGroup == false)
        #expect(conv.participants?.isEmpty ?? true)
        #expect(conv.lastMessage == nil)
        #expect(conv.unreadCount == 0)
    }

    @Test("ConversationModel update from conversation")
    func conversationModelUpdate() {
        let model = ConversationModel(id: "conv_3", schoolId: "school_1")
        model.name = "Old Name"

        let now = Date()
        let conv = Conversation(
            id: "conv_3",
            name: "Updated Name",
            isGroup: true,
            participants: nil,
            lastMessage: nil,
            unreadCount: 0,
            createdAt: now,
            updatedAt: now
        )

        model.update(from: conv)
        #expect(model.name == "Updated Name")
        #expect(model.isGroup == true)
    }

    // MARK: - AppNotification ↔ NotificationModel Conversion

    @Test("NotificationModel initializes from AppNotification")
    func notificationModelFromNotification() {
        let notif = AppNotification(
            id: "notif_1",
            userId: "user_1",
            type: "attendance",
            title: "Absent Today",
            message: "Student was marked absent",
            schoolId: "school_1",
            data: nil,
            isRead: false,
            createdAt: Date()
        )

        let model = NotificationModel(from: notif)
        #expect(model.id == "notif_1")
        #expect(model.userId == "user_1")
        #expect(model.type == "attendance")
        #expect(model.title == "Absent Today")
        #expect(model.message == "Student was marked absent")
        #expect(model.schoolId == "school_1")
        #expect(model.isRead == false)
    }

    @Test("AppNotification initializes from NotificationModel")
    func notificationFromModel() {
        let model = NotificationModel(
            id: "notif_2",
            userId: "user_2",
            type: "grade",
            title: "New Grade",
            message: "You received an A+",
            schoolId: "school_1"
        )
        model.isRead = true

        let notif = AppNotification(from: model)
        #expect(notif.id == "notif_2")
        #expect(notif.userId == "user_2")
        #expect(notif.type == "grade")
        #expect(notif.title == "New Grade")
        #expect(notif.message == "You received an A+")
        #expect(notif.isRead == true)
    }

    @Test("NotificationModel update from notification")
    func notificationModelUpdate() {
        let model = NotificationModel(
            id: "notif_3",
            userId: "user_3",
            type: "message",
            title: "Original Title",
            message: "Original Message",
            schoolId: "school_1"
        )

        let notif = AppNotification(
            id: "notif_3",
            userId: "user_3",
            type: "message",
            title: "Updated Title",
            message: "Updated Message",
            schoolId: "school_1",
            data: nil,
            isRead: true,
            createdAt: Date()
        )

        model.update(from: notif)
        #expect(model.title == "Updated Title")
        #expect(model.message == "Updated Message")
        #expect(model.isRead == true)
    }

    @Test("NotificationModel handles data string conversion")
    func notificationModelDataConversion() {
        let notif = AppNotification(
            id: "notif_4",
            userId: "user_4",
            type: "system",
            title: "System",
            message: "Update",
            schoolId: "school_1",
            data: "{\"key\":\"value\"}",
            isRead: false,
            createdAt: Date()
        )

        let model = NotificationModel(from: notif)
        #expect(model.data != nil)

        let restored = AppNotification(from: model)
        #expect(restored.data == "{\"key\":\"value\"}")
    }

    // MARK: - TimetableViewState

    @Test("TimetableViewState loading isLoading is true")
    func timetableViewStateLoading() {
        let state = TimetableViewState.loading
        #expect(state.isLoading)
    }

    @Test("TimetableViewState idle returns empty entries")
    func timetableViewStateIdle() {
        let state = TimetableViewState.idle
        #expect(state.entries.isEmpty)
        #expect(!state.isLoading)
    }

    @Test("TimetableViewState loaded returns entries")
    func timetableViewStateLoaded() {
        let entries = [
            TimetableEntry(
                id: "tt_1",
                subjectName: "Math",
                startTime: "08:00",
                endTime: "09:00",
                subjectNameAr: nil,
                teacherName: nil,
                classroomName: nil,
                classId: nil,
                dayOfWeek: 1,
                periodNumber: 1
            )
        ]
        let response = WeeklyScheduleResponse(entries: entries, termName: "Term 1", className: nil)
        let state = TimetableViewState.loaded(response)
        #expect(state.entries.count == 1)
        #expect(!state.isLoading)
    }

    // MARK: - MessagesViewState

    @Test("MessagesViewState loading isLoading is true")
    func messagesViewStateLoading() {
        let state = MessagesViewState.loading
        #expect(state.isLoading)
    }

    @Test("MessagesViewState idle returns empty conversations")
    func messagesViewStateIdle() {
        let state = MessagesViewState.idle
        #expect(state.conversations.isEmpty)
    }

    // MARK: - NotificationsViewState

    @Test("NotificationsViewState loading isLoading is true")
    func notificationsViewStateLoading() {
        let state = NotificationsViewState.loading
        #expect(state.isLoading)
    }

    @Test("NotificationsViewState idle returns empty notifications")
    func notificationsViewStateIdle() {
        let state = NotificationsViewState.idle
        #expect(state.notifications.isEmpty)
    }
}
