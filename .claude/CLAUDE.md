# CLAUDE.md - Hogwarts iOS App

This file provides guidance to Claude Code when working with the Hogwarts iOS application.

---

## 7 Critical Rules

1. **Always include `schoolId`** in API requests and SwiftData queries (multi-tenant isolation)
2. **Follow feature-based structure**: `features/{name}/views|viewmodels|models|services|helpers/`
3. **Use kebab-case for filenames**: `students-content.swift`, `attendance-form.swift`
4. **Use `@Observable` + `@MainActor`** for ViewModels (not ObservableObject/@Published)
5. **All async operations use `async/await`** (no callbacks, no Combine for networking)
6. **Localization via `Localizable.xcstrings`** (no hardcoded strings in views)
7. **Run `xcodebuild -scheme Hogwarts`** before commits to verify compilation

---

## Vision

**Hogwarts iOS** is the native mobile companion for the Hogwarts school management platform. Built with Swift and SwiftUI, it provides offline-first access to school features for all 8 user roles.

### Key Principles

1. **Offline-First**: All critical features work without internet
2. **Multi-Tenant**: Strict schoolId isolation (mirrors web app)
3. **Role-Based**: 8 distinct user experiences
4. **Bilingual**: Arabic (RTL default) + English (LTR)
5. **Native**: Pure Swift/SwiftUI, no cross-platform frameworks

---

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Language | Swift | 6.0+ |
| UI | SwiftUI | iOS 18+ |
| Storage | SwiftData | iOS 18+ |
| Networking | URLSession | async/await |
| Auth | Keychain + OAuth | - |
| Testing | Swift Testing (unit) + XCTest (UI) | - |
| Min Target | iOS | 18.0 |

---

## Web <-> iOS Mirror Pattern

The iOS app mirrors the Hogwarts web app (`/Users/abdout/hogwarts/`) naming conventions:

### File Mapping

| Web (Next.js) | iOS (SwiftUI) | Purpose |
|----------------|----------------|---------|
| `content.tsx` | `{feature}-content.swift` | Main feature view (data display) |
| `form.tsx` | `{feature}-form.swift` | Create/edit form |
| `table.tsx` | `{feature}-table.swift` | Data table/list view |
| `actions.ts` | `{feature}-actions.swift` | API operations (CRUD) |
| `validation.ts` | `{feature}-validation.swift` | Input validation rules |
| `types.ts` | `{feature}-types.swift` | Type definitions & enums |
| `columns.tsx` | `{feature}-columns.swift` | Column/field definitions |
| `authorization.ts` | `{feature}-authorization.swift` | RBAC permission checks |

### Pattern Mapping

| Web Pattern | iOS Pattern |
|-------------|-------------|
| Server Component | SwiftUI View with `.task {}` |
| Client Component | `@Observable` ViewModel |
| Server Action | `{Feature}Actions` async methods |
| Zod Schema | Swift validation functions |
| `revalidatePath()` | SwiftData context save + refresh |
| `Promise.all()` | `async let` + tuple await |
| `getTenantContext()` | `TenantContext.shared.schoolId` |
| `useSearchParams` | `@State var searchText` + `@Bindable` |

### Example: Students Module

```
Web: src/components/school-dashboard/listings/students/
  content.tsx, table.tsx, form.tsx, actions.ts, validation.ts, types.ts

iOS: hogwarts/features/students/
  views/students-content.swift, students-table.swift, students-form.swift
  services/students-actions.swift
  helpers/students-validation.swift, students-types.swift
  viewmodels/students-view-model.swift
  models/student.swift
```

---

## Architecture

### MVVM + Clean Architecture

```
Views (SwiftUI)
    |
    v
ViewModels (@Observable, @MainActor)
    |
    v
Actions (async API calls)
    |
    +---> APIClient (Remote)
    +---> SwiftData (Local)
    +---> SyncEngine (Offline Queue)
```

### Directory Structure

```
hogwarts/
├── app/
│   ├── hogwarts-app.swift           # App entry point
│   └── app-delegate.swift           # Push notifications, lifecycle
├── core/
│   ├── auth/
│   │   ├── auth-manager.swift       # Token management, OAuth
│   │   ├── keychain-service.swift   # Secure storage
│   │   └── tenant-context.swift     # Multi-tenant schoolId
│   ├── network/
│   │   ├── api-client.swift         # HTTP client (async/await)
│   │   └── network-monitor.swift    # Connectivity detection
│   ├── storage/
│   │   ├── data-container.swift     # SwiftData setup
│   │   └── sync-engine.swift        # Offline queue processing
│   └── extensions/
├── features/
│   ├── auth/
│   │   ├── views/
│   │   │   └── login-view.swift
│   │   ├── viewmodels/
│   │   ├── models/
│   │   ├── helpers/
│   │   └── services/
│   ├── dashboard/
│   ├── students/
│   ├── attendance/
│   ├── grades/
│   ├── timetable/
│   ├── messages/
│   ├── notifications/
│   └── profile/
├── shared/
│   ├── ui/                          # Reusable components (HWButton, HWCard, etc.)
│   ├── models/                      # SwiftData models (User, School, etc.)
│   └── utils/
└── resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

---

## Component Hierarchy

| Level | Name | Description | Example |
|-------|------|-------------|---------|
| 1 | `ui` | SwiftUI primitives (HWButton, HWCard) | `shared/ui/` |
| 2 | `atom` | 2+ primitives composed | `HWSearchBar` (TextField + Button) |
| 3 | `feature` | Feature-specific views | `students-content.swift` |
| 4 | `screen` | Full screen with navigation | `StudentDashboard` |

---

## File Naming Conventions

All files use **kebab-case** (matching existing codebase):

| Type | Pattern | Example |
|------|---------|---------|
| View | `{feature}-{purpose}.swift` | `students-content.swift` |
| ViewModel | `{feature}-view-model.swift` | `students-view-model.swift` |
| Model | `{entity}.swift` | `student.swift` |
| Actions | `{feature}-actions.swift` | `students-actions.swift` |
| Validation | `{feature}-validation.swift` | `students-validation.swift` |
| Types | `{feature}-types.swift` | `students-types.swift` |
| Test | `{feature}-tests.swift` | `students-tests.swift` |

### Naming Rules

- **Classes/Structs**: PascalCase (`StudentsViewModel`, `AttendanceForm`)
- **Functions/Properties**: camelCase (`fetchStudents()`, `isLoading`)
- **Files**: kebab-case (`students-view-model.swift`)
- **Enum cases**: camelCase (`case present`, `case absent`)

---

## API Integration

### Backend: Hogwarts Next.js API

Base URL: `https://ed.databayt.org/api`

### Authentication Flow

```swift
// 1. Login via OAuth or credentials
let session = try await authManager.signIn(with: credentials)

// 2. Store JWT in Keychain
try keychainService.save(session.accessToken, for: .accessToken)

// 3. All API requests include Authorization header
// Authorization: Bearer <jwt_token>

// 4. Session contains schoolId for multi-tenant scoping
// CRITICAL: Every query MUST include schoolId
```

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/session` | GET | Get current session |
| `/api/auth/signin` | POST | Login with credentials |
| `/api/auth/callback/{provider}` | POST | OAuth callback |
| `/api/students` | GET | List students (scoped by schoolId) |
| `/api/students/{id}` | GET | Student details |
| `/api/attendance` | GET/POST | Attendance records |
| `/api/attendance/qr` | POST | QR-based check-in |
| `/api/grades` | GET | Exam results |
| `/api/grades/report-card/{studentId}` | GET | Report card |
| `/api/timetable` | GET | Class schedule |
| `/api/messages` | GET/POST | Conversations |
| `/api/notifications` | GET | User notifications |

### Multi-Tenant Scoping

```swift
// CRITICAL: All API requests must include schoolId
// The backend filters data by schoolId from JWT claims

struct Session: Codable {
    let user: User
    let schoolId: String    // Tenant identifier
    let role: UserRole      // STUDENT, TEACHER, etc.
}

// In queries - ALWAYS scope by schoolId:
let descriptor = FetchDescriptor<Student>(
    predicate: #Predicate { $0.schoolId == schoolId }
)
```

---

## Multi-Tenant Isolation

### 3 Levels of Protection (Mirror Web App)

**Level 1 - SwiftData Models**: Every model has `schoolId` field
**Level 2 - Query Layer**: All FetchDescriptors include `schoolId` predicate
**Level 3 - API Layer**: JWT contains `schoolId`, backend enforces isolation

```swift
// CORRECT - Always include schoolId
let descriptor = FetchDescriptor<Student>(
    predicate: #Predicate { $0.schoolId == currentSchoolId }
)

// WRONG - Data leak across schools!
let descriptor = FetchDescriptor<Student>()
```

---

## User Roles

| Role | Features Access | Dashboard |
|------|-----------------|-----------|
| DEVELOPER | All (platform admin) | AdminDashboard |
| ADMIN | School management | AdminDashboard |
| TEACHER | Classes, attendance, grades | TeacherDashboard |
| STUDENT | Dashboard, grades, schedule | StudentDashboard |
| GUARDIAN | Children's info | GuardianDashboard |
| ACCOUNTANT | Finance features | AccountantDashboard |
| STAFF | Limited admin | StaffDashboard |
| USER | Basic profile | DefaultDashboard |

### Permission Matrix

| Action | DEVELOPER | ADMIN | TEACHER | STAFF | STUDENT | GUARDIAN |
|--------|-----------|-------|---------|-------|---------|----------|
| CREATE students | Y | Y | Y | N | N | N |
| READ students | Y | Y | Y | Y | Self | Children |
| UPDATE students | Y | Y | Y (school) | N | N | N |
| DELETE students | Y | Y | N | N | N | N |
| MARK attendance | Y | Y | Y | N | N | N |
| VIEW attendance | Y | Y | Y | Y | Self | Children |
| ENTER grades | Y | Y | Y | N | N | N |
| VIEW grades | Y | Y | Y | Y | Self | Children |

---

## Offline-First Strategy

### Sync Engine Rules

1. **Queue all write operations** when offline via `PendingAction`
2. **Process queue FIFO** when connectivity restored
3. **Retry 3 times** with exponential backoff (1s, 2s, 4s)
4. **Failed actions** marked for manual retry in UI
5. **Sync on app launch** if connected

### Cache Policy

| Data Type | Cache Duration | Sync Trigger |
|-----------|---------------|--------------|
| User Profile | Indefinite | On login |
| Students | 1 hour | App launch |
| Attendance | 24 hours | App launch, pull-refresh |
| Grades | 24 hours | App launch, pull-refresh |
| Timetable | 1 week | App launch |
| Messages | Indefinite | Real-time + periodic |

### Conflict Resolution

| Entity | Strategy | Rule |
|--------|----------|------|
| Attendance | Server wins | Official record authority |
| Messages | Merge | Append by timestamp |
| Profile | Last-write-wins | Compare `updatedAt` |
| Grades | Server wins | Read-only locally |

---

## SwiftData Models (Core)

### Priority Models

```swift
@Model class User {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: String  // UserRole raw value
    var schoolId: String?
    var lastSyncedAt: Date?
}

@Model class Student {
    @Attribute(.unique) var id: String
    var grNumber: String
    var userId: String
    var schoolId: String      // REQUIRED: Tenant isolation
    var yearLevelId: String?
    var status: String
    var lastSyncedAt: Date?
}

@Model class Attendance {
    @Attribute(.unique) var id: String
    var studentId: String
    var date: Date
    var status: String        // PRESENT, ABSENT, LATE, EXCUSED
    var method: String?       // MANUAL, QR_CODE, etc.
    var schoolId: String      // REQUIRED: Tenant isolation
    var isLocalOnly: Bool = false
}

@Model class PendingAction {
    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int = 0
    var status: String        // pending, syncing, completed, failed
}
```

---

## Localization

### Languages
- **Arabic (ar)**: RTL, default, Tajawal font
- **English (en)**: LTR, SF Pro font

### Rules
- All user-visible strings in `Localizable.xcstrings`
- Use `LocalizedStringKey` for SwiftUI Text
- RTL handled automatically by SwiftUI
- Use `.flipsForRightToLeftLayoutDirection(true)` for directional icons
- Use `@Environment(\.layoutDirection)` for explicit RTL checks

---

## Code Patterns

### ViewModel Pattern
```swift
@Observable
@MainActor
class StudentsViewModel {
    private let actions = StudentsActions()

    var students: [Student] = []
    var isLoading = false
    var error: Error?

    func load(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            students = try await actions.fetchStudents(schoolId: schoolId)
        } catch {
            self.error = error
        }
    }
}
```

### Actions Pattern (Mirror Web Server Actions)
```swift
struct StudentsActions {
    private let apiClient = APIClient.shared

    func fetchStudents(schoolId: String) async throws -> [Student] {
        try await apiClient.request(
            .students(schoolId: schoolId),
            responseType: [Student].self
        )
    }

    func createStudent(_ data: CreateStudentRequest) async throws -> Student {
        try await apiClient.request(
            .createStudent(data),
            responseType: Student.self
        )
    }
}
```

### View Pattern
```swift
struct StudentsContent: View {
    @State private var viewModel = StudentsViewModel()
    @Environment(\.schoolId) private var schoolId

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else {
                StudentsTable(students: viewModel.students)
            }
        }
        .task { await viewModel.load(schoolId: schoolId) }
    }
}
```

### Parallel Data Fetching (Mirror Web Promise.all)
```swift
// CORRECT - Parallel (mirrors web Promise.all)
async let students = fetchStudents(schoolId: schoolId)
async let attendance = fetchAttendance(schoolId: schoolId)
let (studentList, attendanceList) = try await (students, attendance)

// WRONG - Sequential (waterfall)
let studentList = try await fetchStudents(schoolId: schoolId)
let attendanceList = try await fetchAttendance(schoolId: schoolId)
```

---

## Testing Requirements

### Coverage Target: 80%+

| Test Type | Framework | Target |
|-----------|-----------|--------|
| Unit (ViewModels) | Swift Testing | 80%+ |
| Integration (Repos) | Swift Testing | Key paths |
| UI (Flows) | XCTest + XCUI | Critical flows |
| Accessibility | XCTest | All screens |

### Test Pattern
```swift
import Testing

@MainActor
struct StudentsViewModelTests {
    @Test func loadSuccess() async {
        // Given
        let vm = StudentsViewModel(actions: MockStudentsActions())

        // When
        await vm.load(schoolId: "school_123")

        // Then
        #expect(!vm.isLoading)
        #expect(vm.students.count == 3)
    }
}
```

---

## BMAD Workflow

### Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Analysis | Complete | Requirements gathered |
| 2. Planning | Complete | Architecture defined |
| 3. Solutioning | Complete | API specs, data models |
| 4. Implementation | In Progress | Sprint execution |

### Story Lifecycle

```
Backlog -> Sprint -> In Dev -> Testing -> Done
              |          |         |
         /analyst     /dev      /qa
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
| `/analyst` | Analyst | Requirements analysis, user stories |
| `/architect` | Architect | Architecture decisions, schema design |
| `/dev` | Developer | Swift implementation |
| `/qa` | QA | Testing (Swift Testing + XCTest), quality gates |
| `/ui` | UI Expert | SwiftUI components, animations |
| `/status` | Status | Workflow status report |
| `/next` | Navigator | Advance workflow phase/story |
| `/build` | Build | Build, lint, format workflow |
| `/story` | Story | Create story files from epics |
| `/sync` | Sync | Generate sync engine methods |

---

## Auto-Invocation Workflow

When running through epics/stories, agents chain automatically:

```
/next story
  |
  +--> Picks highest priority pending story
  +--> Reads story file from docs/stories/
  +--> Marks in_progress
  |
  +--> /dev (implements the story)
  |       Reads story acceptance criteria
  |       Creates files per subtask list
  |       Follows mirror pattern from web app
  |
  +--> /qa (tests and verifies)
  |       Runs unit tests
  |       Checks accessibility
  |       Verifies offline behavior
  |
  +--> /next complete {STORY-ID}
  +--> /next story (continues to next)
```

### Sprint Workflow

```
/next sprint     --> Start sprint N
/next story      --> Pick first story, auto-chain dev -> qa -> complete
/next story      --> Pick next story, repeat
...
/next sprint     --> All stories done, advance to sprint N+1
```

### Quick Commands

| Say | What Happens |
|-----|-------------|
| `next` | Pick and implement next story |
| `next story` | Same as above |
| `next sprint` | Start next sprint |
| `next phase` | Advance BMAD phase |
| `next complete AUTH-001` | Mark story done |
| `status` | Show full workflow status |

---

## iOS-Specific Keywords

| Keyword | Action |
|---------|--------|
| `build` | Run `xcodebuild -scheme Hogwarts` |
| `test` | Run test suite (Swift Testing + XCTest) |
| `lint` | Run SwiftLint |
| `format` | Run SwiftFormat |
| `sim` | Build for iOS Simulator |
| `device` | Build for physical device |
| `sync` | Generate sync engine methods |
| `model` | Create SwiftData model |
| `screen` | Create full screen view |
| `offline` | Add offline support to feature |

---

## Dependencies (SPM)

```swift
dependencies: [
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "16.0.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0"),
    .package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
]
```

---

## Quick Reference

### Build Commands

```bash
# Build
xcodebuild -scheme Hogwarts -destination 'platform=iOS Simulator,name=iPhone 16'

# Test
xcodebuild test -scheme Hogwarts -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint
swiftlint lint

# Format
swiftformat .
```

### Test Accounts (password: 1234)

| Email | Role |
|-------|------|
| `dev@databayt.org` | DEVELOPER |
| `admin@databayt.org` | ADMIN |
| `teacher@databayt.org` | TEACHER |
| `student@databayt.org` | STUDENT |
| `parent@databayt.org` | GUARDIAN |

---

## References

- [Hogwarts Web App](https://ed.databayt.org) - Web platform to mirror
- [Web Codebase](/Users/abdout/hogwarts/) - Local web app reference
- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [SwiftData Docs](https://developer.apple.com/documentation/swiftdata)
