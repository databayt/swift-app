import SwiftUI

/// Empty state view for lists with no data
/// Mirrors: Empty state patterns in Hogwarts web
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(String(localized: "a11y.hint.tapToPerformAction"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(
        title: "No Students",
        message: "Add your first student to get started",
        systemImage: "person.2.slash",
        action: {},
        actionTitle: "Add Student"
    )
}
