import SwiftUI

/// Row for conversation list with avatar, name, preview, time, unread badge
/// Mirrors: src/components/platform/messages/conversation-row.tsx
struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            conversationAvatar
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.headline)
                        .fontWeight(conversation.hasUnread ? .bold : .regular)
                        .lineLimit(1)

                    Spacer()

                    // Time
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    // Preview
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundStyle(conversation.hasUnread ? .primary : .secondary)
                            .fontWeight(conversation.hasUnread ? .medium : .regular)
                            .lineLimit(1)
                    } else {
                        Text(String(localized: "messages.noMessages"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Unread badge
                    if conversation.hasUnread {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue)
                            .clipShape(Capsule())
                            .accessibilityLabel(String(localized: "a11y.label.unreadMessages \(conversation.unreadCount)"))
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var conversationAvatar: some View {
        if conversation.isGroup {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
            }
            .frame(width: 44, height: 44)
        } else {
            let imageUrl = conversation.participants?.first?.imageUrl
            AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        }
    }
}
