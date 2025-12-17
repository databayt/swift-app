# Technical Architecture
## Hogwarts iOS App

**Version**: 1.0
**Last Updated**: 2025-12-17

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Presentation Layer                      │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │ │
│  │  │  Auth   │  │Dashboard│  │Attendance│  │ Grades │  ... │ │
│  │  │  Views  │  │  Views  │  │  Views  │  │ Views  │      │ │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │ │
│  └───────┼────────────┼───────────┼───────────┼─────────────┘ │
│          ▼            ▼           ▼           ▼               │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    ViewModel Layer                         │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │ │
│  │  │  Auth   │  │Dashboard│  │Attendance│  │ Grades │  ... │ │
│  │  │   VM    │  │   VM    │  │    VM   │  │   VM   │      │ │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │ │
│  └───────┼────────────┼───────────┼───────────┼─────────────┘ │
│          ▼            ▼           ▼           ▼               │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Domain Layer                            │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │                    UseCases                          │  │ │
│  │  │  LoginUseCase, GetStudentsUseCase, MarkAttendance... │  │ │
│  │  └─────────────────────────┬───────────────────────────┘  │ │
│  └────────────────────────────┼──────────────────────────────┘ │
│                               ▼                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                     Data Layer                             │ │
│  │  ┌─────────────────┐         ┌─────────────────────────┐  │ │
│  │  │   Repositories  │         │      Data Sources       │  │ │
│  │  │                 │    ┌───▶│  ┌──────────────────┐   │  │ │
│  │  │ StudentRepo     │────┤    │  │   SwiftData      │   │  │ │
│  │  │ AttendanceRepo  │    │    │  │   (Local DB)     │   │  │ │
│  │  │ GradeRepo       │    │    │  └──────────────────┘   │  │ │
│  │  │ ...             │    │    │  ┌──────────────────┐   │  │ │
│  │  │                 │    └───▶│  │   APIClient      │   │  │ │
│  │  │                 │         │  │   (Remote API)   │   │  │ │
│  │  └─────────────────┘         │  └──────────────────┘   │  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Hogwarts Backend                             │
│                   (Next.js API Server)                           │
│                  https://ed.databayt.org/api                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Responsibilities

### 2.1 Presentation Layer
- SwiftUI Views
- UI state management
- Navigation
- Localization

### 2.2 ViewModel Layer
- Business logic for views
- State transformation
- Error handling
- Loading states

### 2.3 Domain Layer
- Business rules
- Use cases (single responsibility)
- Domain models

### 2.4 Data Layer
- Repository pattern (abstraction)
- Data sources (local + remote)
- Caching strategy
- Sync logic

---

## 3. Core Components

### 3.1 Network Layer

```swift
// Core/Network/APIClient.swift
actor APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let authManager: AuthManager

    init(baseURL: URL, authManager: AuthManager) {
        self.baseURL = baseURL
        self.authManager = authManager
        self.session = URLSession(configuration: .default)
    }

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type = T.self
    ) async throws -> T {
        var request = endpoint.urlRequest(baseURL: baseURL)

        // Add auth header
        if let token = await authManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

// Core/Network/Endpoint.swift
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let body: Encodable?

    func urlRequest(baseURL: URL) -> URLRequest {
        var url = baseURL.appendingPathComponent(path)

        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = queryItems
            url = components.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        return request
    }
}
```

### 3.2 Auth Manager

```swift
// Core/Auth/AuthManager.swift
@Observable
class AuthManager {
    private let keychain: KeychainService
    private let apiClient: APIClient

    var isAuthenticated: Bool { accessToken != nil }
    var currentUser: User?
    var schoolId: String?

    var accessToken: String? {
        keychain.get(.accessToken)
    }

    func signIn(email: String, password: String) async throws -> Session {
        let session = try await apiClient.request(
            .signIn(email: email, password: password),
            responseType: Session.self
        )

        try keychain.save(session.accessToken, for: .accessToken)
        currentUser = session.user
        schoolId = session.schoolId

        return session
    }

    func signInWithGoogle() async throws -> Session {
        // Google Sign-In flow
        let googleToken = try await GoogleSignIn.signIn()
        let session = try await apiClient.request(
            .signInWithProvider(provider: "google", token: googleToken),
            responseType: Session.self
        )

        try keychain.save(session.accessToken, for: .accessToken)
        currentUser = session.user
        schoolId = session.schoolId

        return session
    }

    func signOut() {
        keychain.delete(.accessToken)
        currentUser = nil
        schoolId = nil
    }
}
```

### 3.3 SwiftData Container

```swift
// Core/Storage/SwiftDataContainer.swift
import SwiftData

@MainActor
class DataContainer {
    static let shared = DataContainer()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            User.self,
            School.self,
            Student.self,
            Teacher.self,
            Attendance.self,
            ExamResult.self,
            Message.self,
            Notification.self,
            PendingAction.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        container = try! ModelContainer(for: schema, configurations: config)
    }

    var modelContext: ModelContext {
        container.mainContext
    }
}
```

### 3.4 Sync Engine

```swift
// Core/Storage/SyncEngine.swift
actor SyncEngine {
    private let apiClient: APIClient
    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor

    // Full sync on app launch
    func syncAll() async throws {
        guard networkMonitor.isConnected else { return }

        // Process pending actions first
        try await processPendingActions()

        // Then sync data
        async let users = syncUsers()
        async let students = syncStudents()
        async let attendance = syncAttendance()

        _ = try await (users, students, attendance)
    }

    // Queue action for offline
    func queueAction(
        endpoint: String,
        method: HTTPMethod,
        payload: Data?
    ) async {
        let action = PendingAction(
            id: UUID(),
            endpoint: endpoint,
            method: method.rawValue,
            payload: payload,
            createdAt: Date(),
            status: .pending
        )

        modelContext.insert(action)
        try? modelContext.save()

        // Try to sync immediately if online
        if networkMonitor.isConnected {
            try? await processPendingActions()
        }
    }

    private func processPendingActions() async throws {
        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { $0.status == .pending },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        let pendingActions = try modelContext.fetch(descriptor)

        for action in pendingActions {
            action.status = .syncing
            try? modelContext.save()

            do {
                try await executeAction(action)
                action.status = .completed
            } catch {
                action.status = .failed
                action.retryCount += 1
                action.errorMessage = error.localizedDescription
            }

            try? modelContext.save()
        }
    }
}
```

---

## 4. Data Models

### 4.1 Core Models

```swift
// Shared/Models/User.swift
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var nameAr: String?
    var role: String  // UserRole raw value
    var schoolId: String?
    var imageUrl: String?
    var phone: String?

    // Sync metadata
    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }

    init(id: String, email: String, name: String, role: String, schoolId: String?) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.schoolId = schoolId
    }
}

enum UserRole: String, Codable {
    case developer = "DEVELOPER"
    case admin = "ADMIN"
    case teacher = "TEACHER"
    case student = "STUDENT"
    case guardian = "GUARDIAN"
    case accountant = "ACCOUNTANT"
    case staff = "STAFF"
    case user = "USER"
}
```

```swift
// Shared/Models/Student.swift
@Model
class Student {
    @Attribute(.unique) var id: String
    var grNumber: String
    var userId: String
    var schoolId: String
    var yearLevelId: String?
    var status: String  // StudentStatus

    // Relationships
    @Relationship(inverse: \Attendance.student)
    var attendanceRecords: [Attendance] = []

    @Relationship(inverse: \ExamResult.student)
    var examResults: [ExamResult] = []

    // Sync metadata
    var lastSyncedAt: Date?

    init(id: String, grNumber: String, userId: String, schoolId: String) {
        self.id = id
        self.grNumber = grNumber
        self.userId = userId
        self.schoolId = schoolId
    }
}
```

```swift
// Shared/Models/Attendance.swift
@Model
class Attendance {
    @Attribute(.unique) var id: String
    var studentId: String
    var classId: String?
    var date: Date
    var status: String  // PRESENT, ABSENT, LATE, EXCUSED
    var method: String? // MANUAL, QR_CODE, etc.
    var schoolId: String

    var student: Student?

    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false

    init(id: String, studentId: String, date: Date, status: String, schoolId: String) {
        self.id = id
        self.studentId = studentId
        self.date = date
        self.status = status
        self.schoolId = schoolId
    }
}
```

### 4.2 Pending Action Model

```swift
// Shared/Models/PendingAction.swift
@Model
class PendingAction {
    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    var status: String  // SyncStatus
    var errorMessage: String?

    var syncStatus: SyncStatus {
        SyncStatus(rawValue: status) ?? .pending
    }

    init(
        id: UUID,
        endpoint: String,
        method: String,
        payload: Data?,
        createdAt: Date,
        status: SyncStatus
    ) {
        self.id = id
        self.endpoint = endpoint
        self.method = method
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = 0
        self.status = status.rawValue
    }
}

enum SyncStatus: String, Codable {
    case pending
    case syncing
    case completed
    case failed
}
```

---

## 5. API Endpoints

### 5.1 Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/session` | GET | Get current session |
| `/api/auth/signin` | POST | Sign in with credentials |
| `/api/auth/signout` | POST | Sign out |
| `/api/auth/callback/{provider}` | POST | OAuth callback |

### 5.2 Students

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/students` | GET | List students (filtered by schoolId) |
| `/api/students/{id}` | GET | Get student details |
| `/api/students/{id}/attendance` | GET | Student attendance history |
| `/api/students/{id}/grades` | GET | Student grades |

### 5.3 Attendance

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/attendance` | GET | List attendance records |
| `/api/attendance` | POST | Mark attendance |
| `/api/attendance/qr` | POST | QR-based check-in |

### 5.4 Grades

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/grades` | GET | List grades |
| `/api/grades/report-card/{studentId}` | GET | Get report card |

### 5.5 Messages

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/messages` | GET | List conversations |
| `/api/messages/{conversationId}` | GET | Get messages |
| `/api/messages` | POST | Send message |

---

## 6. Offline Strategy

### 6.1 Caching Policy

| Data Type | Cache Duration | Sync Trigger |
|-----------|---------------|--------------|
| User Profile | Indefinite | On login |
| Students | 1 hour | App launch |
| Attendance | 24 hours | App launch, pull-refresh |
| Grades | 24 hours | App launch, pull-refresh |
| Timetable | 1 week | App launch |
| Messages | Indefinite | Real-time + periodic |

### 6.2 Conflict Resolution

| Scenario | Resolution |
|----------|------------|
| Attendance marked offline | Server wins (official record) |
| Message sent offline | Merge by timestamp |
| Profile edited offline | Last-write-wins |
| Grade viewed offline | Server wins (read-only) |

### 6.3 Queue Processing

1. Actions queued with timestamp
2. Processed in FIFO order when online
3. Retry 3 times with exponential backoff
4. Failed actions marked for manual retry

---

## 7. Push Notifications

### 7.1 APNs Setup

```swift
// App/AppDelegate.swift
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()
        return true
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            try? await APIClient.shared.registerDeviceToken(token)
        }
    }

    // Handle silent push (trigger sync)
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        try? await SyncEngine.shared.syncAll()
        return .newData
    }
}
```

### 7.2 Notification Types

| Type | Trigger | Action |
|------|---------|--------|
| `message` | New message | Open conversation |
| `grade_posted` | Grade available | Open grades |
| `attendance_alert` | Absence marked | Open attendance |
| `announcement` | New announcement | Open announcements |
| `assignment` | New assignment | Open assignments |

---

## 8. Security

### 8.1 Token Storage
- JWT stored in Keychain
- Biometric protection option
- No tokens in UserDefaults

### 8.2 API Security
- All requests over HTTPS
- Authorization header with JWT
- Certificate pinning (production)

### 8.3 Data Security
- SwiftData encrypted at rest (device encryption)
- No sensitive data in logs
- Secure input fields

---

## 9. Testing Strategy

### 9.1 Unit Tests
- ViewModels (80%+ coverage)
- UseCases
- Repositories (with mocks)
- Network layer

### 9.2 Integration Tests
- API integration
- SwiftData operations
- Sync engine

### 9.3 UI Tests
- Login flow
- Navigation
- Critical user journeys
- Accessibility

---

## 10. Performance Targets

| Metric | Target |
|--------|--------|
| App Launch | < 2 seconds |
| Screen Transition | < 300ms |
| API Response | < 1 second |
| Memory Usage | < 100MB |
| Battery Impact | < 5% per hour active |
