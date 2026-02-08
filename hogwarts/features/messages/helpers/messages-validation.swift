import Foundation

/// Validation rules for Messages feature
/// Mirrors: src/components/platform/messages/validation.ts
struct MessagesValidation {

    /// Maximum message content length
    static let maxMessageLength = 5000

    /// Minimum message content length
    static let minMessageLength = 1

    /// Maximum conversation name length
    static let maxConversationNameLength = 100

    // MARK: - Validation Methods

    /// Validate message content
    static func validateMessage(_ content: String) -> ValidationResult {
        var errors: [String: String] = [:]

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors["content"] = String(localized: "messages.validation.empty")
        } else if trimmed.count > maxMessageLength {
            errors["content"] = String(localized: "messages.validation.tooLong")
        }

        return ValidationResult(errors: errors)
    }

    /// Validate new conversation
    static func validateNewConversation(
        recipientIds: [String],
        initialMessage: String?,
        name: String?
    ) -> ValidationResult {
        var errors: [String: String] = [:]

        if recipientIds.isEmpty {
            errors["recipients"] = String(localized: "messages.validation.noRecipients")
        }

        if let message = initialMessage {
            let messageResult = validateMessage(message)
            errors.merge(messageResult.errors) { _, new in new }
        }

        if let name, name.count > maxConversationNameLength {
            errors["name"] = String(localized: "messages.validation.nameTooLong")
        }

        return ValidationResult(errors: errors)
    }

    /// Simple validation result
    struct ValidationResult {
        let errors: [String: String]

        var isValid: Bool {
            errors.isEmpty
        }

        var firstError: String? {
            errors.values.first
        }
    }
}
