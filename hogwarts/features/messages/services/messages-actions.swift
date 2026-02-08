import Foundation

/// Server actions for Messages feature
/// Mirrors: src/components/platform/messages/actions.ts
///
/// CRITICAL: All actions must include schoolId for multi-tenant isolation
final class MessagesActions: Sendable {

    private let api = APIClient.shared
    private let syncEngine = SyncEngine.shared

    // MARK: - Read Actions

    /// Get conversations list
    /// GET /conversations?schoolId=X
    func getConversations(schoolId: String) async throws -> [Conversation] {
        try await api.get(
            "/conversations",
            query: ["schoolId": schoolId],
            as: [Conversation].self
        )
    }

    /// Get messages in a conversation (paginated)
    /// GET /conversations/{id}/messages?schoolId=X&page=N
    func getMessages(
        conversationId: String,
        schoolId: String,
        page: Int = 1
    ) async throws -> MessagesResponse {
        try await api.get(
            "/conversations/\(conversationId)/messages",
            query: [
                "schoolId": schoolId,
                "page": String(page)
            ],
            as: MessagesResponse.self
        )
    }

    // MARK: - Write Actions

    /// Send a message
    /// POST /messages
    func sendMessage(
        conversationId: String,
        content: String,
        schoolId: String
    ) async throws -> Message {
        let request = SendMessageRequest(
            conversationId: conversationId,
            content: content,
            schoolId: schoolId
        )
        return try await api.post("/messages", body: request, as: Message.self)
    }

    /// Create a new conversation
    /// POST /conversations
    func createConversation(
        participantIds: [String],
        name: String? = nil,
        isGroup: Bool = false,
        initialMessage: String? = nil,
        schoolId: String
    ) async throws -> Conversation {
        let request = CreateConversationRequest(
            participantIds: participantIds,
            name: name,
            isGroup: isGroup,
            initialMessage: initialMessage,
            schoolId: schoolId
        )
        return try await api.post("/conversations", body: request, as: Conversation.self)
    }

    /// Mark message as read
    /// PUT /messages/{id}/read
    func markAsRead(
        messageId: String,
        schoolId: String
    ) async throws {
        let request = MarkReadRequest(schoolId: schoolId)
        let _: EmptyResponse = try await api.put(
            "/messages/\(messageId)/read",
            body: request
        )
    }

    /// Get available recipients for new conversation
    /// GET /users?schoolId=X&role=Y
    func getRecipients(
        schoolId: String,
        role: String? = nil,
        search: String? = nil
    ) async throws -> [Recipient] {
        var params: [String: String] = ["schoolId": schoolId]

        if let role {
            params["role"] = role
        }
        if let search, !search.isEmpty {
            params["search"] = search
        }

        return try await api.get("/users", query: params, as: [Recipient].self)
    }

    // MARK: - Offline Actions

    /// Send message (offline-capable)
    @MainActor
    func sendMessageOffline(
        conversationId: String,
        content: String,
        schoolId: String
    ) async throws -> Message? {
        if NetworkMonitor.shared.isConnected {
            return try await sendMessage(
                conversationId: conversationId,
                content: content,
                schoolId: schoolId
            )
        }

        // Queue for later
        let request = SendMessageRequest(
            conversationId: conversationId,
            content: content,
            schoolId: schoolId
        )
        let payload = try JSONEncoder().encode(request)
        await syncEngine.queueAction(
            endpoint: "/messages",
            method: .post,
            payload: payload
        )

        return nil
    }
}

// MARK: - Errors

enum MessagesError: LocalizedError {
    case validationFailed([String: String])
    case conversationNotFound
    case unauthorized
    case sendFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return errors.values.joined(separator: ", ")
        case .conversationNotFound:
            return String(localized: "messages.error.notFound")
        case .unauthorized:
            return String(localized: "error.unauthorized")
        case .sendFailed:
            return String(localized: "messages.error.sendFailed")
        case .serverError(let message):
            return message
        }
    }
}
