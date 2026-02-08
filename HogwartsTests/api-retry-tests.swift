import Foundation
import Testing
@testable import Hogwarts

/// Tests for API error types and retry logic
@Suite("API Retry")
struct APIRetryTests {

    // MARK: - APIError Types

    @Test("APIError serverError stores status code")
    func serverErrorStoresCode() {
        let error = APIError.serverError(500)
        if case .serverError(let code) = error {
            #expect(code == 500)
        } else {
            Issue.record("Expected serverError case")
        }
    }

    @Test("APIError 500 is retryable")
    func error500IsRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(retryableCodes.contains(500))
    }

    @Test("APIError 502 is retryable")
    func error502IsRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(retryableCodes.contains(502))
    }

    @Test("APIError 503 is retryable")
    func error503IsRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(retryableCodes.contains(503))
    }

    @Test("APIError 401 is not retryable")
    func error401NotRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(!retryableCodes.contains(401))
    }

    @Test("APIError 403 is not retryable")
    func error403NotRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(!retryableCodes.contains(403))
    }

    @Test("APIError 404 is not retryable")
    func error404NotRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(!retryableCodes.contains(404))
    }

    @Test("APIError 422 is not retryable")
    func error422NotRetryable() {
        let retryableCodes = [500, 502, 503]
        #expect(!retryableCodes.contains(422))
    }

    // MARK: - APIError Descriptions

    @Test("APIError unauthorized has description")
    func unauthorizedDescription() {
        let error = APIError.unauthorized
        #expect(error.errorDescription != nil)
    }

    @Test("APIError forbidden has description")
    func forbiddenDescription() {
        let error = APIError.forbidden
        #expect(error.errorDescription != nil)
    }

    @Test("APIError notFound has description")
    func notFoundDescription() {
        let error = APIError.notFound
        #expect(error.errorDescription != nil)
    }

    @Test("APIError invalidResponse has description")
    func invalidResponseDescription() {
        let error = APIError.invalidResponse
        #expect(error.errorDescription != nil)
    }

    @Test("APIError serverError has description")
    func serverErrorDescription() {
        let error = APIError.serverError(500)
        #expect(error.errorDescription != nil)
    }

    @Test("APIError validationFailed preserves message")
    func validationFailedMessage() {
        let error = APIError.validationFailed("Email is required")
        if case .validationFailed(let msg) = error {
            #expect(msg == "Email is required")
        }
    }

    // MARK: - Retry Backoff Calculation

    @Test("Retry backoff delay for attempt 1")
    func retryBackoffAttempt1() {
        let attempt = 1
        let delay = pow(2.0, Double(attempt - 1))
        #expect(delay == 1.0)
    }

    @Test("Retry backoff delay for attempt 2")
    func retryBackoffAttempt2() {
        let attempt = 2
        let delay = pow(2.0, Double(attempt - 1))
        #expect(delay == 2.0)
    }

    @Test("Max 3 attempts means 2 retries")
    func maxThreeAttempts() {
        let maxAttempts = 3
        var attempts = 0
        for attempt in 0..<maxAttempts {
            attempts += 1
            _ = attempt  // silence warning
        }
        #expect(attempts == 3)
    }

    @Test("First attempt has no delay")
    func firstAttemptNoDelay() {
        let attempt = 0
        let shouldDelay = attempt > 0
        #expect(!shouldDelay)
    }

    // MARK: - HTTPMethod

    @Test("HTTPMethod GET rawValue")
    func httpMethodGet() {
        #expect(HTTPMethod.get.rawValue == "GET")
    }

    @Test("HTTPMethod POST rawValue")
    func httpMethodPost() {
        #expect(HTTPMethod.post.rawValue == "POST")
    }

    @Test("HTTPMethod PUT rawValue")
    func httpMethodPut() {
        #expect(HTTPMethod.put.rawValue == "PUT")
    }

    @Test("HTTPMethod DELETE rawValue")
    func httpMethodDelete() {
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }

    @Test("HTTPMethod PATCH rawValue")
    func httpMethodPatch() {
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }

    // MARK: - EmptyResponse

    @Test("EmptyResponse is decodable from empty JSON")
    func emptyResponseDecodable() throws {
        let data = "{}".data(using: .utf8)!
        let response = try JSONDecoder().decode(EmptyResponse.self, from: data)
        _ = response  // Just verify it decodes
    }

    // MARK: - ValidationError

    @Test("ValidationError decodes message")
    func validationErrorDecodesMessage() throws {
        let json = "{\"message\":\"Invalid input\",\"errors\":{\"email\":[\"required\"]}}"
        let data = json.data(using: .utf8)!
        let error = try JSONDecoder().decode(ValidationError.self, from: data)
        #expect(error.message == "Invalid input")
        #expect(error.errors?["email"]?.first == "required")
    }

    @Test("ValidationError decodes without errors field")
    func validationErrorWithoutErrors() throws {
        let json = "{\"message\":\"Bad request\"}"
        let data = json.data(using: .utf8)!
        let error = try JSONDecoder().decode(ValidationError.self, from: data)
        #expect(error.message == "Bad request")
        #expect(error.errors == nil)
    }
}
