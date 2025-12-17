import SwiftUI

/// Loading indicator view
/// Used across all features for loading states
struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? String(localized: "common.loading"))
    }
}

/// Loading overlay modifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                LoadingView(message: message)
                    .background(.ultraThinMaterial)
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

#Preview {
    LoadingView(message: "Loading students...")
}
