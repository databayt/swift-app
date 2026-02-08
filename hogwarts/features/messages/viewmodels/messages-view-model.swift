import SwiftUI

/// ViewModel for Messages conversation list
/// Mirrors: Logic from messages/content.tsx
@Observable
@MainActor
final class MessagesViewModel {
    // Dependencies
    private let actions = MessagesActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var viewState: MessagesViewState = .idle
    var searchText = ""
    var isShowingCompose = false

    // Error handling
    var error: Error?
    var showError = false

    // MARK: - Computed Properties

    var conversations: [Conversation] {
        let all = viewState.conversations
        if searchText.isEmpty { return all }
        return all.filter { conversation in
            conversation.displayName.localizedCaseInsensitiveContains(searchText) ||
            conversation.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
        }
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var unreadCount: Int {
        viewState.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var capabilities: MessagingCapabilities {
        guard let role = authManager?.role else {
            return MessagingCapabilities.forRole(.user)
        }
        return MessagingCapabilities.forRole(role)
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext, authManager: AuthManager) {
        self.tenantContext = tenantContext
        self.authManager = authManager
    }

    // MARK: - Load Actions

    /// Load conversations list
    func loadConversations() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(APIError.unauthorized)
            return
        }

        viewState = .loading

        do {
            let conversations = try await actions.getConversations(schoolId: schoolId)

            if conversations.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(conversations)
            }
        } catch {
            viewState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Refresh conversations
    func refresh() async {
        await loadConversations()
    }

    /// Show compose view
    func showCompose() {
        isShowingCompose = true
    }

    /// Handle conversation created from compose
    func onConversationCreated(_ conversation: Conversation) {
        isShowingCompose = false
        // Reload to get updated list
        Task { await loadConversations() }
    }
}
