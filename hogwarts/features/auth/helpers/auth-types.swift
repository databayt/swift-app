import Foundation

// MARK: - Session

/// Authenticated session from API
/// Mirrors: NextAuth session object
struct Session: Codable {
    let user: User
    let schoolId: String?
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

// MARK: - Request Types

struct SignInRequest: Encodable {
    let email: String
    let password: String
}

struct OAuthSignInRequest: Encodable {
    let provider: String
    let token: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

// MARK: - Session State

enum SessionState {
    case authenticated
    case expired
    case unauthenticated
}

// MARK: - Token Payload

/// Decoded JWT payload (base64 decode, no external library)
struct TokenPayload {
    let sub: String
    let exp: Date
    let schoolId: String?

    /// Token is expired
    var isExpired: Bool {
        Date() >= exp
    }

    /// Token should be proactively refreshed (at 80% of lifetime)
    /// Uses iat if available, otherwise assumes 1-hour lifetime
    func shouldRefresh(issuedAt: Date? = nil) -> Bool {
        let now = Date()
        let issueDate = issuedAt ?? exp.addingTimeInterval(-3600)
        let lifetime = exp.timeIntervalSince(issueDate)
        let elapsed = now.timeIntervalSince(issueDate)
        return elapsed >= lifetime * 0.8
    }

    /// Decode a JWT access token into TokenPayload
    /// JWT format: header.payload.signature (base64url encoded)
    static func decode(from jwt: String) -> TokenPayload? {
        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else { return nil }

        let payloadSegment = String(segments[1])
        guard let data = base64URLDecode(payloadSegment) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String,
              let expValue = json["exp"] as? TimeInterval else {
            return nil
        }

        let exp = Date(timeIntervalSince1970: expValue)
        let schoolId = json["schoolId"] as? String

        return TokenPayload(sub: sub, exp: exp, schoolId: schoolId)
    }

    /// Base64URL decode (JWT uses URL-safe base64 without padding)
    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(contentsOf: String(repeating: "=", count: 4 - remainder))
        }

        return Data(base64Encoded: base64)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case unauthorized
    case sessionExpired
    case refreshFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return String(localized: "auth.error.invalidCredentials")
        case .unauthorized:
            return String(localized: "auth.error.unauthorized")
        case .sessionExpired:
            return String(localized: "session_expired")
        case .refreshFailed:
            return String(localized: "auth.error.refreshFailed")
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
