import SwiftUI

/// Banner showing offline/sync status
/// Shows when the device is offline or syncing
struct SyncStatusBanner: View {
    let networkMonitor = NetworkMonitor.shared

    @State private var isVisible = false

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text(String(localized: "sync.offline"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red.opacity(0.9))
            .foregroundStyle(.white)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "a11y.sync.offlineBanner"))
        }
    }
}
