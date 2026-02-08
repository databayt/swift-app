import SwiftUI

/// Type definitions for Messages feature
/// Mirrors: src/components/platform/messages/types.ts

// MARK: - API Response Types

/// Conversation list item
struct Conversation: Codable, Identifiable {
    let id: String
    let name: String?
    let isGroup: Bool
    let participants: [ConversationParticipant]?
    let lastMessage: MessagePreview?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date

    var displayName: String {
        if let name, !name.isEmpty { return name }
        // For 1:1 conversations, show the other participant's name
        return participants?.first?.name ?? String(localized: "messages.unknownUser")
    }

    var lastMessagePreview: String {
        lastMessage?.content ?? ""
    }

    var hasUnread: Bool {
        unreadCount > 0
    }
}

/// Participant in a conversation
struct ConversationParticipant: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let nameAr: String?
    let imageUrl: String?
    let role: String?

    var displayName: String {
        nameAr ?? name
    }
}

/// Message preview (embedded in conversation)
struct MessagePreview: Codable {
    let id: String
    let content: String
    let senderName: String
    let createdAt: Date
}

/// Full message
struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let content: String
    let senderImageUrl: String?
    let createdAt: Date
    let readAt: Date?

    var isRead: Bool {
        readAt != nil
    }
}

/// Paginated messages response
struct MessagesResponse: Codable {
    let data: [Message]
    let total: Int
    let page: Int
    let totalPages: Int
}

/// Conversations list response
struct ConversationsResponse: Codable {
    let data: [Conversation]
    let total: Int
}

/// Recipient for new conversation
struct Recipient: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameAr: String?
    let email: String?
    let role: String?
    let imageUrl: String?

    var displayName: String {
        nameAr ?? name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recipient, rhs: Recipient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Request Types

/// Send message request
struct SendMessageRequest: Encodable {
    let conversationId: String
    let content: String
    let schoolId: String
}

/// Create conversation request
struct CreateConversationRequest: Encodable {
    let participantIds: [String]
    let name: String?
    let isGroup: Bool
    let initialMessage: String?
    let schoolId: String
}

/// Mark message as read request
struct MarkReadRequest: Encodable {
    let schoolId: String
}

// MARK: - View State

/// Messages list view state
enum MessagesViewState {
    case idle
    case loading
    case loaded([Conversation])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var conversations: [Conversation] {
        if case .loaded(let list) = self { return list }
        return []
    }
}

/// Chat view state
enum ChatViewState {
    case idle
    case loading
    case loaded([Message])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var messages: [Message] {
        if case .loaded(let list) = self { return list }
        return []
    }
}

// MARK: - Role-Based Capabilities

/// Role-specific messaging capabilities
struct MessagingCapabilities {
    let canSendMessages: Bool
    let canCreateConversations: Bool
    let canCreateGroupChats: Bool
    let canMessageAllRoles: Bool

    static func forRole(_ role: UserRole) -> MessagingCapabilities {
        switch role {
        case .developer, .admin:
            return MessagingCapabilities(
                canSendMessages: true,
                canCreateConversations: true,
                canCreateGroupChats: true,
                canMessageAllRoles: true
            )
        case .teacher, .staff:
            return MessagingCapabilities(
                canSendMessages: true,
                canCreateConversations: true,
                canCreateGroupChats: true,
                canMessageAllRoles: true
            )
        case .student:
            return MessagingCapabilities(
                canSendMessages: true,
                canCreateConversations: true,
                canCreateGroupChats: false,
                canMessageAllRoles: false
            )
        case .guardian:
            return MessagingCapabilities(
                canSendMessages: true,
                canCreateConversations: true,
                canCreateGroupChats: false,
                canMessageAllRoles: false
            )
        case .accountant, .user:
            return MessagingCapabilities(
                canSendMessages: false,
                canCreateConversations: false,
                canCreateGroupChats: false,
                canMessageAllRoles: false
            )
        }
    }
}
