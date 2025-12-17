import SwiftUI
import SwiftData

/// SwiftData container configuration
/// Mirrors: src/lib/db.ts (Prisma client)
@MainActor
final class DataContainer {
    static let shared = DataContainer()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            // Core models
            UserModel.self,
            SchoolModel.self,

            // Feature models
            StudentModel.self,
            TeacherModel.self,
            GuardianModel.self,
            AttendanceModel.self,
            ExamResultModel.self,
            TimetableModel.self,
            MessageModel.self,
            ConversationModel.self,
            NotificationModel.self,

            // Sync models
            PendingAction.self,
            SyncMetadata.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var modelContext: ModelContext {
        container.mainContext
    }
}

// MARK: - Sync Metadata

/// Track sync state per entity type
@Model
final class SyncMetadata {
    @Attribute(.unique) var entityType: String
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(entityType: String) {
        self.entityType = entityType
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

// MARK: - Pending Action (Offline Queue)

/// Queued actions for offline sync
/// Mirrors: Offline-first pattern
@Model
final class PendingAction {
    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    var status: String
    var errorMessage: String?

    var syncStatus: SyncStatus {
        SyncStatus(rawValue: status) ?? .pending
    }

    init(
        endpoint: String,
        method: HTTPMethod,
        payload: Data? = nil
    ) {
        self.id = UUID()
        self.endpoint = endpoint
        self.method = method.rawValue
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
        self.status = SyncStatus.pending.rawValue
    }
}

enum SyncStatus: String, Codable {
    case pending
    case syncing
    case completed
    case failed
}
