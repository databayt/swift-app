import Foundation
import Security

/// Secure storage using Keychain
/// Stores sensitive data like JWT tokens
final class KeychainService {

    enum Key: String {
        case accessToken = "com.hogwarts.accessToken"
        case refreshToken = "com.hogwarts.refreshToken"
        case deviceToken = "com.hogwarts.deviceToken"
        case lastSchoolId = "com.hogwarts.lastSchoolId"
        case biometricEnabled = "com.hogwarts.biometricEnabled"
    }

    private let serviceName = "com.hogwarts.ios"

    // MARK: - Public Methods

    /// Save value to keychain
    func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)

        // Delete existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Get value from keychain
    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Delete value from keychain
    func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// Clear all keychain items
    func clearAll() {
        Key.allCases.forEach { delete($0) }
    }
}

extension KeychainService.Key: CaseIterable {}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed: \(status)"
        case .readFailed(let status):
            return "Keychain read failed: \(status)"
        }
    }
}
