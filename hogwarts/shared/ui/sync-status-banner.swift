import SwiftUI
import SwiftData

/// Banner showing offline/sync status
/// Shows when the device is offline or syncing
struct SyncStatusBanner: View {
    let networkMonitor = NetworkMonitor.shared

    @State private var lastSyncedAt: Date?

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text(String(localized: "sync.offline"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let lastSyncedAt {
                    Text(lastSyncedText(lastSyncedAt))
                        .font(.caption)
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red.opacity(0.9))
            .foregroundStyle(.white)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "a11y.sync.offlineBanner"))
            .task {
                loadLastSyncTime()
            }
        }
    }

    /// Format last synced time as relative string
    private func lastSyncedText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return String(localized: "sync.lastSynced \(formatter.localizedString(for: date, relativeTo: Date()))")
    }

    /// Query SyncMetadata for most recent sync time
    @MainActor
    private func loadLastSyncTime() {
        let context = DataContainer.shared.modelContext
        let descriptor = FetchDescriptor<SyncMetadata>(
            sortBy: [SortDescriptor(\.lastSyncedAt, order: .reverse)]
        )
        if let metadata = try? context.fetch(descriptor).first {
            lastSyncedAt = metadata.lastSyncedAt
        }
    }
}
