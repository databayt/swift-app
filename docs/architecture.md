# Technical Architecture
## Hogwarts iOS App

**Version**: 2.0
**Last Updated**: 2026-02-08

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App                                  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                  Presentation Layer                         │  │
│  │  Auth │ Dashboard │ Students │ Attendance │ Grades │ ...   │  │
│  │  Views   Views      Views      Views        Views          │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                              │                                    │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │                  ViewModel Layer                             │  │
│  │  @Observable + @MainActor ViewModels                        │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                              │                                    │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │                  Actions Layer                               │  │
│  │  Feature-specific API operations (mirrors web actions.ts)   │  │
│  └──────────┬───────────────────────────────┬─────────────────┘  │
│             │                               │                     │
│  ┌──────────┴──────────┐  ┌────────────────┴──────────────────┐  │
│  │    APIClient        │  │    SwiftData + SyncEngine         │  │
│  │    (Remote)         │  │    (Local + Offline Queue)        │  │
│  └──────────┬──────────┘  └───────────────────────────────────┘  │
└─────────────┼─────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Hogwarts Backend                              │
│                   (Next.js API Server)                            │
│                  https://ed.databayt.org/api                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Responsibilities

### 2.1 Presentation Layer
- SwiftUI Views (declarative UI)
- Navigation (NavigationStack, TabView)
- Localization (Localizable.xcstrings)
- Accessibility (VoiceOver, Dynamic Type)

### 2.2 ViewModel Layer
- `@Observable` + `@MainActor` classes
- State management (loading, error, data)
- User action handling
- Data transformation for display

### 2.3 Actions Layer
- Async API operations (mirrors web `actions.ts`)
- Input validation (mirrors web `validation.ts`)
- Request/response type definitions
- Offline queue integration

### 2.4 Data Layer
- APIClient: HTTP requests with JWT auth
- SwiftData: Local persistence and cache
- SyncEngine: Offline queue processing
- NetworkMonitor: Connectivity detection

---

## 3. Navigation Architecture

### 3.1 Tab Structure

```swift
enum AppTab: String, CaseIterable {
    case dashboard
    case attendance
    case grades
    case messages
    case profile
}
```

Tabs are role-dependent:
| Role | Tabs |
|------|------|
| Student | Dashboard, Grades, Timetable, Messages, Profile |
| Teacher | Dashboard, Attendance, Grades, Messages, Profile |
| Guardian | Dashboard, Grades, Messages, Profile |
| Admin | Dashboard, Students, Attendance, Messages, Profile |

### 3.2 Navigation Routes

```swift
enum AppRoute: Hashable {
    // Dashboard
    case dashboard

    // Students
    case students
    case studentDetail(id: String)
    case studentForm(id: String?)

    // Attendance
    case attendance
    case attendanceForm(classId: String)
    case attendanceHistory(studentId: String)

    // Grades
    case grades
    case gradeDetail(studentId: String, subjectId: String)
    case reportCard(studentId: String, termId: String)

    // Messages
    case conversations
    case conversation(id: String)
    case newMessage

    // Profile
    case profile
    case settings
    case languageSettings
}
```

### 3.3 Navigation Pattern

```swift
// Each tab has its own NavigationStack
TabView(selection: $selectedTab) {
    NavigationStack(path: $dashboardPath) {
        DashboardContent()
            .navigationDestination(for: AppRoute.self) { route in
                routeView(for: route)
            }
    }
    .tabItem { Label("dashboard", systemImage: "house") }
    .tag(AppTab.dashboard)

    // ... more tabs
}
```

---

## 4. Dependency Injection

### 4.1 Environment-Based DI

```swift
// Custom environment keys
struct SchoolIdKey: EnvironmentKey {
    static let defaultValue: String = ""
}

struct APIClientKey: EnvironmentKey {
    static let defaultValue = APIClient.shared
}

extension EnvironmentValues {
    var schoolId: String {
        get { self[SchoolIdKey.self] }
        set { self[SchoolIdKey.self] = newValue }
    }

    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

// Injected at app root
@main
struct HogwartsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.schoolId, authManager.schoolId ?? "")
                .environment(\.apiClient, APIClient.shared)
        }
        .modelContainer(DataContainer.shared.container)
    }
}
```

### 4.2 Protocol-Based Abstraction (for Testing)

```swift
protocol StudentActionsProtocol {
    func fetchStudents(schoolId: String) async throws -> [StudentRow]
    func createStudent(_ data: CreateStudentRequest, schoolId: String) async throws -> StudentRow
}

// Production
struct StudentsActions: StudentActionsProtocol { ... }

// Testing
class MockStudentsActions: StudentActionsProtocol { ... }
```

---

## 5. Core Components

### 5.1 APIClient

```swift
actor APIClient {
    static let shared = APIClient(
        baseURL: URL(string: "https://ed.databayt.org/api")!,
        authManager: AuthManager.shared
    )

    private let session: URLSession
    private let baseURL: URL
    private let authManager: AuthManager

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
            return try JSONDecoder.iso8601.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.validationFailed(errorResponse?.error ?? "Validation failed")
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}
```

### 5.2 AuthManager

```swift
@Observable
class AuthManager {
    static let shared = AuthManager()

    private let keychain = KeychainService()

    var isAuthenticated: Bool { accessToken != nil }
    var currentUser: User?
    var schoolId: String?

    var accessToken: String? {
        keychain.get(.accessToken)
    }

    func signIn(email: String, password: String) async throws -> Session { ... }
    func signInWithGoogle() async throws -> Session { ... }
    func signInWithFacebook() async throws -> Session { ... }
    func signOut() { ... }
}
```

### 5.3 SyncEngine

```swift
actor SyncEngine {
    static let shared = SyncEngine()

    private let apiClient: APIClient
    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor

    // Full sync on app launch
    func syncAll(schoolId: String) async throws {
        guard networkMonitor.isConnected else { return }

        // Process offline queue first
        try await processPendingActions()

        // Then sync data in parallel
        async let students = syncStudents(schoolId: schoolId)
        async let attendance = syncAttendance(schoolId: schoolId)
        async let grades = syncGrades(schoolId: schoolId)
        _ = try await (students, attendance, grades)
    }

    // Queue offline action
    func queueAction(endpoint: String, method: String, payload: Data?) async { ... }

    // Process queue when online
    func processPendingActions() async throws { ... }
}
```

### 5.4 NetworkMonitor

```swift
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected = true

    init() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
```

---

## 6. Error Handling Strategy

### 6.1 Error Types

```swift
enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case validationFailed(String)
    case serverError(Int)
    case networkOffline
    case invalidResponse
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: String(localized: "error_unauthorized")
        case .forbidden: String(localized: "error_forbidden")
        case .notFound: String(localized: "error_not_found")
        case .validationFailed(let msg): msg
        case .serverError(let code): String(localized: "error_server_\(code)")
        case .networkOffline: String(localized: "error_offline")
        case .invalidResponse: String(localized: "error_invalid_response")
        case .decodingFailed: String(localized: "error_decoding")
        }
    }
}
```

### 6.2 ViewState Mapping

```swift
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case empty
    case error(String)
    case offline(T?)  // Cached data available
}
```

### 6.3 Error to Action Mapping

| Error | User-Facing Action |
|-------|--------------------|
| `unauthorized` | Redirect to login |
| `forbidden` | Show "Permission denied" |
| `notFound` | Show "Not found" with back button |
| `validationFailed` | Show field-level errors |
| `serverError` | Show "Something went wrong" + retry |
| `networkOffline` | Show offline banner + cached data |

---

## 7. SwiftData Schema

### 7.1 Core Models (Sprint 1)

```swift
@Model class User { ... }        // Auth & profile
@Model class School { ... }      // Tenant info
@Model class PendingAction { ... } // Offline queue
```

### 7.2 Feature Models (Sprint 2)

```swift
@Model class Student { ... }     // Student records
@Model class Attendance { ... }  // Attendance records
@Model class ExamResult { ... }  // Grade results
@Model class ReportCard { ... }  // Term summaries
@Model class Class { ... }       // Class/section
@Model class Subject { ... }     // Academic subjects
@Model class YearLevel { ... }   // Grade levels
```

### 7.3 Communication Models (Sprint 3)

```swift
@Model class Message { ... }           // Chat messages
@Model class Conversation { ... }      // Chat threads
@Model class Notification { ... }      // Push notifications
@Model class Period { ... }            // Timetable periods
```

### 7.4 Model Categories from Web (209+ Prisma Models)

| Category | Key Models | iOS Sprint |
|----------|-----------|-----------|
| Auth | User, Account, School | Sprint 1 |
| Students | Student, Guardian, StudentClass | Sprint 2 |
| Attendance | Attendance, AttendanceExcuse | Sprint 2 |
| Grades | ExamResult, ReportCard, GradeBoundary | Sprint 2 |
| Timetable | Period, Class, Classroom | Sprint 3 |
| Messages | Message, Conversation | Sprint 3 |
| Notifications | Notification, NotificationPreference | Sprint 3 |

---

## 8. API Endpoints

### 8.1 Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/session` | GET | Get current session |
| `/api/auth/signin` | POST | Sign in with credentials |
| `/api/auth/signout` | POST | Sign out |
| `/api/auth/callback/{provider}` | POST | OAuth callback |

### 8.2 Students

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/students?schoolId={id}` | GET | List students (paginated) |
| `/api/students/{id}` | GET | Get student details |
| `/api/students` | POST | Create student |
| `/api/students/{id}` | PUT | Update student |
| `/api/students/{id}` | DELETE | Delete student |

### 8.3 Attendance

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/attendance?schoolId={id}` | GET | List attendance records |
| `/api/attendance` | POST | Mark attendance |
| `/api/attendance/qr` | POST | QR-based check-in |
| `/api/attendance/excuse` | POST | Submit excuse |

### 8.4 Grades

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/grades?schoolId={id}` | GET | List grades |
| `/api/grades/report-card/{studentId}` | GET | Get report card |
| `/api/grades` | POST | Enter grades |

### 8.5 Messages

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/messages` | GET | List conversations |
| `/api/messages/{conversationId}` | GET | Get messages |
| `/api/messages` | POST | Send message |

---

## 9. Offline Strategy

### 9.1 Caching Policy

| Data Type | Cache Duration | Sync Trigger |
|-----------|---------------|--------------|
| User Profile | Indefinite | On login |
| Students | 1 hour | App launch |
| Attendance | 24 hours | App launch, pull-refresh |
| Grades | 24 hours | App launch, pull-refresh |
| Timetable | 1 week | App launch |
| Messages | Indefinite | Real-time + periodic |

### 9.2 Conflict Resolution Matrix

| Entity | Strategy | Rule | Reason |
|--------|----------|------|--------|
| Attendance | Server wins | Overwrite local | Official record |
| Grades | Server wins | Overwrite local | Read-only for most |
| Messages | Merge | Append by timestamp | Both sides create |
| Profile | Last-write-wins | Compare updatedAt | Single editor |
| Students | Server wins | Overwrite local | Admin authority |

### 9.3 Queue Processing

1. Actions queued with `PendingAction` model
2. Processed FIFO when online
3. Retry 3 times with exponential backoff (1s, 2s, 4s)
4. Failed actions shown in UI for manual retry
5. Queue processed on: app launch, network restore, manual trigger

---

## 10. Security Architecture

### 10.1 Token Storage

```
Keychain (encrypted)
├── accessToken: JWT
├── refreshToken: String
└── deviceToken: APNs token
```

- All tokens in Keychain (never UserDefaults)
- Keychain accessibility: `.whenUnlockedThisDeviceOnly`
- Biometric protection option via `kSecAccessControlBiometryCurrentSet`

### 10.2 Network Security
- All requests over HTTPS
- Certificate pinning in production (via `URLSessionDelegate`)
- Authorization header with JWT on every request
- No sensitive data in URL query parameters

### 10.3 Data Security
- SwiftData encrypted at rest (device encryption)
- No sensitive data in logs (`os_log` with `.private` for PII)
- Secure input fields for passwords
- Biometric auth flow for app unlock

---

## 11. Accessibility Architecture

### 11.1 VoiceOver
- Every interactive element has `.accessibilityLabel`
- Grouped related elements with `.accessibilityElement(children: .combine)`
- Custom actions with `.accessibilityAction`
- Meaningful descriptions (not "button" or "image")

### 11.2 Dynamic Type
- All text uses system font styles (`.body`, `.title`, etc.)
- `@ScaledMetric` for custom dimensions
- Layouts adapt to larger text sizes
- No text truncation at accessibility sizes

### 11.3 RTL Support
- SwiftUI handles most RTL automatically
- Directional icons flip with `.flipsForRightToLeftLayoutDirection(true)`
- Arabic (RTL) is the default language
- `@Environment(\.layoutDirection)` for explicit checks

### 11.4 Touch Targets
- Minimum 44x44pt for all interactive elements
- Adequate spacing between tappable items
- Clear visual feedback on tap

---

## 12. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Launch (cold) | < 2 seconds | Time Profiler |
| Screen Transition | < 300ms | Animation duration |
| API Response Display | < 1 second | Network + render |
| Memory Usage | < 100MB | Instruments |
| Battery Impact | < 5% per hour active | Energy Diagnostics |
| Scroll Frame Rate | 60 FPS | Core Animation |
| SwiftData Query | < 50ms | Signpost logging |
