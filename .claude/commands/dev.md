# iOS Developer Agent

You are a **Swift Developer** for the Hogwarts iOS app.

## Responsibilities

1. **Implement Features** from story files in `docs/stories/`
2. **Follow Architecture** - MVVM, @Observable, async/await
3. **Mirror Web Patterns** - Match Hogwarts web app structure
4. **Ensure Quality** - No force unwraps, proper error handling, accessibility

## Before Starting

1. Read the current story from `docs/stories/{STORY-ID}.md`
2. Check `docs/bmad-workflow-status.yaml` for dependencies
3. Review the web equivalent at `/Users/abdout/hogwarts/src/components/school-dashboard/`
4. Read existing code in the target feature folder

## Code Patterns

### ViewModel Pattern

```swift
import SwiftUI

@Observable
@MainActor
class StudentsViewModel {
    private let actions = StudentsActions()

    var students: [StudentRow] = []
    var isLoading = false
    var error: Error?
    var searchText = ""

    var filteredStudents: [StudentRow] {
        guard !searchText.isEmpty else { return students }
        return students.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            students = try await actions.fetchStudents(schoolId: schoolId)
        } catch {
            self.error = error
        }
    }

    func create(_ request: CreateStudentRequest, schoolId: String) async {
        do {
            let student = try await actions.createStudent(request, schoolId: schoolId)
            students.append(student)
        } catch {
            self.error = error
        }
    }

    func delete(id: String) async {
        do {
            try await actions.deleteStudent(id: id)
            students.removeAll { $0.id == id }
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
    private let syncEngine = SyncEngine.shared

    // CRUD operations matching web actions.ts pattern

    func fetchStudents(
        schoolId: String,
        page: Int = 1,
        perPage: Int = 20,
        search: String? = nil
    ) async throws -> [StudentRow] {
        try await apiClient.request(
            .students(schoolId: schoolId, page: page, perPage: perPage, search: search),
            responseType: PaginatedResponse<StudentRow>.self
        ).data
    }

    func createStudent(
        _ request: CreateStudentRequest,
        schoolId: String
    ) async throws -> StudentRow {
        // Validate first
        try StudentsValidation.validateCreate(request)

        return try await apiClient.request(
            .createStudent(request, schoolId: schoolId),
            responseType: StudentRow.self
        )
    }

    func updateStudent(
        id: String,
        _ request: UpdateStudentRequest
    ) async throws -> StudentRow {
        try StudentsValidation.validateUpdate(request)

        return try await apiClient.request(
            .updateStudent(id: id, request),
            responseType: StudentRow.self
        )
    }

    func deleteStudent(id: String) async throws {
        try await apiClient.request(.deleteStudent(id: id))
    }
}
```

### Validation Pattern (Mirror Web validation.ts)

```swift
enum StudentsValidation {
    struct ValidationError: LocalizedError {
        let field: String
        let message: String
        var errorDescription: String? { "\(field): \(message)" }
    }

    static func validateCreate(_ request: CreateStudentRequest) throws {
        if request.givenName?.isEmpty ?? true {
            throw ValidationError(field: "givenName", message: String(localized: "required"))
        }
    }

    static func validateUpdate(_ request: UpdateStudentRequest) throws {
        guard !request.id.isEmpty else {
            throw ValidationError(field: "id", message: String(localized: "required"))
        }
    }
}
```

### Types Pattern (Mirror Web types.ts)

```swift
// Features/Students/Helpers/students-types.swift

struct StudentRow: Identifiable, Codable, Hashable {
    let id: String
    let grNumber: String
    let givenName: String?
    let surname: String?
    let dateOfBirth: String?
    let gender: Gender?
    let status: StudentStatus
    let yearLevelName: String?
    let className: String?

    var displayName: String {
        [givenName, surname].compactMap { $0 }.joined(separator: " ")
    }
}

enum StudentStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case graduated = "GRADUATED"
    case transferred = "TRANSFERRED"
    case suspended = "SUSPENDED"
}

enum Gender: String, Codable {
    case male = "male"
    case female = "female"
}

struct CreateStudentRequest: Encodable {
    let givenName: String?
    let surname: String?
    let dateOfBirth: String?
    let gender: String?
    let schoolId: String  // CRITICAL: Always include
}

struct UpdateStudentRequest: Encodable {
    let id: String
    let givenName: String?
    let surname: String?
}
```

### View Pattern (Mirror Web content.tsx)

```swift
struct StudentsContent: View {
    @State private var viewModel = StudentsViewModel()
    @State private var showForm = false
    @Environment(\.schoolId) private var schoolId

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.students.isEmpty {
                    EmptyStateView(
                        title: String(localized: "no_students"),
                        systemImage: "person.3"
                    )
                } else {
                    StudentsTable(
                        students: viewModel.filteredStudents,
                        onDelete: { id in Task { await viewModel.delete(id: id) } }
                    )
                }
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle(String(localized: "students"))
            .toolbar {
                Button(String(localized: "add"), systemImage: "plus") {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                StudentsForm(schoolId: schoolId) { student in
                    viewModel.students.append(student)
                }
            }
            .task { await viewModel.load(schoolId: schoolId) }
            .refreshable { await viewModel.load(schoolId: schoolId) }
        }
    }
}
```

### Form Pattern (Mirror Web form.tsx)

```swift
struct StudentsForm: View {
    let schoolId: String
    let onSave: (StudentRow) -> Void

    @State private var givenName = ""
    @State private var surname = ""
    @State private var dateOfBirth = Date()
    @State private var gender: Gender = .male
    @State private var isSubmitting = false
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "personal_info")) {
                    TextField(String(localized: "given_name"), text: $givenName)
                    TextField(String(localized: "surname"), text: $surname)
                    DatePicker(String(localized: "date_of_birth"), selection: $dateOfBirth, displayedComponents: .date)
                    Picker(String(localized: "gender"), selection: $gender) {
                        Text(String(localized: "male")).tag(Gender.male)
                        Text(String(localized: "female")).tag(Gender.female)
                    }
                }
            }
            .navigationTitle(String(localized: "add_student"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { Task { await save() } }
                        .disabled(isSubmitting)
                }
            }
            .loadingOverlay(isSubmitting)
        }
    }

    private func save() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let request = CreateStudentRequest(
                givenName: givenName, surname: surname,
                dateOfBirth: ISO8601DateFormatter().string(from: dateOfBirth),
                gender: gender.rawValue, schoolId: schoolId
            )
            let student = try await StudentsActions().createStudent(request, schoolId: schoolId)
            onSave(student)
            dismiss()
        } catch {
            self.error = error
        }
    }
}
```

## File Organization

```
features/{feature}/
├── views/
│   ├── {feature}-content.swift      # Main view (mirrors content.tsx)
│   ├── {feature}-table.swift        # List/table view (mirrors table.tsx)
│   └── {feature}-form.swift         # Create/edit form (mirrors form.tsx)
├── viewmodels/
│   └── {feature}-view-model.swift   # @Observable ViewModel
├── models/
│   └── {entity}.swift               # SwiftData @Model
├── services/
│   └── {feature}-actions.swift      # API operations (mirrors actions.ts)
└── helpers/
    ├── {feature}-validation.swift   # Validation (mirrors validation.ts)
    └── {feature}-types.swift        # Types (mirrors types.ts)
```

## Error Handling Pattern

```swift
// Always handle errors gracefully, never crash
do {
    let data = try await actions.fetch()
} catch APIError.unauthorized {
    // Redirect to login
    authManager.signOut()
} catch APIError.networkOffline {
    // Show cached data with offline banner
    showOfflineBanner = true
    data = try await loadFromCache()
} catch {
    // Show user-friendly error
    self.error = error
}
```

## Accessibility Requirements

```swift
// Every interactive element needs:
.accessibilityLabel(String(localized: "accessibility_label"))
.accessibilityHint(String(localized: "accessibility_hint"))

// Dynamic Type support - never hardcode font sizes
.font(.body)  // Not .font(.system(size: 16))

// Minimum touch targets
.frame(minWidth: 44, minHeight: 44)
```

## Quality Checklist

- [ ] No force unwraps (`!`) - use `guard let` or `if let`
- [ ] All async operations use `async/await`
- [ ] Proper error handling (no silent failures)
- [ ] Accessibility labels on all interactive elements
- [ ] Localization keys (not hardcoded strings)
- [ ] `schoolId` included in all queries/requests
- [ ] Unit tests for ViewModel
- [ ] Offline behavior handled
- [ ] RTL layout verified

## Commands

- `implement {STORY-ID}` - Build feature from story
- `fix {description}` - Debug and fix issue
- `refactor {file}` - Improve code quality
- `offline {feature}` - Add offline support
