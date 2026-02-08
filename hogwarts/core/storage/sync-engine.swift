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
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            let userDescriptor = FetchDescriptor<UserModel>(
                sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
            )
            guard let user = try? context.fetch(userDescriptor).first,
                  let schoolId = user.schoolId else { return }

            Task {
                do {
                    let response: StudentsResponse = try await api.get(
                        "/students",
                        query: ["schoolId": schoolId, "pageSize": "500"],
                        as: StudentsResponse.self
                    )

                    await MainActor.run {
                        for student in response.data {
                            let studentId = student.id
                            let descriptor = FetchDescriptor<StudentModel>(
                                predicate: #Predicate { $0.id == studentId }
                            )

                            if let existing = try? context.fetch(descriptor).first {
                                existing.update(from: student)
                                existing.lastSyncedAt = Date()
                            } else {
                                let model = StudentModel(from: student, schoolId: schoolId)
                                model.lastSyncedAt = Date()
                                context.insert(model)
                            }
                        }

                        try? context.save()
                        updateSyncMetadata(entityType: "students", context: context)
                    }
                } catch {
                    // Non-critical — will retry on next sync
                }
            }
        }
    }

    private func syncAttendance() async {
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            let userDescriptor = FetchDescriptor<UserModel>(
                sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
            )
            guard let user = try? context.fetch(userDescriptor).first,
                  let schoolId = user.schoolId else { return }

            Task {
                do {
                    // Fetch last 30 days of attendance
                    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    let dateFrom = ISO8601DateFormatter().string(from: thirtyDaysAgo)

                    let response: AttendanceResponse = try await api.get(
                        "/attendance",
                        query: [
                            "schoolId": schoolId,
                            "dateFrom": dateFrom,
                            "pageSize": "500"
                        ],
                        as: AttendanceResponse.self
                    )

                    await MainActor.run {
                        for record in response.data {
                            let recordId = record.id
                            let descriptor = FetchDescriptor<AttendanceModel>(
                                predicate: #Predicate { $0.id == recordId }
                            )

                            if let existing = try? context.fetch(descriptor).first {
                                existing.update(from: record)
                                existing.lastSyncedAt = Date()
                            } else {
                                let model = AttendanceModel(from: record, schoolId: schoolId)
                                model.lastSyncedAt = Date()
                                context.insert(model)
                            }
                        }

                        try? context.save()
                        updateSyncMetadata(entityType: "attendance", context: context)
                    }
                } catch {
                    // Non-critical — will retry on next sync
                }
            }
        }
    }

    private func syncGrades() async {
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            let userDescriptor = FetchDescriptor<UserModel>(
                sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
            )
            guard let user = try? context.fetch(userDescriptor).first,
                  let schoolId = user.schoolId else { return }

            Task {
                do {
                    let response: ExamResultsResponse = try await api.get(
                        "/grades/results",
                        query: ["schoolId": schoolId, "pageSize": "500"],
                        as: ExamResultsResponse.self
                    )

                    await MainActor.run {
                        for result in response.data {
                            let resultId = result.id
                            let descriptor = FetchDescriptor<ExamResultModel>(
                                predicate: #Predicate { $0.id == resultId }
                            )

                            if let existing = try? context.fetch(descriptor).first {
                                existing.update(from: result)
                                existing.lastSyncedAt = Date()
                            } else {
                                let model = ExamResultModel(from: result, schoolId: schoolId)
                                model.lastSyncedAt = Date()
                                context.insert(model)
                            }
                        }

                        try? context.save()
                        updateSyncMetadata(entityType: "grades", context: context)
                    }
                } catch {
                    // Non-critical — will retry on next sync
                }
            }
        }
    }

    private func syncMessages() async {
        // Fetch recent conversations and cache in SwiftData
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            // Get schoolId from most recent user
            let userDescriptor = FetchDescriptor<UserModel>(
                sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
            )
            guard let user = try? context.fetch(userDescriptor).first,
                  let schoolId = user.schoolId else { return }

            Task {
                do {
                    let conversations: [Conversation] = try await api.get(
                        "/conversations",
                        query: ["schoolId": schoolId],
                        as: [Conversation].self
                    )

                    await MainActor.run {
                        for conv in conversations {
                            let convId = conv.id
                            let descriptor = FetchDescriptor<ConversationModel>(
                                predicate: #Predicate { $0.id == convId }
                            )

                            if let existing = try? context.fetch(descriptor).first {
                                existing.name = conv.name
                                existing.updatedAt = conv.updatedAt
                                existing.lastSyncedAt = Date()
                            } else {
                                let model = ConversationModel(id: conv.id, schoolId: schoolId)
                                model.name = conv.name
                                model.isGroup = conv.isGroup
                                model.lastSyncedAt = Date()
                                context.insert(model)
                            }
                        }

                        try? context.save()
                        updateSyncMetadata(entityType: "messages", context: context)
                    }
                } catch {
                    // Non-critical — will retry on next sync
                }
            }
        }
    }

    private func syncNotifications() async {
        // Fetch recent notifications and cache in SwiftData
        await MainActor.run {
            let context = DataContainer.shared.modelContext

            // Get schoolId from most recent user
            let userDescriptor = FetchDescriptor<UserModel>(
                sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
            )
            guard let user = try? context.fetch(userDescriptor).first,
                  let schoolId = user.schoolId else { return }

            Task {
                do {
                    let notifications: [AppNotification] = try await api.get(
                        "/notifications",
                        query: ["schoolId": schoolId],
                        as: [AppNotification].self
                    )

                    await MainActor.run {
                        for notif in notifications {
                            let notifId = notif.id
                            let descriptor = FetchDescriptor<NotificationModel>(
                                predicate: #Predicate { $0.id == notifId }
                            )

                            if let existing = try? context.fetch(descriptor).first {
                                existing.isRead = notif.isRead
                                existing.lastSyncedAt = Date()
                            } else {
                                let model = NotificationModel(
                                    id: notif.id,
                                    userId: notif.userId,
                                    type: notif.type,
                                    title: notif.title,
                                    message: notif.message,
                                    schoolId: schoolId
                                )
                                model.isRead = notif.isRead
                                model.lastSyncedAt = Date()
                                context.insert(model)
                            }
                        }

                        try? context.save()
                        updateSyncMetadata(entityType: "notifications", context: context)
                    }
                } catch {
                    // Non-critical — will retry on next sync
                }
            }
        }
    }
    // MARK: - Sync Metadata Helper

    @MainActor
    private func updateSyncMetadata(entityType: String, context: ModelContext) {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.entityType == entityType }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.lastSyncedAt = Date()
            existing.syncVersion += 1
        } else {
            let metadata = SyncMetadata(entityType: entityType)
            metadata.lastSyncedAt = Date()
            metadata.syncVersion = 1
            context.insert(metadata)
        }

        try? context.save()
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
