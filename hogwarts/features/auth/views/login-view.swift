import SwiftUI
import AuthenticationServices

/// Login view
/// Mirrors: src/app/[lang]/(auth)/login/page.tsx
struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.accentColor)

                        Text("Hogwarts")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(String(localized: "login.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Login form
                    VStack(spacing: 16) {
                        // Email field
                        TextField(String(localized: "login.email"), text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        // Password field
                        SecureField(String(localized: "login.password"), text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        // Login button
                        Button {
                            login()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(String(localized: "login.signIn"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text(String(localized: "login.or"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Social login
                    VStack(spacing: 12) {
                        // Google Sign In
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text(String(localized: "login.continueWithGoogle"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .alert(
                String(localized: "error.title"),
                isPresented: $showError,
                presenting: error
            ) { _ in
                Button(String(localized: "common.ok")) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Methods

    private func login() {
        isLoading = true

        Task {
            do {
                let session = try await authManager.signIn(email: email, password: password)
                if let schoolId = session.schoolId {
                    tenantContext.setTenant(schoolId: schoolId)
                }
            } catch {
                self.error = error
                showError = true
            }

            isLoading = false
        }
    }

    private func signInWithGoogle() {
        // Implement Google Sign-In
        // This requires GoogleSignIn SDK setup
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    let session = try await authManager.signInWithApple(authorization: authorization)
                    if let schoolId = session.schoolId {
                        tenantContext.setTenant(schoolId: schoolId)
                    }
                } catch {
                    self.error = error
                    showError = true
                }
            }
        case .failure(let error):
            self.error = error
            showError = true
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
        .environment(TenantContext())
}
