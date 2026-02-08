import Foundation
import Testing
@testable import Hogwarts

/// Tests for Students feature types, validation, and filters
@Suite("Students")
struct StudentsTests {

    // MARK: - StudentStatus Raw Values

    @Test("StudentStatus ACTIVE rawValue")
    func activeRawValue() {
        #expect(StudentStatus.active.rawValue == "ACTIVE")
    }

    @Test("StudentStatus INACTIVE rawValue")
    func inactiveRawValue() {
        #expect(StudentStatus.inactive.rawValue == "INACTIVE")
    }

    @Test("StudentStatus GRADUATED rawValue")
    func graduatedRawValue() {
        #expect(StudentStatus.graduated.rawValue == "GRADUATED")
    }

    @Test("StudentStatus TRANSFERRED rawValue")
    func transferredRawValue() {
        #expect(StudentStatus.transferred.rawValue == "TRANSFERRED")
    }

    @Test("StudentStatus SUSPENDED rawValue")
    func suspendedRawValue() {
        #expect(StudentStatus.suspended.rawValue == "SUSPENDED")
    }

    @Test("StudentStatus has 5 cases")
    func statusCaseCount() {
        #expect(StudentStatus.allCases.count == 5)
    }

    // MARK: - StudentInfo fullName

    @Test("StudentInfo fullName concatenates given and surname")
    func studentInfoFullName() {
        let info = StudentInfo(
            id: "stu_1",
            grNumber: "GR001",
            givenName: "Harry",
            surname: "Potter",
            photoUrl: nil
        )
        #expect(info.fullName == "Harry Potter")
    }

    @Test("StudentInfo fullName handles nil givenName")
    func studentInfoFullNameNilGiven() {
        let info = StudentInfo(
            id: "stu_1",
            grNumber: "GR001",
            givenName: nil,
            surname: "Potter",
            photoUrl: nil
        )
        #expect(info.fullName == "Potter")
    }

    @Test("StudentInfo fullName handles nil surname")
    func studentInfoFullNameNilSurname() {
        let info = StudentInfo(
            id: "stu_1",
            grNumber: "GR001",
            givenName: "Harry",
            surname: nil,
            photoUrl: nil
        )
        #expect(info.fullName == "Harry")
    }

    @Test("StudentInfo fullName handles both nil")
    func studentInfoFullNameBothNil() {
        let info = StudentInfo(
            id: "stu_1",
            grNumber: "GR001",
            givenName: nil,
            surname: nil,
            photoUrl: nil
        )
        #expect(info.fullName == "")
    }

    // MARK: - StudentFilters queryParams

    @Test("StudentFilters default queryParams")
    func filtersDefaultQueryParams() {
        let filters = StudentFilters()
        let params = filters.queryParams
        #expect(params["page"] == "1")
        #expect(params["pageSize"] == "20")
        #expect(params["sortBy"] == "givenName")
        #expect(params["sortOrder"] == "asc")
    }

    @Test("StudentFilters queryParams includes set fields")
    func filtersQueryParamsWithFields() {
        var filters = StudentFilters()
        filters.search = "Harry"
        filters.status = .active
        filters.yearLevelId = "yl_1"
        filters.batchId = "batch_1"
        let params = filters.queryParams
        #expect(params["search"] == "Harry")
        #expect(params["status"] == "ACTIVE")
        #expect(params["yearLevelId"] == "yl_1")
        #expect(params["batchId"] == "batch_1")
    }

    @Test("StudentFilters queryParams omits nil fields")
    func filtersQueryParamsOmitsNils() {
        let filters = StudentFilters()
        let params = filters.queryParams
        #expect(params["search"] == nil)
        #expect(params["status"] == nil)
        #expect(params["yearLevelId"] == nil)
        #expect(params["batchId"] == nil)
    }

    @Test("StudentFilters queryParams omits empty search")
    func filtersQueryParamsOmitsEmptySearch() {
        var filters = StudentFilters()
        filters.search = ""
        let params = filters.queryParams
        #expect(params["search"] == nil)
    }

    @Test("StudentFilters SortField rawValues")
    func sortFieldRawValues() {
        #expect(StudentFilters.SortField.name.rawValue == "givenName")
        #expect(StudentFilters.SortField.grNumber.rawValue == "grNumber")
        #expect(StudentFilters.SortField.createdAt.rawValue == "createdAt")
        #expect(StudentFilters.SortField.status.rawValue == "status")
    }

    // MARK: - StudentsValidation

    @Test("Validate GR number rejects empty")
    func validateGrNumberEmpty() {
        let result = StudentsValidation.validateGrNumber("")
        #expect(!result.isValid)
    }

    @Test("Validate GR number rejects too short")
    func validateGrNumberTooShort() {
        let result = StudentsValidation.validateGrNumber("AB")
        #expect(!result.isValid)
    }

    @Test("Validate GR number accepts valid")
    func validateGrNumberValid() {
        let result = StudentsValidation.validateGrNumber("GR001")
        #expect(result.isValid)
    }

    @Test("Validate given name rejects empty")
    func validateGivenNameEmpty() {
        let result = StudentsValidation.validateGivenName("")
        #expect(!result.isValid)
        #expect(result.errorMessage != nil)
    }

    @Test("Validate given name accepts valid name")
    func validateGivenNameValid() {
        let result = StudentsValidation.validateGivenName("Harry")
        #expect(result.isValid)
    }

    @Test("Validate surname rejects single char")
    func validateSurnameTooShort() {
        let result = StudentsValidation.validateSurname("P")
        #expect(!result.isValid)
    }

    @Test("Validate email accepts nil (optional)")
    func validateEmailNil() {
        let result = StudentsValidation.validateEmail(nil)
        #expect(result.isValid)
    }

    @Test("Validate email rejects invalid format")
    func validateEmailInvalid() {
        let result = StudentsValidation.validateEmail("not-an-email")
        #expect(!result.isValid)
    }

    @Test("Validate create form catches all errors")
    func validateCreateFormErrors() {
        let result = StudentsValidation.validateCreateForm(
            grNumber: "",
            givenName: "",
            surname: "",
            email: "bad-email",
            phone: nil,
            dateOfBirth: nil
        )
        #expect(!result.isValid)
        #expect(result.error(for: "grNumber") != nil)
        #expect(result.error(for: "givenName") != nil)
        #expect(result.error(for: "surname") != nil)
        #expect(result.error(for: "email") != nil)
    }

    @Test("Validate create form passes with valid data")
    func validateCreateFormValid() {
        let result = StudentsValidation.validateCreateForm(
            grNumber: "GR001",
            givenName: "Harry",
            surname: "Potter",
            email: "harry@hogwarts.edu",
            phone: nil,
            dateOfBirth: nil
        )
        #expect(result.isValid)
    }

    // MARK: - StudentsViewState

    @Test("StudentsViewState loading isLoading is true")
    func viewStateLoadingIsLoading() {
        let state = StudentsViewState.loading
        #expect(state.isLoading)
    }

    @Test("StudentsViewState idle isLoading is false")
    func viewStateIdleNotLoading() {
        let state = StudentsViewState.idle
        #expect(!state.isLoading)
    }

    @Test("StudentsViewState idle returns empty students array")
    func viewStateIdleEmptyStudents() {
        let state = StudentsViewState.idle
        #expect(state.students.isEmpty)
    }
}
