import SwiftUI

/// Chat interface — message bubbles with input bar
/// Mirrors: src/components/platform/messages/chat-view.tsx
struct ChatView: View {
    let conversation: Conversation

    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            Group {
                switch viewModel.chatState {
                case .idle, .loading:
                    LoadingView()

                case .loaded:
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                // Load more button
                                if viewModel.hasMore {
                                    Button {
                                        Task { await viewModel.loadMore() }
                                    } label: {
                                        Text(String(localized: "messages.loadMore"))
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.vertical, 8)
                                }

                                // Messages (reversed — newest at bottom)
                                ForEach(viewModel.messages.reversed()) { message in
                                    MessageBubble(
                                        message: message,
                                        isOutgoing: message.senderId == viewModel.currentUserId
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            // Scroll to latest message
                            if let lastId = viewModel.messages.first?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                case .empty:
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(String(localized: "messages.startConversation"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: {
                            Task { await viewModel.refresh() }
                        }
                    )
                }
            }

            Divider()

            // Input bar
            MessageInputBar(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                canSend: viewModel.canSend
            ) {
                Task { await viewModel.sendMessage() }
            }
        }
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            String(localized: "error.title"),
            isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button(String(localized: "common.ok")) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            viewModel.setup(
                conversation: conversation,
                tenantContext: tenantContext,
                authManager: authManager
            )
            await viewModel.loadMessages()
        }
    }
}

// MARK: - Message Input Bar

struct MessageInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField(
                String(localized: "messages.placeholder"),
                text: $text,
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(String(localized: "a11y.field.messageInput"))
            .accessibilityHint(String(localized: "a11y.hint.typeYourMessage"))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .disabled(!canSend)
            .tint(.blue)
            .accessibilityLabel(String(localized: "a11y.button.sendMessage"))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
