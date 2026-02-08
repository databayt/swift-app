import SwiftUI

/// Row for notification list with type icon, title, message, time, read indicator
/// Mirrors: src/components/platform/notifications/notification-row.tsx
struct NotificationRow: View {
    let notification: AppNotification

    private var type: NotificationType {
        notification.notificationType
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                Image(systemName: type.icon)
                    .font(.caption)
                    .foregroundStyle(type.color)
            }
            .frame(width: 36, height: 36)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .lineLimit(1)

                    Spacer()

                    Text(notification.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Type badge
                Text(type.label)
                    .font(.system(size: 10))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(type.color.opacity(0.1))
                    .foregroundStyle(type.color)
                    .clipShape(Capsule())
            }

            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .opacity(notification.isRead ? 0.7 : 1.0)
    }
}
