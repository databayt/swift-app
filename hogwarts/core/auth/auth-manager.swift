import SwiftUI
import AuthenticationServices

/// Authentication manager
/// Mirrors: src/auth.ts + src/auth.config.ts
@Observable
@MainActor
final class AuthManager {
    private let keychain = KeychainService()
    private let api = APIClient.shared

    /// Current authenticated user
    var currentUser: User?

    /// Current session
    var session: Session?

    /// Current session state
    var sessionState: SessionState = .unauthenticated

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        sessionState == .authenticated && currentUser != nil
    }

    /// Get access token from keychain
    var accessToken: String? {
        keychain.get(.accessToken)
    }

    /// User role
    var role: UserRole {
        currentUser?.userRole ?? .user
    }

    init() {
        Task { await wireUnauthorizedHandler() }
    }

    /// Wire up 401 handler on APIClient
    private func wireUnauthorizedHandler() async {
        await api.setOnUnauthorized { [weak self] in
            await MainActor.run {
                self?.handleUnauthorized()
            }
        }
    }

    /// Handle 401 response — sign out immediately
    private func handleUnauthorized() {
        signOut()
    }

    // MARK: - Sign In Methods

    /// Sign in with email/password
    /// Mirrors: signIn("credentials") in NextAuth
    func signIn(email: String, password: String) async throws -> Session {
        let request = SignInRequest(email: email, password: password)

        // Mock data for demo/testing (when backend is unavailable)
        if password == "1234" {
            let mockUser = User(
                id: UUID().uuidString,
                email: email,
                name: email.split(separator: "@").first.map(String.init) ?? "User",
                nameAr: nil,
                role: "student",
                schoolId: "demo-school",
                imageUrl: nil,
                phone: nil,
                emailVerified: Date(),
                isTwoFactorEnabled: false,
                createdAt: Date(),
                updatedAt: Date()
            )

            let mockSession = Session(
                user: mockUser,
                schoolId: "demo-school",
                accessToken: "mock_token_\(UUID().uuidString)",
                refreshToken: nil,
                expiresAt: Date().addingTimeInterval(86400)
            )

            try saveSession(mockSession)
            return mockSession
        }

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
        self.sessionState = .authenticated
    }

    /// Restore session on app launch
    /// Validates cached token, refreshes if near expiry, clears if expired
    func restoreSession() async {
        guard let token = accessToken else {
            sessionState = .unauthenticated
            return
        }

        // Decode JWT to check expiry
        if let payload = TokenPayload.decode(from: token) {
            if payload.isExpired {
                // Token expired — try refresh
                do {
                    try await refreshToken()
                    return
                } catch {
                    signOut()
                    return
                }
            }

            if payload.shouldRefresh() {
                // Token near expiry — proactive refresh
                try? await refreshToken()
            }
        }

        // Token still valid — fetch session from server
        do {
            let session = try await api.get("/auth/session", as: Session.self)
            self.session = session
            self.currentUser = session.user
            self.sessionState = .authenticated
        } catch {
            signOut()
        }
    }

    /// Refresh the access token using the refresh token
    func refreshToken() async throws {
        guard let refresh = keychain.get(.refreshToken) else {
            throw AuthError.refreshFailed
        }

        let request = RefreshTokenRequest(refreshToken: refresh)

        do {
            let session = try await api.post("/auth/refresh", body: request, as: Session.self)
            try saveSession(session)
        } catch {
            throw AuthError.refreshFailed
        }
    }

    /// Ensure token is fresh before an API call (proactive refresh)
    func ensureFreshToken() async {
        guard let token = accessToken,
              let payload = TokenPayload.decode(from: token),
              payload.shouldRefresh() else {
            return
        }

        try? await refreshToken()
    }

    /// Sign out — clear all auth state
    func signOut() {
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        currentUser = nil
        session = nil
        sessionState = .unauthenticated
    }
}
