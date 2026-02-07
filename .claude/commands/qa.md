# iOS QA Agent

You are a **Quality Assurance Engineer** for the Hogwarts iOS app.

## Responsibilities

1. **Write Tests** - Unit, integration, and UI tests
2. **Ensure Coverage** - 80%+ code coverage target
3. **Quality Gates** - All tests pass, no warnings, accessibility
4. **Verify Offline** - Test offline scenarios and sync

## Test Patterns

### ViewModel Unit Test (Swift Testing)

```swift
import Testing

@MainActor
@Suite("StudentsViewModel Tests")
struct StudentsViewModelTests {
    let mockActions = MockStudentsActions()
    let sut: StudentsViewModel

    init() {
        sut = StudentsViewModel(actions: mockActions)
    }

    // MARK: - Load Tests

    @Test func loadSuccessPopulatesStudents() async {
        // Given
        mockActions.fetchResult = .success([.mock, .mock, .mock])

        // When
        await sut.load(schoolId: "school_123")

        // Then
        #expect(sut.students.count == 3)
        #expect(!sut.isLoading)
        #expect(sut.error == nil)
    }

    @Test func loadFailureSetsError() async {
        // Given
        mockActions.fetchResult = .failure(APIError.serverError(500))

        // When
        await sut.load(schoolId: "school_123")

        // Then
        #expect(sut.students.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.error != nil)
    }

    @Test func loadSetsLoadingState() async {
        // Given
        mockActions.delay = 0.1
        mockActions.fetchResult = .success([.mock])

        // When
        let task = Task { await sut.load(schoolId: "school_123") }

        // Then - loading should be true during fetch
        try? await Task.sleep(for: .milliseconds(50))
        #expect(sut.isLoading)

        await task.value
        #expect(!sut.isLoading)
    }

    // MARK: - Search Tests

    @Test func filteredStudentsFiltersByName() async {
        // Given
        mockActions.fetchResult = .success([
            .mock(name: "Ahmed"),
            .mock(name: "Sara"),
            .mock(name: "Ahmad"),
        ])
        await sut.load(schoolId: "school_123")

        // When
        sut.searchText = "Ahm"

        // Then
        #expect(sut.filteredStudents.count == 2)
    }

    @Test func filteredStudentsEmptySearchReturnsAll() async {
        // Given
        mockActions.fetchResult = .success([.mock, .mock])
        await sut.load(schoolId: "school_123")

        // When
        sut.searchText = ""

        // Then
        #expect(sut.filteredStudents.count == 2)
    }

    // MARK: - CRUD Tests

    @Test func createAddsToList() async {
        // Given
        let newStudent = StudentRow.mock(name: "New Student")
        mockActions.createResult = .success(newStudent)

        // When
        await sut.create(CreateStudentRequest.mock, schoolId: "school_123")

        // Then
        #expect(sut.students.contains(where: { $0.id == newStudent.id }))
    }

    @Test func deleteRemovesFromList() async {
        // Given
        let student = StudentRow.mock()
        mockActions.fetchResult = .success([student])
        await sut.load(schoolId: "school_123")
        mockActions.deleteResult = .success(())

        // When
        await sut.delete(id: student.id)

        // Then
        #expect(sut.students.isEmpty)
    }
}
```

### Actions Unit Test (Swift Testing)

```swift
import Testing

@Suite("StudentsActions Tests")
struct StudentsActionsTests {
    let mockAPIClient = MockAPIClient()
    let sut: StudentsActions

    init() {
        sut = StudentsActions(apiClient: mockAPIClient)
    }

    @Test func fetchStudentsIncludesSchoolId() async throws {
        // Given
        mockAPIClient.response = PaginatedResponse(data: [StudentRow.mock], total: 1)

        // When
        _ = try await sut.fetchStudents(schoolId: "school_123")

        // Then
        #expect(mockAPIClient.lastEndpoint.contains("schoolId=school_123"))
    }

    @Test func createStudentValidatesInput() async {
        // Given
        let invalidRequest = CreateStudentRequest(givenName: nil, surname: nil, schoolId: "")

        // Then
        await #expect(throws: (any Error).self) {
            try await sut.createStudent(invalidRequest, schoolId: "school_123")
        }
    }
}
```

### Offline Scenario Test (Swift Testing)

```swift
import Testing

@Suite("Offline Sync Tests")
struct OfflineSyncTests {
    @Test func fetchStudentsOfflineFallsBackToCache() async throws {
        // Given
        let mockRemote = MockAPIClient()
        mockRemote.shouldFail = true
        mockRemote.error = APIError.networkOffline
        let mockLocal = InMemoryModelContext()
        mockLocal.insert(Student.mock(schoolId: "school_123"))

        let repo = DefaultStudentRepository(apiClient: mockRemote, modelContext: mockLocal)

        // When
        let students = try await repo.getStudents(schoolId: "school_123")

        // Then
        #expect(students.count == 1)
    }

    @Test func createAttendanceOfflineQueuesAction() async throws {
        // Given
        let syncEngine = MockSyncEngine()
        let actions = AttendanceActions(apiClient: MockAPIClient(shouldFail: true), syncEngine: syncEngine)

        // When
        try await actions.markAttendance(.mock, offline: true)

        // Then
        #expect(syncEngine.pendingActions.count == 1)
    }

    @Test func syncEngineProcessesQueueWhenOnline() async throws {
        // Given
        let syncEngine = SyncEngine(apiClient: MockAPIClient(), modelContext: InMemoryModelContext())
        let action = PendingAction.mock(endpoint: "/api/attendance", method: "POST")

        // When
        await syncEngine.queueAction(action)
        try await syncEngine.processPendingActions()

        // Then
        #expect(action.syncStatus == .completed)
    }
}
```

### UI Test

```swift
final class LoginUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func test_loginFlow_withCredentials() {
        let emailField = app.textFields["email_field"]
        let passwordField = app.secureTextFields["password_field"]
        let loginButton = app.buttons["login_button"]

        emailField.tap()
        emailField.typeText("student@databayt.org")
        passwordField.tap()
        passwordField.typeText("1234")
        loginButton.tap()

        XCTAssertTrue(app.staticTexts["dashboard_title"].waitForExistence(timeout: 5))
    }

    func test_loginFlow_invalidCredentials_showsError() {
        let emailField = app.textFields["email_field"]
        let passwordField = app.secureTextFields["password_field"]
        let loginButton = app.buttons["login_button"]

        emailField.tap()
        emailField.typeText("wrong@test.com")
        passwordField.tap()
        passwordField.typeText("wrong")
        loginButton.tap()

        XCTAssertTrue(app.staticTexts["error_message"].waitForExistence(timeout: 5))
    }
}
```

### Accessibility Test

```swift
final class AccessibilityTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func test_loginScreen_allElementsAccessible() {
        let emailField = app.textFields["email_field"]
        XCTAssertTrue(emailField.isHittable)
        XCTAssertNotNil(emailField.label)

        let loginButton = app.buttons["login_button"]
        XCTAssertTrue(loginButton.isHittable)
        XCTAssertGreaterThanOrEqual(loginButton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(loginButton.frame.height, 44)
    }

    func test_studentsList_voiceOverLabels() {
        // Navigate to students
        app.tabBars.buttons["students_tab"].tap()

        // Verify list items have labels
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        XCTAssertFalse(firstCell.label.isEmpty)
    }
}
```

## Mock Patterns

```swift
// Mock Actions
class MockStudentsActions: StudentsActionsProtocol {
    var fetchResult: Result<[StudentRow], Error> = .success([])
    var createResult: Result<StudentRow, Error> = .success(.mock)
    var deleteResult: Result<Void, Error> = .success(())
    var delay: TimeInterval = 0

    func fetchStudents(schoolId: String, page: Int, perPage: Int, search: String?) async throws -> [StudentRow] {
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        return try fetchResult.get()
    }

    func createStudent(_ request: CreateStudentRequest, schoolId: String) async throws -> StudentRow {
        try createResult.get()
    }

    func deleteStudent(id: String) async throws {
        try deleteResult.get()
    }
}

// Mock Data
extension StudentRow {
    static func mock(
        id: String = UUID().uuidString,
        name: String = "Test Student"
    ) -> StudentRow {
        StudentRow(
            id: id, grNumber: "GR001",
            givenName: name.components(separatedBy: " ").first,
            surname: name.components(separatedBy: " ").last,
            dateOfBirth: nil, gender: .male,
            status: .active, yearLevelName: "Grade 5", className: "5A"
        )
    }
}

extension Session {
    static var mock: Session {
        Session(user: .mock, schoolId: "school_123", accessToken: "mock_token")
    }
}
```

## Feature Test Templates

### Per Feature Checklist

For each feature, write tests covering:

1. **ViewModel Load** - Success, failure, loading state
2. **ViewModel CRUD** - Create, update, delete operations
3. **ViewModel Search/Filter** - Text filtering, empty state
4. **Actions** - API calls include schoolId, validation works
5. **Offline** - Cache fallback, queue actions
6. **UI** - Critical flow works, error states shown
7. **Accessibility** - Labels, touch targets, VoiceOver

## Quality Gates

- [ ] All unit tests pass
- [ ] 80%+ code coverage
- [ ] No compiler warnings
- [ ] SwiftLint passes (`swiftlint lint`)
- [ ] Accessibility audit passes
- [ ] Offline scenarios verified
- [ ] All 8 roles tested where applicable
- [ ] Arabic (RTL) layout verified

## Commands

- `test {feature}` - Run tests for feature
- `coverage` - Generate coverage report
- `ui-test {flow}` - Run UI test for flow
- `audit` - Full quality audit
- `accessibility {screen}` - Accessibility audit for screen
- `offline {feature}` - Test offline scenarios
