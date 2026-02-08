import LocalAuthentication
import SwiftUI

/// Biometric authentication service (Face ID / Touch ID)
/// Provides optional biometric lock for app access
@Observable
@MainActor
final class BiometricService {
    private let keychain = KeychainService()
    private let context = LAContext()

    /// Whether the device supports biometric authentication
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// The type of biometric available (Face ID or Touch ID)
    var biometricType: LABiometryType {
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Whether the user has enabled biometric unlock
    var isBiometricEnabled: Bool {
        keychain.get(.biometricEnabled) == "true"
    }

    /// Whether the app is currently unlocked
    var isUnlocked: Bool = false

    /// Display name for the biometric type
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return String(localized: "biometric.unknown")
        }
    }

    /// System image for the biometric type
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        @unknown default: return "lock"
        }
    }

    // MARK: - Enable/Disable

    /// Enable biometric unlock
    func enableBiometric() throws {
        try keychain.save("true", for: .biometricEnabled)
    }

    /// Disable biometric unlock
    func disableBiometric() {
        keychain.delete(.biometricEnabled)
        isUnlocked = true
    }

    // MARK: - Authentication

    /// Authenticate with biometrics
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "common.cancel")

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback: allow access if biometrics unavailable
            isUnlocked = true
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: String(localized: "biometric.reason")
            )
            isUnlocked = success
            return success
        } catch {
            return false
        }
    }

    /// Reset unlock state (e.g., on app background)
    func lock() {
        if isBiometricEnabled {
            isUnlocked = false
        }
    }
}

// MARK: - Biometric Prompt View

/// Shown when biometric unlock is required
struct BiometricPromptView: View {
    @Environment(BiometricService.self) private var biometricService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: biometricService.biometricIcon)
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text(String(localized: "biometric.unlockTitle"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "biometric.unlockMessage", defaultValue: "Authenticate to access Hogwarts"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await biometricService.authenticate() }
            } label: {
                Label(
                    String(localized: "biometric.unlock", defaultValue: "Unlock with \(biometricService.biometricName)"),
                    systemImage: biometricService.biometricIcon
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .task {
            await biometricService.authenticate()
        }
    }
}
