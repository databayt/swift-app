import SwiftUI

/// Horizontal child selector for guardian dashboard
/// Shows avatars/names of guardian's children, single child shows as header
struct ChildSelector: View {
    let children: [DashboardChild]
    let selectedChild: DashboardChild?
    let onSelect: (DashboardChild) -> Void

    var body: some View {
        if children.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(children) { child in
                        childButton(child)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func childButton(_ child: DashboardChild) -> some View {
        let isSelected = selectedChild?.id == child.id

        return Button {
            onSelect(child)
        } label: {
            VStack(spacing: 6) {
                // Avatar
                AsyncImage(url: URL(string: child.imageUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                )

                // Name
                Text(child.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
    }
}
