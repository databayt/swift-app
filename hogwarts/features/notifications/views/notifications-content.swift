import SwiftUI

/// Main notifications view — grouped list with filters
/// Mirrors: src/components/platform/notifications/content.tsx
struct NotificationsContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        NotificationFilterChip(
                            filter: .all,
                            isSelected: viewModel.activeFilter == .all
                        ) {
                            viewModel.setFilter(.all)
                        }

                        NotificationFilterChip(
                            filter: .unread,
                            isSelected: viewModel.activeFilter == .unread,
                            badge: viewModel.unreadCount
                        ) {
                            viewModel.setFilter(.unread)
                        }

                        ForEach(NotificationType.allCases, id: \.self) { type in
                            NotificationFilterChip(
                                filter: .type(type),
                                isSelected: viewModel.activeFilter == .type(type)
                            ) {
                                viewModel.setFilter(.type(type))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                // Content
                Group {
                    switch viewModel.viewState {
                    case .idle, .loading:
                        LoadingView()

                    case .loaded:
                        if viewModel.notifications.isEmpty {
                            EmptyStateView(
                                title: String(localized: "notification.empty.filtered.title"),
                                message: String(localized: "notification.empty.filtered.message"),
                                systemImage: "bell.slash"
                            )
                        } else {
                            List {
                                ForEach(viewModel.groupedNotifications) { group in
                                    Section(group.title) {
                                        ForEach(group.notifications) { notification in
                                            NotificationRow(notification: notification)
                                                .onTapGesture {
                                                    Task {
                                                        await viewModel.markAsRead(notification)
                                                    }
                                                }
                                                .swipeActions(edge: .trailing) {
                                                    Button(role: .destructive) {
                                                        Task {
                                                            await viewModel.deleteNotification(notification)
                                                        }
                                                    } label: {
                                                        Label(
                                                            String(localized: "common.delete"),
                                                            systemImage: "trash"
                                                        )
                                                    }

                                                    if !notification.isRead {
                                                        Button {
                                                            Task {
                                                                await viewModel.markAsRead(notification)
                                                            }
                                                        } label: {
                                                            Label(
                                                                String(localized: "notification.markRead"),
                                                                systemImage: "envelope.open"
                                                            )
                                                        }
                                                        .tint(.blue)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                await viewModel.refresh()
                            }
                        }

                    case .empty:
                        EmptyStateView(
                            title: String(localized: "notification.empty.title"),
                            message: String(localized: "notification.empty.message"),
                            systemImage: "bell"
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
            }
            .navigationTitle(String(localized: "notification.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        Button {
                            Task { await viewModel.markAllAsRead() }
                        } label: {
                            Image(systemName: "envelope.open")
                        }
                    }
                }
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
            .alert(
                String(localized: "success.title"),
                isPresented: $viewModel.showSuccess
            ) {
                Button(String(localized: "common.ok")) {}
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .task {
                viewModel.setup(tenantContext: tenantContext, authManager: authManager)
                await viewModel.loadNotifications()
            }
        }
    }
}

// MARK: - Filter Chip

struct NotificationFilterChip: View {
    let filter: NotificationFilter
    let isSelected: Bool
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(filter.label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)

                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.red)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotificationsContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
