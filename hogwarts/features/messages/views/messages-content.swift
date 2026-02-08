import SwiftUI

/// Main messages view — conversation list with search
/// Mirrors: src/components/platform/messages/content.tsx
struct MessagesContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = MessagesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    LoadingView()

                case .loaded:
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink {
                                ChatView(
                                    conversation: conversation
                                )
                            } label: {
                                ConversationRow(conversation: conversation)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .searchable(
                        text: $viewModel.searchText,
                        prompt: String(localized: "messages.search")
                    )

                case .empty:
                    EmptyStateView(
                        title: String(localized: "messages.empty.title"),
                        message: String(localized: "messages.empty.message"),
                        systemImage: "bubble.left.and.bubble.right",
                        action: {
                            viewModel.showCompose()
                        },
                        actionTitle: String(localized: "messages.action.newMessage")
                    )

                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: {
                            Task { await viewModel.refresh() }
                        }
                    )
                }
            }
            .navigationTitle(String(localized: "messages.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.capabilities.canCreateConversations {
                        Button {
                            viewModel.showCompose()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingCompose) {
                ComposeMessageView(
                    onConversationCreated: { conversation in
                        viewModel.onConversationCreated(conversation)
                    }
                )
            }
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
                viewModel.setup(tenantContext: tenantContext, authManager: authManager)
                await viewModel.loadConversations()
            }
        }
    }
}

#Preview {
    MessagesContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
