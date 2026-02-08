import Foundation
import Testing
@testable import Hogwarts

/// Tests for Email/Password Login (AUTH-003)
@Suite("Email/Password Login")
struct EmailPasswordTests {

    // MARK: - Email Validation

    @Test("Valid email passes validation")
    func validEmail() {
        let result = AuthValidation.validateEmail("user@example.com")
        #expect(result.isValid)
    }

    @Test("Empty email fails validation")
    func emptyEmail() {
        let result = AuthValidation.validateEmail("")
        #expect(!result.isValid)
        #expect(result.errorMessage != nil)
    }

    @Test("Email without @ fails validation")
    func emailWithoutAt() {
        let result = AuthValidation.validateEmail("userexample.com")
        #expect(!result.isValid)
    }

    @Test("Email without domain fails validation")
    func emailWithoutDomain() {
        let result = AuthValidation.validateEmail("user@")
        #expect(!result.isValid)
    }

    @Test("Email without TLD fails validation")
    func emailWithoutTLD() {
        let result = AuthValidation.validateEmail("user@example")
        #expect(!result.isValid)
    }

    @Test("Email with subdomain passes")
    func emailWithSubdomain() {
        let result = AuthValidation.validateEmail("user@mail.example.com")
        #expect(result.isValid)
    }

    // MARK: - Password Validation

    @Test("Non-empty password passes validation")
    func validPassword() {
        let result = AuthValidation.validatePassword("password123")
        #expect(result.isValid)
    }

    @Test("Empty password fails validation")
    func emptyPassword() {
        let result = AuthValidation.validatePassword("")
        #expect(!result.isValid)
        #expect(result.errorMessage != nil)
    }

    // MARK: - Form Validation

    @Test("Valid form passes validation")
    func validForm() {
        let result = AuthValidation.validateLoginForm(
            email: "user@example.com",
            password: "password"
        )
        #expect(result.isValid)
    }

    @Test("Form with invalid email fails")
    func formInvalidEmail() {
        let result = AuthValidation.validateLoginForm(
            email: "invalid",
            password: "password"
        )
        #expect(!result.isValid)
        #expect(!result.email.isValid)
        #expect(result.password.isValid)
    }

    @Test("Form with empty password fails")
    func formEmptyPassword() {
        let result = AuthValidation.validateLoginForm(
            email: "user@example.com",
            password: ""
        )
        #expect(!result.isValid)
        #expect(result.email.isValid)
        #expect(!result.password.isValid)
    }

    // MARK: - ValidationResult

    @Test("ValidationResult equality")
    func validationResultEquality() {
        #expect(ValidationResult.valid == ValidationResult.valid)
        #expect(ValidationResult.invalid("error") == ValidationResult.invalid("error"))
        #expect(ValidationResult.valid != ValidationResult.invalid("error"))
    }

    // MARK: - SignInRequest

    @Test("SignInRequest encodes correctly")
    func signInRequestEncoding() throws {
        let request = SignInRequest(email: "test@test.com", password: "secret")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["email"] as? String == "test@test.com")
        #expect(json?["password"] as? String == "secret")
    }
}
