import SwiftUI

/// Main students view
/// Mirrors: src/components/platform/students/content.tsx
struct StudentsContent: View {
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = StudentsViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                StudentsToolbar(
                    searchText: $searchText,
                    filters: $viewModel.filters,
                    onSearch: { await viewModel.search(searchText) },
                    onFilter: { viewModel.filterByStatus($0) },
                    onCreate: { viewModel.showCreateForm() }
                )

                // Content
                Group {
                    switch viewModel.viewState {
                    case .idle, .loading:
                        LoadingView()

                    case .loaded:
                        StudentsTable(
                            rows: viewModel.rows,
                            onSelect: { row in
                                if let student = viewModel.students.first(where: { $0.id == row.id }) {
                                    viewModel.showEditForm(for: student)
                                }
                            },
                            onDelete: { rows in
                                let students = rows.compactMap { row in
                                    viewModel.students.first(where: { $0.id == row.id })
                                }
                                Task { await viewModel.deleteStudents(students) }
                            }
                        )
                        .refreshable {
                            await viewModel.refresh()
                        }

                    case .empty:
                        EmptyStateView(
                            title: String(localized: "student.empty.title"),
                            message: String(localized: "student.empty.message"),
                            systemImage: "person.2.slash",
                            action: {
                                viewModel.showCreateForm()
                            },
                            actionTitle: String(localized: "student.action.create")
                        )

                    case .error(let error):
                        ErrorStateView(
                            error: error,
                            retryAction: {
                                Task { await viewModel.loadStudents() }
                            }
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "students.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingForm) {
                StudentsForm(
                    mode: viewModel.formMode,
                    onSubmit: { request in
                        Task {
                            await viewModel.submitForm(request)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingForm = false
                    }
                )
            }
            .alert(
                "Error",
                isPresented: $viewModel.showError,
                presenting: viewModel.error
            ) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .task {
                viewModel.setup(tenantContext: tenantContext)
                await viewModel.loadStudents()
            }
        }
    }
}

// MARK: - Toolbar

struct StudentsToolbar: View {
    @Binding var searchText: String
    @Binding var filters: StudentFilters
    let onSearch: () async -> Void
    let onFilter: (StudentStatus?) -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(String(localized: "student.search.placeholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await onSearch() }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await onSearch() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: String(localized: "filter.all"),
                        isSelected: filters.status == nil,
                        action: { onFilter(nil) }
                    )

                    ForEach(StudentStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: filters.status == status,
                            action: { onFilter(status) }
                        )
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    StudentsContent()
        .environment(TenantContext())
}
