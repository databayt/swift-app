import Foundation
import Testing
@testable import Hogwarts

/// Tests for Google OAuth Sign-In (AUTH-001)
@Suite("Google OAuth")
struct GoogleOAuthTests {

    @Test("OAuth request uses correct provider")
    func oauthRequestProvider() {
        let request = OAuthSignInRequest(provider: "google", token: "test-id-token")
        #expect(request.provider == "google")
        #expect(request.token == "test-id-token")
    }

    @Test("OAuth request is encodable to JSON")
    func oauthRequestEncodable() throws {
        let request = OAuthSignInRequest(provider: "google", token: "id-token-123")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["provider"] as? String == "google")
        #expect(json?["token"] as? String == "id-token-123")
    }

    @Test("Session decodes with schoolId")
    func sessionDecodeWithSchool() throws {
        let json = """
        {
            "user": {
                "id": "user-1",
                "email": "test@example.com",
                "name": "Test User",
                "role": "STUDENT"
            },
            "schoolId": "school-123",
            "accessToken": "jwt-token",
            "refreshToken": "refresh-token"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(Session.self, from: json)
        #expect(session.schoolId == "school-123")
        #expect(session.user.email == "test@example.com")
        #expect(session.accessToken == "jwt-token")
    }

    @Test("Session decodes without schoolId")
    func sessionDecodeWithoutSchool() throws {
        let json = """
        {
            "user": {
                "id": "user-1",
                "email": "test@example.com",
                "name": "Test User",
                "role": "USER"
            },
            "accessToken": "jwt-token"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(Session.self, from: json)
        #expect(session.schoolId == nil)
        #expect(session.refreshToken == nil)
    }

    @Test("AuthError has localized descriptions")
    func authErrorDescriptions() {
        let errors: [AuthError] = [
            .invalidCredentials,
            .unauthorized,
            .sessionExpired,
            .refreshFailed,
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }
}
