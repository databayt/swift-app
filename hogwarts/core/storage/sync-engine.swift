import SwiftUI
import SwiftData

/// Sync engine for offline-first architecture
/// Handles data synchronization between local SwiftData and remote API
actor SyncEngine {
    static let shared = SyncEngine()

    private let api = APIClient.shared
    private let networkMonitor = NetworkMonitor.shared

    private var isSyncing = false

    // MARK: - Public Methods

    /// Full sync on app launch
    func syncAll() async {
        guard !isSyncing else { return }
        guard networkMonitor.isOnline else { return }

        isSyncing = true
        defer { isSyncing = false }

        // Process pending actions first
        await processPendingActions()

        // Then sync data (parallel)
        async let students = syncStudents()
        async let attendance = syncAttendance()
        async let grades = syncGrades()
        async let messages = syncMessages()
        async let notifications = syncNotifications()

        _ = await (students, attendance, grades, messages, notifications)

        // Post sync complete notification
        await MainActor.run {
            NotificationCenter.default.post(name: .syncCompleted, object: nil)
        }
    }

    /// Sync specific entity type
    func sync(_ entityType: EntityType) async {
        guard networkMonitor.isOnline else { return }

        switch entityType {
        case .students:
            await syncStudents()
        case .attendance:
            await syncAttendance()
        case .grades:
            await syncGrades()
        case .messages:
            await syncMessages()
        case .notifications:
            await syncNotifications()
        }
    }

    /// Queue action for offline processing
    @MainActor
    func queueAction(
        endpoint: String,
        method: HTTPMethod,
        payload: Data?
    ) {
        let action = PendingAction(
            endpoint: endpoint,
            method: method,
            payload: payload
        )

        let context = DataContainer.shared.modelContext
        context.insert(action)
        try? context.save()

        // Try to sync immediately if online
        if networkMonitor.isOnline {
            Task {
                await processPendingActions()
            }
        }
    }

    // MARK: - Pending Actions Processing

    private func processPendingActions() async {
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            let descriptor = FetchDescriptor<PendingAction>(
                predicate: #Predicate { $0.status == "pending" },
                sortBy: [SortDescriptor(\.createdAt)]
            )

            guard let pendingActions = try? context.fetch(descriptor) else { return }

            for action in pendingActions {
                Task {
                    await processAction(action, context: context)
                }
            }
        }
    }

    @MainActor
    private func processAction(_ action: PendingAction, context: ModelContext) async {
        action.status = SyncStatus.syncing.rawValue
        try? context.save()

        // Extract data before crossing actor boundary
        let endpoint = action.endpoint
        let method = action.method
        let payload = action.payload

        do {
            try await executeAction(endpoint: endpoint, method: method, payload: payload)
            action.status = SyncStatus.completed.rawValue
        } catch {
            action.status = SyncStatus.failed.rawValue
            action.retryCount += 1
            action.errorMessage = error.localizedDescription
        }

        try? context.save()
    }

    private func executeAction(endpoint: String, method: String, payload: Data?) async throws {
        let httpMethod = HTTPMethod(rawValue: method) ?? .post

        switch httpMethod {
        case .post:
            if let payload {
                let _: EmptyResponse = try await api.post(endpoint, body: payload)
            }
        case .put:
            if let payload {
                let _: EmptyResponse = try await api.put(endpoint, body: payload)
            }
        case .delete:
            try await api.delete(endpoint)
        default:
            break
        }
    }

    // MARK: - Entity Sync Methods

    private func syncStudents() async {
        // Implementation will fetch from API and update SwiftData
    }

    private func syncAttendance() async {
        // Implementation will fetch from API and update SwiftData
    }

    private func syncGrades() async {
        // Implementation will fetch from API and update SwiftData
    }

    private func syncMessages() async {
        // Implementation will fetch from API and update SwiftData
    }

    private func syncNotifications() async {
        // Implementation will fetch from API and update SwiftData
    }
}

// MARK: - Supporting Types

enum EntityType {
    case students
    case attendance
    case grades
    case messages
    case notifications
}

extension Notification.Name {
    static let syncCompleted = Notification.Name("syncCompleted")
}

// For encoding Data in API requests
extension Data: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.base64EncodedString())
    }
}
