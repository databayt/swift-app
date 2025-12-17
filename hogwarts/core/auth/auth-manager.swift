import SwiftUI
import AuthenticationServices

/// Authentication manager
/// Mirrors: src/auth.ts + src/auth.config.ts
@Observable
final class AuthManager {
    private let keychain = KeychainService()
    private let api = APIClient.shared

    /// Current authenticated user
    var currentUser: User?

    /// Current session
    var session: Session?

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        accessToken != nil && currentUser != nil
    }

    /// Get access token from keychain
    var accessToken: String? {
        keychain.get(.accessToken)
    }

    /// User role
    var role: UserRole {
        currentUser?.userRole ?? .user
    }

    // MARK: - Sign In Methods

    /// Sign in with email/password
    /// Mirrors: signIn("credentials") in NextAuth
    func signIn(email: String, password: String) async throws -> Session {
        let request = SignInRequest(email: email, password: password)
        let session = try await api.post("/auth/signin", body: request, as: Session.self)

        try saveSession(session)
        return session
    }

    /// Sign in with Google
    /// Mirrors: signIn("google") in NextAuth
    func signInWithGoogle(idToken: String) async throws -> Session {
        let request = OAuthSignInRequest(provider: "google", token: idToken)
        let session = try await api.post("/auth/callback/google", body: request, as: Session.self)

        try saveSession(session)
        return session
    }

    /// Sign in with Facebook
    /// Mirrors: signIn("facebook") in NextAuth
    func signInWithFacebook(accessToken: String) async throws -> Session {
        let request = OAuthSignInRequest(provider: "facebook", token: accessToken)
        let session = try await api.post("/auth/callback/facebook", body: request, as: Session.self)

        try saveSession(session)
        return session
    }

    /// Sign in with Apple
    func signInWithApple(authorization: ASAuthorization) async throws -> Session {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        let request = OAuthSignInRequest(provider: "apple", token: tokenString)
        let session = try await api.post("/auth/callback/apple", body: request, as: Session.self)

        try saveSession(session)
        return session
    }

    // MARK: - Session Management

    /// Save session to keychain
    private func saveSession(_ session: Session) throws {
        try keychain.save(session.accessToken, for: .accessToken)
        if let refreshToken = session.refreshToken {
            try keychain.save(refreshToken, for: .refreshToken)
        }

        self.session = session
        self.currentUser = session.user
    }

    /// Restore session on app launch
    func restoreSession() async {
        guard let token = accessToken else { return }

        do {
            let session = try await api.get("/auth/session", as: Session.self)
            self.session = session
            self.currentUser = session.user
        } catch {
            // Token invalid, clear session
            signOut()
        }
    }

    /// Sign out
    func signOut() {
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        currentUser = nil
        session = nil
    }
}

// MARK: - Request/Response Types

struct SignInRequest: Encodable {
    let email: String
    let password: String
}

struct OAuthSignInRequest: Encodable {
    let provider: String
    let token: String
}

struct Session: Codable {
    let user: User
    let schoolId: String?
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case unauthorized
    case sessionExpired
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return String(localized: "auth.error.invalidCredentials")
        case .unauthorized:
            return String(localized: "auth.error.unauthorized")
        case .sessionExpired:
            return String(localized: "auth.error.sessionExpired")
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
