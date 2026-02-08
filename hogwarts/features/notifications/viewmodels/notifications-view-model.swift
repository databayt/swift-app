import SwiftUI
import SwiftData

/// ViewModel for Notifications feature
/// Mirrors: Logic from notifications/content.tsx
@Observable
@MainActor
final class NotificationsViewModel {
    // Dependencies
    private let actions = NotificationsActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var viewState: NotificationsViewState = .idle
    var activeFilter: NotificationFilter = .all

    // Error handling
    var error: Error?
    var showError = false

    // Success feedback
    var successMessage: String?
    var showSuccess = false

    // Push notification observer
    nonisolated(unsafe) private var notificationObserver: NSObjectProtocol?

    // MARK: - Computed Properties

    var notifications: [AppNotification] {
        let all = viewState.notifications

        switch activeFilter {
        case .all:
            return all
        case .unread:
            return all.filter { !$0.isRead }
        case .type(let type):
            return all.filter { $0.notificationType == type }
        }
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var unreadCount: Int {
        viewState.notifications.filter { !$0.isRead }.count
    }

    /// Notifications grouped by date
    var groupedNotifications: [NotificationGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notifications) { notification in
            calendar.startOfDay(for: notification.createdAt)
        }

        return grouped
            .map { NotificationGroup(date: $0.key, notifications: $0.value) }
            .sorted { group1, group2 in
                guard let date1 = group1.notifications.first?.createdAt,
                      let date2 = group2.notifications.first?.createdAt else {
                    return false
                }
                return date1 > date2
            }
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext, authManager: AuthManager) {
        self.tenantContext = tenantContext
        self.authManager = authManager
        observePushNotifications()
    }

    // MARK: - Load Actions

    /// Load notifications (offline-first)
    func loadNotifications() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(APIError.unauthorized)
            return
        }

        viewState = .loading

        do {
            let notifications = try await actions.getNotifications(schoolId: schoolId)

            if notifications.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(notifications)
            }

            // Cache to SwiftData
            cacheNotifications(notifications, schoolId: schoolId)
        } catch {
            // Offline fallback: read from SwiftData
            let cached = loadCachedNotifications(schoolId: schoolId)
            if !cached.isEmpty {
                viewState = .loaded(cached)
            } else {
                viewState = .error(error)
                self.error = error
                showError = true
            }
        }
    }

    /// Refresh notifications
    func refresh() async {
        await loadNotifications()
    }

    // MARK: - Actions

    /// Mark a notification as read
    func markAsRead(_ notification: AppNotification) async {
        guard let schoolId = tenantContext?.schoolId else { return }
        guard !notification.isRead else { return }

        do {
            try await actions.markAsRead(
                notificationId: notification.id,
                schoolId: schoolId
            )

            // Update local state
            if case .loaded(var list) = viewState {
                if let index = list.firstIndex(where: { $0.id == notification.id }) {
                    // Re-create with isRead = true
                    let updated = AppNotification(
                        id: list[index].id,
                        userId: list[index].userId,
                        type: list[index].type,
                        title: list[index].title,
                        message: list[index].message,
                        schoolId: list[index].schoolId,
                        data: list[index].data,
                        isRead: true,
                        createdAt: list[index].createdAt
                    )
                    list[index] = updated
                    viewState = .loaded(list)
                }
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() async {
        guard let schoolId = tenantContext?.schoolId else { return }

        do {
            try await actions.markAllAsRead(schoolId: schoolId)
            successMessage = String(localized: "notification.success.allRead")
            showSuccess = true
            await loadNotifications()
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Delete a notification
    func deleteNotification(_ notification: AppNotification) async {
        guard let schoolId = tenantContext?.schoolId else { return }

        do {
            try await actions.deleteNotification(
                notificationId: notification.id,
                schoolId: schoolId
            )

            // Remove from local state
            if case .loaded(var list) = viewState {
                list.removeAll { $0.id == notification.id }
                viewState = list.isEmpty ? .empty : .loaded(list)
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Set active filter
    func setFilter(_ filter: NotificationFilter) {
        activeFilter = filter
    }

    // MARK: - Push Notification Observer

    private func observePushNotifications() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .didReceiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.loadNotifications()
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - SwiftData Cache

    /// Cache notifications to SwiftData
    private func cacheNotifications(_ notifications: [AppNotification], schoolId: String) {
        let context = DataContainer.shared.modelContext
        for notif in notifications {
            let notifId = notif.id
            let descriptor = FetchDescriptor<NotificationModel>(
                predicate: #Predicate { $0.id == notifId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: notif)
                existing.lastSyncedAt = Date()
            } else {
                let model = NotificationModel(from: notif)
                model.lastSyncedAt = Date()
                context.insert(model)
            }
        }
        try? context.save()
    }

    /// Load cached notifications from SwiftData
    private func loadCachedNotifications(schoolId: String) -> [AppNotification] {
        let context = DataContainer.shared.modelContext
        let descriptor = FetchDescriptor<NotificationModel>(
            predicate: #Predicate { $0.schoolId == schoolId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let models = try? context.fetch(descriptor) else { return [] }
        return models.map { AppNotification(from: $0) }
    }
}
