import SwiftUI

/// New conversation with recipient picker
/// Mirrors: src/components/platform/messages/compose.tsx
struct ComposeMessageView: View {
    let onConversationCreated: (Conversation) -> Void

    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedRecipients: [Recipient] = []
    @State private var messageText = ""
    @State private var recipients: [Recipient] = []
    @State private var isLoading = false
    @State private var isSending = false
    @State private var error: Error?
    @State private var showError = false

    private let actions = MessagesActions()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected recipients
                if !selectedRecipients.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedRecipients) { recipient in
                                HStack(spacing: 4) {
                                    Text(recipient.displayName)
                                        .font(.caption)

                                    Button {
                                        selectedRecipients.removeAll { $0.id == recipient.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityLabel(String(localized: "a11y.button.removeRecipient \(recipient.displayName)"))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    Divider()
                }

                // Recipient search
                List {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(filteredRecipients) { recipient in
                            Button {
                                toggleRecipient(recipient)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: recipient.imageUrl ?? "")) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recipient.displayName)
                                            .font(.subheadline)
                                        if let role = recipient.role {
                                            Text(role)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedRecipients.contains(recipient) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(
                    text: $searchText,
                    prompt: String(localized: "messages.searchRecipients")
                )
                .accessibilityLabel(String(localized: "a11y.field.recipientSearch"))
                .accessibilityHint(String(localized: "a11y.hint.searchForRecipients"))

                Divider()

                // Message input
                HStack(spacing: 12) {
                    TextField(
                        String(localized: "messages.firstMessage"),
                        text: $messageText,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(String(localized: "a11y.field.messageInput"))
                    .accessibilityHint(String(localized: "a11y.hint.typeFirstMessage"))

                    Button {
                        Task { await createConversation() }
                    } label: {
                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(!canSend)
                    .tint(.blue)
                    .accessibilityLabel(String(localized: "a11y.button.sendMessage"))
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle(String(localized: "messages.newMessage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
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
            .task {
                await loadRecipients()
            }
            .onChange(of: searchText) { _, newValue in
                Task { await loadRecipients(search: newValue) }
            }
        }
    }

    // MARK: - Computed

    private var filteredRecipients: [Recipient] {
        recipients.filter { recipient in
            !selectedRecipients.contains(recipient)
        }
    }

    private var canSend: Bool {
        !selectedRecipients.isEmpty &&
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending
    }

    // MARK: - Actions

    private func loadRecipients(search: String? = nil) async {
        guard let schoolId = tenantContext.schoolId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            recipients = try await actions.getRecipients(
                schoolId: schoolId,
                search: search
            )
        } catch {
            self.error = error
            showError = true
        }
    }

    private func toggleRecipient(_ recipient: Recipient) {
        if let index = selectedRecipients.firstIndex(of: recipient) {
            selectedRecipients.remove(at: index)
        } else {
            selectedRecipients.append(recipient)
        }
    }

    private func createConversation() async {
        guard let schoolId = tenantContext.schoolId else { return }

        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let participantIds = selectedRecipients.map(\.id)

        // Validate
        let validation = MessagesValidation.validateNewConversation(
            recipientIds: participantIds,
            initialMessage: content,
            name: nil
        )

        guard validation.isValid else {
            error = MessagesError.validationFailed(validation.errors)
            showError = true
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let conversation = try await actions.createConversation(
                participantIds: participantIds,
                isGroup: selectedRecipients.count > 1,
                initialMessage: content,
                schoolId: schoolId
            )

            onConversationCreated(conversation)
        } catch {
            self.error = error
            showError = true
        }
    }
}
