# CLAUDE.md - Hogwarts iOS App

This file provides guidance to Claude Code when working with the Hogwarts iOS application.

---

## Vision

**Hogwarts iOS** is the native mobile companion for the Hogwarts school management platform. Built with Swift and SwiftUI, it provides offline-first access to school features for all 8 user roles.

### Key Principles

1. **Offline-First**: All critical features work without internet
2. **Multi-Tenant**: Strict schoolId isolation (mirrors web app)
3. **Role-Based**: 8 distinct user experiences
4. **Bilingual**: Arabic (RTL) + English (LTR)
5. **Native**: Pure Swift/SwiftUI, no cross-platform frameworks

---

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Language | Swift | 5.9+ |
| UI | SwiftUI | iOS 17+ |
| Storage | SwiftData | iOS 17+ |
| Networking | URLSession | async/await |
| Auth | Keychain + OAuth | - |
| Testing | XCTest | - |
| Min Target | iOS | 17.0 |

---

## Architecture

### MVVM + Clean Architecture

```
┌─────────────────────────────────────────────────┐
│                    Views                         │
│              (SwiftUI Views)                     │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│                 ViewModels                       │
│     (ObservableObject, @Published)              │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│                 UseCases                         │
│          (Business Logic Layer)                 │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│               Repositories                       │
│    (Data abstraction - local + remote)          │
└─────────────────────────────────────────────────┘
            │                    │
            ▼                    ▼
┌──────────────────┐  ┌──────────────────────────┐
│   SwiftData      │  │    Network (APIClient)   │
│   (Local DB)     │  │    (Remote API)          │
└──────────────────┘  └──────────────────────────┘
```

### Directory Structure

```
Hogwarts/
├── App/
│   ├── HogwartsApp.swift          # App entry point
│   ├── AppDelegate.swift          # Push notifications
│   └── AppState.swift             # Global app state
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift        # HTTP client
│   │   ├── Endpoint.swift         # API endpoints
│   │   ├── AuthInterceptor.swift  # JWT injection
│   │   └── NetworkMonitor.swift   # Connectivity
│   ├── Storage/
│   │   ├── SwiftDataContainer.swift
│   │   └── SyncEngine.swift       # Offline sync
│   ├── Auth/
│   │   ├── AuthManager.swift      # Token management
│   │   ├── KeychainService.swift  # Secure storage
│   │   └── BiometricAuth.swift    # Face ID / Touch ID
│   └── Extensions/
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Dashboard/
│   ├── Students/
│   ├── Attendance/
│   ├── Grades/
│   ├── Timetable/
│   ├── Messages/
│   ├── Notifications/
│   └── Profile/
├── Shared/
│   ├── Components/               # Reusable UI
│   ├── Models/                   # SwiftData models
│   └── Utils/
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.xcstrings     # String catalogs
    └── Info.plist
```

---

## BMAD Workflow

### Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Analysis | Complete | Requirements gathered |
| 2. Planning | Complete | Architecture defined |
| 3. Solutioning | In Progress | API specs, data models |
| 4. Implementation | Pending | Sprint execution |

### Story Lifecycle

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│ Backlog │──▶│ Sprint  │──▶│ In Dev  │──▶│ Testing │──▶│  Done   │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
     │             │             │             │             │
     │        /ios-analyst  /ios-dev     /ios-qa        Review
     │             │             │             │
     ▼             ▼             ▼             ▼
   PRD.md     Story.md      Code.swift   Tests.swift
```

### Definition of Done

- [ ] Code compiles without warnings
- [ ] Unit tests pass (80%+ coverage)
- [ ] UI tests for critical paths
- [ ] SwiftLint passes
- [ ] Localized (ar + en)
- [ ] Accessibility labels added
- [ ] Offline mode tested
- [ ] Code reviewed

---

## Agent Commands

| Command | Agent | Purpose |
|---------|-------|---------|
| `/ios-analyst` | Analyst | Requirements analysis |
| `/ios-architect` | Architect | Architecture decisions |
| `/ios-dev` | Developer | Swift implementation |
| `/ios-qa` | QA | Testing (XCTest) |
| `/ios-ui` | UI Expert | SwiftUI components |
| `/ios-status` | Status | Workflow status |
| `/ios-next` | Navigator | Advance workflow |

### Agent Skills

| Agent | Skills |
|-------|--------|
| Analyst | User stories, acceptance criteria, PRD |
| Architect | MVVM, Clean Architecture, SwiftData schema |
| Developer | Swift 5.9, SwiftUI, async/await, Combine |
| QA | XCTest, UI testing, accessibility |
| UI Expert | SwiftUI, animations, RTL support |

---

## API Integration

### Backend: Hogwarts Next.js API

Base URL: `https://ed.databayt.org/api`

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/session` | GET | Get current session |
| `/auth/signin` | POST | Login with credentials |
| `/students` | GET | List students (scoped by schoolId) |
| `/attendance` | GET/POST | Attendance records |
| `/grades` | GET | Exam results |
| `/timetable` | GET | Class schedule |
| `/messages` | GET/POST | Conversations |
| `/notifications` | GET | User notifications |

### Authentication Flow

```swift
// 1. Login via OAuth or credentials
let session = try await authManager.signIn(with: credentials)

// 2. Store JWT in Keychain
try keychainService.save(session.accessToken, for: .accessToken)

// 3. All API requests include Authorization header
// Authorization: Bearer <jwt_token>
```

### Multi-Tenant Scoping

```swift
// CRITICAL: All API requests must include schoolId
// The backend filters data by schoolId from JWT claims

// Session contains:
struct Session: Codable {
    let user: User
    let schoolId: String    // Tenant identifier
    let role: UserRole      // STUDENT, TEACHER, etc.
}
```

---

## SwiftData Models

### Core Models (Priority)

```swift
@Model
class User {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: UserRole
    var schoolId: String
    var imageUrl: String?

    // Sync metadata
    var lastSyncedAt: Date?
    var isLocalOnly: Bool = false
}

@Model
class School {
    @Attribute(.unique) var id: String
    var name: String
    var domain: String
    var logoUrl: String?
}

@Model
class Student {
    @Attribute(.unique) var id: String
    var grNumber: String
    var userId: String
    var schoolId: String
    var yearLevelId: String?
    var status: StudentStatus

    @Relationship var user: User?
    @Relationship var attendance: [Attendance]
    @Relationship var grades: [ExamResult]
}
```

### Offline Queue Model

```swift
@Model
class PendingAction {
    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String  // GET, POST, PUT, DELETE
    var payload: Data?
    var createdAt: Date
    var retryCount: Int = 0
    var status: SyncStatus = .pending
    var errorMessage: String?
}

enum SyncStatus: String, Codable {
    case pending
    case syncing
    case completed
    case failed
}
```

---

## Offline-First Strategy

### Sync Engine

```swift
actor SyncEngine {
    private let apiClient: APIClient
    private let modelContext: ModelContext

    // Sync on app launch
    func syncAll() async throws {
        try await syncUsers()
        try await syncAttendance()
        try await syncGrades()
        try await syncMessages()
        try await processPendingActions()
    }

    // Queue offline action
    func queueAction(_ action: PendingAction) async {
        modelContext.insert(action)
        try? modelContext.save()
    }

    // Process queue when online
    func processPendingActions() async throws {
        let pending = try fetchPendingActions()
        for action in pending {
            try await executeAction(action)
        }
    }
}
```

### Conflict Resolution

| Entity | Strategy | Implementation |
|--------|----------|----------------|
| Attendance | Server wins | Overwrite local |
| Messages | Merge | Append by timestamp |
| Profile | Last-write-wins | Compare updatedAt |
| Grades | Server wins | Read-only locally |

---

## Localization

### Languages

- **Arabic (ar)**: RTL, default
- **English (en)**: LTR

### String Catalogs

```
Resources/
└── Localizable.xcstrings
    ├── ar/              # Arabic translations
    └── en/              # English translations
```

### RTL Support

```swift
// SwiftUI automatically handles RTL
// Use Environment for explicit control
@Environment(\.layoutDirection) var layoutDirection

// Flip icons for RTL
Image(systemName: "chevron.right")
    .flipsForRightToLeftLayoutDirection(true)
```

### Fonts

- **Arabic**: Tajawal (Google Fonts)
- **English**: SF Pro (system)

---

## User Roles

| Role | Features Access |
|------|-----------------|
| DEVELOPER | All (platform admin) |
| ADMIN | School management |
| TEACHER | Classes, attendance, grades |
| STUDENT | Dashboard, grades, schedule |
| GUARDIAN | Children's info |
| ACCOUNTANT | Finance features |
| STAFF | Limited admin |
| USER | Basic profile |

### Role-Based UI

```swift
@ViewBuilder
func dashboardView(for role: UserRole) -> some View {
    switch role {
    case .student:
        StudentDashboard()
    case .teacher:
        TeacherDashboard()
    case .guardian:
        GuardianDashboard()
    case .admin, .developer:
        AdminDashboard()
    default:
        DefaultDashboard()
    }
}
```

---

## Push Notifications (APNs)

### Setup

1. Enable Push Notifications capability
2. Register device token on app launch
3. Handle notifications in AppDelegate

### Implementation

```swift
// AppDelegate.swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    Task {
        try await apiClient.registerDeviceToken(token)
    }
}

func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {
    // Handle silent push - trigger sync
    await syncEngine.syncAll()
    return .newData
}
```

### Notification Types

- `message` - New chat message
- `assignment_created` - New assignment
- `grade_posted` - Grade available
- `attendance_alert` - Absence notification
- `fee_due` - Payment reminder
- `announcement` - School announcement

---

## Testing Strategy

### Unit Tests (80%+ coverage)

```swift
// ViewModels
func test_loginViewModel_successfulLogin() async throws {
    let viewModel = LoginViewModel(authManager: MockAuthManager())
    await viewModel.login(email: "test@test.com", password: "password")
    XCTAssertTrue(viewModel.isAuthenticated)
}

// Repositories
func test_studentRepository_fetchesFromCache() async throws {
    let repo = StudentRepository(local: mockLocal, remote: mockRemote)
    let students = try await repo.getStudents()
    XCTAssertEqual(students.count, 5)
}
```

### UI Tests

```swift
func test_loginFlow_success() {
    let app = XCUIApplication()
    app.launch()

    app.textFields["email"].tap()
    app.textFields["email"].typeText("test@school.com")
    app.secureTextFields["password"].tap()
    app.secureTextFields["password"].typeText("password123")
    app.buttons["login"].tap()

    XCTAssertTrue(app.staticTexts["Dashboard"].exists)
}
```

---

## Code Style

### SwiftLint Rules

```yaml
# .swiftlint.yml
disabled_rules:
  - line_length
opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional
```

### Naming Conventions

- **Views**: `{Feature}View.swift` (e.g., `LoginView.swift`)
- **ViewModels**: `{Feature}ViewModel.swift`
- **Models**: `{Entity}.swift` (e.g., `Student.swift`)
- **Services**: `{Name}Service.swift`

### Async/Await

```swift
// Prefer async/await over Combine for API calls
func fetchStudents() async throws -> [Student] {
    try await apiClient.request(.students)
}

// Use @MainActor for UI updates
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var students: [Student] = []

    func loadStudents() async {
        students = try await repository.getStudents()
    }
}
```

---

## Dependencies (SPM)

```swift
// Package.swift
dependencies: [
    // OAuth
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "16.0.0"),

    // Security
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0"),

    // Images
    .package(url: "https://github.com/kean/Nuke", from: "12.0.0"),

    // DI
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),

    // QR Code
    .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.52.0"),
]
```

---

## Quick Reference

### Common Commands

```bash
# Build
xcodebuild -scheme Hogwarts -destination 'platform=iOS Simulator,name=iPhone 15'

# Test
xcodebuild test -scheme Hogwarts -destination 'platform=iOS Simulator,name=iPhone 15'

# Lint
swiftlint lint

# Format
swiftformat .
```

### BMAD Commands

| Say | Action |
|-----|--------|
| `/ios-status` | Show workflow status |
| `/ios-next` | Advance to next phase/story |
| `/ios-dev` | Start implementing current story |
| `/ios-qa` | Run tests and validation |

---

## References

- [Hogwarts Web App](https://ed.databayt.org)
- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [SwiftData Docs](https://developer.apple.com/documentation/swiftdata)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
