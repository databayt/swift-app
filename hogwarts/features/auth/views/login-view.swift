import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FacebookLogin

/// Login view
/// Mirrors: src/app/[lang]/(auth)/login/page.tsx
struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: LoginField?

    enum LoginField {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)

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
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(String(localized: "login.email"), text: $viewModel.email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .onChange(of: viewModel.email) { viewModel.onEmailChanged() }
                                .accessibilityLabel(String(localized: "a11y.login.email"))
                                .accessibilityHint(String(localized: "a11y.hint.enterEmail"))

                            if let emailError = viewModel.emailError {
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField(String(localized: "login.password"), text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { submitForm() }
                                .onChange(of: viewModel.password) { viewModel.onPasswordChanged() }
                                .accessibilityLabel(String(localized: "a11y.login.password"))
                                .accessibilityHint(String(localized: "a11y.hint.enterPassword"))

                            if let passwordError = viewModel.passwordError {
                                Text(passwordError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        // Login button
                        Button {
                            submitForm()
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(String(localized: "login.signIn"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSubmit ? Color.accentColor : Color.accentColor.opacity(0.5))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(!viewModel.canSubmit)
                        .accessibilityLabel(String(localized: "a11y.button.signIn"))
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
                        .disabled(viewModel.isLoading)
                        .accessibilityLabel(String(localized: "a11y.button.continueGoogle"))

                        // Facebook Sign In
                        Button {
                            signInWithFacebook()
                        } label: {
                            HStack {
                                Image(systemName: "f.square.fill")
                                Text(String(localized: "login.continueWithFacebook"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.23, green: 0.35, blue: 0.60))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(viewModel.isLoading)
                        .accessibilityLabel(String(localized: "a11y.button.continueFacebook"))

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
                isPresented: $viewModel.showError,
                presenting: viewModel.error
            ) { _ in
                Button(String(localized: "common.ok")) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Methods

    private func submitForm() {
        focusedField = nil
        Task {
            await viewModel.login(authManager: authManager, tenantContext: tenantContext)
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        viewModel.isLoading = true

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            // Extract token on callback thread before crossing actor boundary
            let idToken = result?.user.idToken?.tokenString
            let callbackError = error

            Task { @MainActor [viewModel, authManager, tenantContext] in
                if let callbackError {
                    viewModel.isLoading = false
                    if (callbackError as NSError).code == GIDSignInError.canceled.rawValue { return }
                    viewModel.error = callbackError
                    viewModel.showError = true
                    return
                }

                guard let idToken else {
                    viewModel.isLoading = false
                    viewModel.error = AuthError.invalidCredentials
                    viewModel.showError = true
                    return
                }

                do {
                    let session = try await authManager.signInWithGoogle(idToken: idToken)
                    if let schoolId = session.schoolId {
                        tenantContext.setTenant(schoolId: schoolId)
                    }
                } catch {
                    viewModel.error = error
                    viewModel.showError = true
                }
                viewModel.isLoading = false
            }
        }
    }

    private func signInWithFacebook() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        viewModel.isLoading = true

        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["email", "public_profile"], from: rootVC) { result, error in
            // Extract token on callback thread before crossing actor boundary
            let isCancelled = result?.isCancelled ?? true
            let token = AccessToken.current?.tokenString
            let callbackError = error

            Task { @MainActor [viewModel, authManager, tenantContext] in
                if let callbackError {
                    viewModel.isLoading = false
                    viewModel.error = callbackError
                    viewModel.showError = true
                    return
                }

                guard !isCancelled, let token else {
                    viewModel.isLoading = false
                    return
                }

                do {
                    let session = try await authManager.signInWithFacebook(accessToken: token)
                    if let schoolId = session.schoolId {
                        tenantContext.setTenant(schoolId: schoolId)
                    }
                } catch {
                    viewModel.error = error
                    viewModel.showError = true
                }
                viewModel.isLoading = false
            }
        }
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
                    viewModel.error = error
                    viewModel.showError = true
                }
            }
        case .failure(let error):
            viewModel.error = error
            viewModel.showError = true
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
        .environment(TenantContext())
}
