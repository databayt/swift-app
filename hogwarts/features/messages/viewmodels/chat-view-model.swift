import SwiftUI

/// ViewModel for Chat (message thread) view
/// Handles message loading, pagination, sending, and optimistic updates
@Observable
@MainActor
final class ChatViewModel {
    // Dependencies
    private let actions = MessagesActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var chatState: ChatViewState = .idle
    var conversation: Conversation?
    var messageText = ""
    var isSending = false

    // Pagination
    var currentPage = 1
    var totalPages = 1
    var hasMore: Bool { currentPage < totalPages }

    // Error handling
    var error: Error?
    var showError = false

    // Success feedback
    var successMessage: String?
    var showSuccess = false

    // MARK: - Computed Properties

    var messages: [Message] {
        chatState.messages
    }

    var isLoading: Bool {
        chatState.isLoading
    }

    var currentUserId: String? {
        authManager?.currentUser?.id
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    // MARK: - Setup

    func setup(
        conversation: Conversation,
        tenantContext: TenantContext,
        authManager: AuthManager
    ) {
        self.conversation = conversation
        self.tenantContext = tenantContext
        self.authManager = authManager
    }

    // MARK: - Load Actions

    /// Load messages for the conversation
    func loadMessages() async {
        guard let schoolId = tenantContext?.schoolId,
              let conversationId = conversation?.id else {
            chatState = .error(APIError.unauthorized)
            return
        }

        chatState = .loading

        do {
            let response = try await actions.getMessages(
                conversationId: conversationId,
                schoolId: schoolId,
                page: 1
            )

            currentPage = response.page
            totalPages = response.totalPages

            if response.data.isEmpty {
                chatState = .empty
            } else {
                chatState = .loaded(response.data)
            }

            // Mark latest messages as read
            if let lastMessage = response.data.first, lastMessage.readAt == nil {
                try? await actions.markAsRead(
                    messageId: lastMessage.id,
                    schoolId: schoolId
                )
            }
        } catch {
            chatState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Load more (older) messages
    func loadMore() async {
        guard hasMore,
              let schoolId = tenantContext?.schoolId,
              let conversationId = conversation?.id else { return }

        do {
            let response = try await actions.getMessages(
                conversationId: conversationId,
                schoolId: schoolId,
                page: currentPage + 1
            )

            currentPage = response.page
            totalPages = response.totalPages

            // Append older messages
            var existing = messages
            existing.append(contentsOf: response.data)
            chatState = .loaded(existing)
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Send Actions

    /// Send a message
    func sendMessage() async {
        guard let schoolId = tenantContext?.schoolId,
              let conversationId = conversation?.id else { return }

        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate
        let validation = MessagesValidation.validateMessage(content)
        guard validation.isValid else {
            error = MessagesError.validationFailed(validation.errors)
            showError = true
            return
        }

        isSending = true
        let sentText = content
        messageText = ""

        do {
            let message = try await actions.sendMessageOffline(
                conversationId: conversationId,
                content: sentText,
                schoolId: schoolId
            )

            if let message {
                // Online: prepend sent message
                var existing = messages
                existing.insert(message, at: 0)
                chatState = .loaded(existing)
            } else {
                // Offline: create optimistic message
                let optimistic = Message(
                    id: UUID().uuidString,
                    conversationId: conversationId,
                    senderId: authManager?.currentUser?.id ?? "",
                    senderName: authManager?.currentUser?.displayName ?? "",
                    content: sentText,
                    senderImageUrl: authManager?.currentUser?.imageUrl,
                    createdAt: Date(),
                    readAt: nil
                )
                var existing = messages
                existing.insert(optimistic, at: 0)
                chatState = .loaded(existing)
            }
        } catch {
            // Restore message text on failure
            messageText = sentText
            self.error = error
            showError = true
        }

        isSending = false
    }

    /// Refresh messages
    func refresh() async {
        currentPage = 1
        await loadMessages()
    }
}
