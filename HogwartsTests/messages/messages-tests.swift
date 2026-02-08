import Foundation
import Testing
@testable import Hogwarts

/// Tests for Messages feature types, validation, and capabilities
@Suite("Messages")
struct MessagesTests {

    // MARK: - Conversation computed properties

    @Test("Conversation displayName returns name when set")
    func conversationDisplayNameWithName() {
        let conv = Conversation(
            id: "conv_1", name: "Study Group",
            isGroup: true, participants: nil,
            lastMessage: nil, unreadCount: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(conv.displayName == "Study Group")
    }

    @Test("Conversation displayName returns first participant name when name is nil")
    func conversationDisplayNameWithParticipant() {
        let participant = ConversationParticipant(
            id: "p_1", userId: "u_1", name: "Hermione",
            nameAr: nil, imageUrl: nil, role: nil
        )
        let conv = Conversation(
            id: "conv_1", name: nil,
            isGroup: false, participants: [participant],
            lastMessage: nil, unreadCount: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(conv.displayName == "Hermione")
    }

    @Test("Conversation hasUnread returns true when unreadCount > 0")
    func conversationHasUnread() {
        let conv = Conversation(
            id: "conv_1", name: "Chat",
            isGroup: false, participants: nil,
            lastMessage: nil, unreadCount: 5,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(conv.hasUnread)
    }

    @Test("Conversation hasUnread returns false when unreadCount is 0")
    func conversationNoUnread() {
        let conv = Conversation(
            id: "conv_1", name: "Chat",
            isGroup: false, participants: nil,
            lastMessage: nil, unreadCount: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(!conv.hasUnread)
    }

    @Test("Conversation lastMessagePreview returns content from lastMessage")
    func conversationLastMessagePreview() {
        let preview = MessagePreview(
            id: "msg_1", content: "Hello there!",
            senderName: "Ron", createdAt: Date()
        )
        let conv = Conversation(
            id: "conv_1", name: "Chat",
            isGroup: false, participants: nil,
            lastMessage: preview, unreadCount: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(conv.lastMessagePreview == "Hello there!")
    }

    @Test("Conversation lastMessagePreview returns empty when no lastMessage")
    func conversationNoLastMessage() {
        let conv = Conversation(
            id: "conv_1", name: "Chat",
            isGroup: false, participants: nil,
            lastMessage: nil, unreadCount: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(conv.lastMessagePreview == "")
    }

    // MARK: - Message computed properties

    @Test("Message isRead returns true when readAt is set")
    func messageIsRead() {
        let msg = Message(
            id: "msg_1", conversationId: "conv_1",
            senderId: "u_1", senderName: "Harry",
            content: "Hello", senderImageUrl: nil,
            createdAt: Date(), readAt: Date()
        )
        #expect(msg.isRead)
    }

    @Test("Message isRead returns false when readAt is nil")
    func messageIsNotRead() {
        let msg = Message(
            id: "msg_1", conversationId: "conv_1",
            senderId: "u_1", senderName: "Harry",
            content: "Hello", senderImageUrl: nil,
            createdAt: Date(), readAt: nil
        )
        #expect(!msg.isRead)
    }

    // MARK: - ConversationParticipant

    @Test("ConversationParticipant displayName returns nameAr when available")
    func participantDisplayNameAr() {
        let participant = ConversationParticipant(
            id: "p_1", userId: "u_1", name: "Hermione",
            nameAr: "هيرميوني", imageUrl: nil, role: nil
        )
        #expect(participant.displayName == "هيرميوني")
    }

    @Test("ConversationParticipant displayName falls back to name")
    func participantDisplayNameFallback() {
        let participant = ConversationParticipant(
            id: "p_1", userId: "u_1", name: "Hermione",
            nameAr: nil, imageUrl: nil, role: nil
        )
        #expect(participant.displayName == "Hermione")
    }

    // MARK: - Recipient

    @Test("Recipient equality based on id")
    func recipientEquality() {
        let r1 = Recipient(id: "r_1", name: "Ron", nameAr: nil, email: nil, role: nil, imageUrl: nil)
        let r2 = Recipient(id: "r_1", name: "Ronald", nameAr: nil, email: nil, role: nil, imageUrl: nil)
        #expect(r1 == r2)
    }

    @Test("Recipient inequality for different ids")
    func recipientInequality() {
        let r1 = Recipient(id: "r_1", name: "Ron", nameAr: nil, email: nil, role: nil, imageUrl: nil)
        let r2 = Recipient(id: "r_2", name: "Ron", nameAr: nil, email: nil, role: nil, imageUrl: nil)
        #expect(r1 != r2)
    }

    @Test("Recipient displayName returns nameAr when available")
    func recipientDisplayNameAr() {
        let r = Recipient(id: "r_1", name: "Ron", nameAr: "رون", email: nil, role: nil, imageUrl: nil)
        #expect(r.displayName == "رون")
    }

    // MARK: - MessagesValidation

    @Test("Validate message rejects empty content")
    func validateMessageEmpty() {
        let result = MessagesValidation.validateMessage("")
        #expect(!result.isValid)
    }

    @Test("Validate message rejects whitespace-only content")
    func validateMessageWhitespace() {
        let result = MessagesValidation.validateMessage("   \n  ")
        #expect(!result.isValid)
    }

    @Test("Validate message accepts valid content")
    func validateMessageValid() {
        let result = MessagesValidation.validateMessage("Hello, how are you?")
        #expect(result.isValid)
    }

    @Test("Validate message rejects content over 5000 chars")
    func validateMessageTooLong() {
        let longMessage = String(repeating: "a", count: 5001)
        let result = MessagesValidation.validateMessage(longMessage)
        #expect(!result.isValid)
    }

    @Test("Validate new conversation rejects empty recipients")
    func validateConversationNoRecipients() {
        let result = MessagesValidation.validateNewConversation(
            recipientIds: [],
            initialMessage: nil,
            name: nil
        )
        #expect(!result.isValid)
        #expect(result.errors["recipients"] != nil)
    }

    // MARK: - MessagingCapabilities

    @Test("Admin messaging capabilities allow all")
    func adminMessagingCapabilities() {
        let caps = MessagingCapabilities.forRole(.admin)
        #expect(caps.canSendMessages)
        #expect(caps.canCreateConversations)
        #expect(caps.canCreateGroupChats)
        #expect(caps.canMessageAllRoles)
    }

    @Test("Student messaging capabilities restrict group chats")
    func studentMessagingCapabilities() {
        let caps = MessagingCapabilities.forRole(.student)
        #expect(caps.canSendMessages)
        #expect(caps.canCreateConversations)
        #expect(!caps.canCreateGroupChats)
        #expect(!caps.canMessageAllRoles)
    }

    @Test("Accountant messaging capabilities deny all")
    func accountantMessagingCapabilities() {
        let caps = MessagingCapabilities.forRole(.accountant)
        #expect(!caps.canSendMessages)
        #expect(!caps.canCreateConversations)
        #expect(!caps.canCreateGroupChats)
        #expect(!caps.canMessageAllRoles)
    }

    // MARK: - MessagesViewState

    @Test("MessagesViewState loading isLoading is true")
    func viewStateLoading() {
        let state = MessagesViewState.loading
        #expect(state.isLoading)
    }

    @Test("MessagesViewState idle returns empty conversations")
    func viewStateIdleConversations() {
        let state = MessagesViewState.idle
        #expect(state.conversations.isEmpty)
    }
}
