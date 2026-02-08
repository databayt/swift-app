import Foundation
import Testing
@testable import Hogwarts

// MARK: - Token Payload Tests

@Suite("Session Management")
struct SessionManagementTests {

    // MARK: - JWT Decode

    @Test("Token payload decodes correctly from JWT")
    func tokenPayloadDecodesCorrectly() {
        // JWT with payload: {"sub":"user_123","exp":4102444800,"schoolId":"school_456"}
        // exp = 2100-01-01T00:00:00Z (far future)
        let header = base64URLEncode(#"{"alg":"HS256","typ":"JWT"}"#)
        let payload = base64URLEncode(#"{"sub":"user_123","exp":4102444800,"schoolId":"school_456"}"#)
        let jwt = "\(header).\(payload).fakesignature"

        let decoded = TokenPayload.decode(from: jwt)

        #expect(decoded != nil)
        #expect(decoded?.sub == "user_123")
        #expect(decoded?.schoolId == "school_456")
        #expect(decoded?.exp == Date(timeIntervalSince1970: 4102444800))
    }

    @Test("Token payload returns nil for invalid JWT")
    func tokenPayloadReturnsNilForInvalid() {
        #expect(TokenPayload.decode(from: "not.a.valid.jwt") == nil)
        #expect(TokenPayload.decode(from: "") == nil)
        #expect(TokenPayload.decode(from: "onlyone") == nil)
    }

    // MARK: - Expiry Detection

    @Test("Token payload detects expired token")
    func tokenPayloadDetectsExpiry() {
        // Token that expired in the past
        let header = base64URLEncode(#"{"alg":"HS256","typ":"JWT"}"#)
        let payload = base64URLEncode(#"{"sub":"user_123","exp":1000000000}"#)
        let jwt = "\(header).\(payload).sig"

        let decoded = TokenPayload.decode(from: jwt)

        #expect(decoded != nil)
        #expect(decoded?.isExpired == true)
    }

    @Test("Token payload detects valid (non-expired) token")
    func tokenPayloadDetectsValid() {
        let header = base64URLEncode(#"{"alg":"HS256","typ":"JWT"}"#)
        let payload = base64URLEncode(#"{"sub":"user_123","exp":4102444800}"#)
        let jwt = "\(header).\(payload).sig"

        let decoded = TokenPayload.decode(from: jwt)

        #expect(decoded != nil)
        #expect(decoded?.isExpired == false)
    }

    // MARK: - Proactive Refresh

    @Test("Token should refresh at 80% lifetime")
    func tokenPayloadShouldRefreshAt80Percent() {
        let now = Date()

        // Token issued 50 minutes ago, expires in 10 minutes (1 hour total)
        // 50/60 = 83% elapsed => should refresh
        let issuedAt = now.addingTimeInterval(-3000) // 50 min ago
        let expiresAt = now.addingTimeInterval(600)   // 10 min from now

        let payload = TokenPayload(sub: "user_123", exp: expiresAt, schoolId: nil)
        #expect(payload.shouldRefresh(issuedAt: issuedAt) == true)
    }

    @Test("Token should NOT refresh when fresh")
    func tokenPayloadShouldNotRefreshWhenFresh() {
        let now = Date()

        // Token issued 10 minutes ago, expires in 50 minutes (1 hour total)
        // 10/60 = 16% elapsed => should NOT refresh
        let issuedAt = now.addingTimeInterval(-600)  // 10 min ago
        let expiresAt = now.addingTimeInterval(3000) // 50 min from now

        let payload = TokenPayload(sub: "user_123", exp: expiresAt, schoolId: nil)
        #expect(payload.shouldRefresh(issuedAt: issuedAt) == false)
    }

    // MARK: - Session State

    @Test("SessionState enum has correct cases")
    func sessionStateEnum() {
        let auth: SessionState = .authenticated
        let expired: SessionState = .expired
        let unauth: SessionState = .unauthenticated

        // Verify all three cases exist and are distinct
        switch auth {
        case .authenticated: break
        case .expired: Issue.record("Should be authenticated")
        case .unauthenticated: Issue.record("Should be authenticated")
        }

        switch expired {
        case .expired: break
        default: Issue.record("Should be expired")
        }

        switch unauth {
        case .unauthenticated: break
        default: Issue.record("Should be unauthenticated")
        }
    }

    // MARK: - Auth Error

    @Test("AuthError cases are distinct")
    func authErrorCases() {
        let expired = AuthError.sessionExpired
        let refresh = AuthError.refreshFailed
        let creds = AuthError.invalidCredentials

        #expect(expired.errorDescription != nil)
        #expect(refresh.errorDescription != nil)
        #expect(creds.errorDescription != nil)
    }

    // MARK: - Helpers

    /// Base64URL-encode a string (matching JWT format)
    private func base64URLEncode(_ string: String) -> String {
        Data(string.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
