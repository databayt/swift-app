import SwiftUI

/// School selection view shown after auth when user has multiple schools
/// Mirrors: src/app/[lang]/(auth)/select-school/page.tsx
struct SchoolSelectionView: View {
    @Environment(TenantContext.self) private var tenantContext

    @State private var viewModel = SchoolSelectionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.schools.isEmpty {
                    noSchoolView
                } else {
                    schoolList
                }
            }
            .navigationTitle(String(localized: "school.selection.title"))
            .task {
                await viewModel.loadSchools()
                autoSelectIfSingle()
            }
        }
    }

    @ViewBuilder
    private var schoolList: some View {
        List {
            ForEach(viewModel.schools) { school in
                Button {
                    viewModel.selectSchool(school, tenantContext: tenantContext)
                } label: {
                    HStack(spacing: 12) {
                        // School logo
                        AsyncImage(url: URL(string: school.logoUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // School info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(school.name)
                                .font(.headline)

                            if let nameAr = school.nameAr {
                                Text(nameAr)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Last used indicator
                        if school.id == viewModel.lastSchoolId {
                            Text(String(localized: "school.selection.lastUsed"))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var noSchoolView: some View {
        EmptyStateView(
            title: String(localized: "school.selection.noSchool"),
            message: String(localized: "school.selection.noSchoolMessage"),
            systemImage: "building.2"
        )
    }

    /// Auto-select if user has exactly one school
    private func autoSelectIfSingle() {
        if viewModel.schools.count == 1, let school = viewModel.schools.first {
            viewModel.selectSchool(school, tenantContext: tenantContext)
        }
    }
}

#Preview {
    SchoolSelectionView()
        .environment(TenantContext())
}
