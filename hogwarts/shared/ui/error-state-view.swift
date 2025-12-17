import SwiftUI

/// Error state view with retry action
/// Used when data loading fails
struct ErrorStateView: View {
    let error: Error
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text(String(localized: "error.title"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label(String(localized: "common.retry"), systemImage: "arrow.clockwise")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorStateView(
        error: APIError.serverError(500),
        retryAction: {}
    )
}
