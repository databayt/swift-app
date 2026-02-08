import Foundation
import Testing
@testable import Hogwarts

/// Tests for Facebook OAuth Sign-In (AUTH-002)
@Suite("Facebook OAuth")
struct FacebookOAuthTests {

    @Test("OAuth request uses correct provider")
    func oauthRequestProvider() {
        let request = OAuthSignInRequest(provider: "facebook", token: "fb-access-token")
        #expect(request.provider == "facebook")
        #expect(request.token == "fb-access-token")
    }

    @Test("Facebook OAuth request encodes to JSON")
    func facebookRequestEncodable() throws {
        let request = OAuthSignInRequest(provider: "facebook", token: "fb-token-456")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["provider"] as? String == "facebook")
        #expect(json?["token"] as? String == "fb-token-456")
    }

    @Test("Google and Facebook use different providers")
    func differentProviders() {
        let google = OAuthSignInRequest(provider: "google", token: "g-token")
        let facebook = OAuthSignInRequest(provider: "facebook", token: "fb-token")
        #expect(google.provider != facebook.provider)
    }

    @Test("Session user role parses correctly")
    func sessionUserRole() throws {
        let json = """
        {
            "user": {
                "id": "user-2",
                "email": "teacher@test.com",
                "name": "Teacher Test",
                "role": "TEACHER"
            },
            "schoolId": "school-456",
            "accessToken": "jwt-token-2"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(Session.self, from: json)
        #expect(session.user.userRole == .teacher)
    }
}
