import SwiftUI

/// Message bubble — incoming (left) / outgoing (right), RTL-aware
/// Mirrors: src/components/platform/messages/message-bubble.tsx
struct MessageBubble: View {
    let message: Message
    let isOutgoing: Bool

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOutgoing {
                Spacer(minLength: 60)
            } else {
                // Sender avatar
                AsyncImage(url: URL(string: message.senderImageUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(.secondary)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .accessibilityHidden(true)
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                // Sender name (incoming only)
                if !isOutgoing {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Bubble
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOutgoing ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isOutgoing ? .white : .primary)
                    .clipShape(BubbleShape(isOutgoing: isOutgoing))

                // Time
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "a11y.label.sentAt \(message.createdAt.formatted(date: .abbreviated, time: .shortened))"))
            }

            if !isOutgoing {
                Spacer(minLength: 60)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Bubble Shape

/// Custom bubble shape with tail
struct BubbleShape: Shape {
    let isOutgoing: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        var path = Path()

        if isOutgoing {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height),
                cornerRadii: RectangleCornerRadii(
                    topLeading: radius,
                    bottomLeading: radius,
                    bottomTrailing: 4,
                    topTrailing: radius
                )
            )
        } else {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height),
                cornerRadii: RectangleCornerRadii(
                    topLeading: radius,
                    bottomLeading: 4,
                    bottomTrailing: radius,
                    topTrailing: radius
                )
            )
        }

        return path
    }
}
