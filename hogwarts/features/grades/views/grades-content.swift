import SwiftUI

/// Main grades view
/// Mirrors: src/components/platform/grades/content.tsx
struct GradesContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = GradesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Role-based content
                Group {
                    if viewModel.capabilities.canEnterGrades {
                        TeacherGradesContent(viewModel: viewModel)
                    } else if viewModel.capabilities.canViewGrades {
                        StudentGradesContent(viewModel: viewModel)
                    } else {
                        NoAccessGradesContent()
                    }
                }
            }
            .navigationTitle(String(localized: "grades.title"))
            .toolbar {
                if viewModel.capabilities.canCreateExams {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                viewModel.showCreateExamForm()
                            } label: {
                                Label(String(localized: "grade.action.createExam"), systemImage: "plus.circle")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }

                if viewModel.capabilities.canViewReportCard {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showReportCard()
                        } label: {
                            Image(systemName: "doc.text")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingForm) {
                GradesForm(viewModel: viewModel)
                    .environment(tenantContext)
            }
            .sheet(isPresented: $viewModel.isShowingReportCard) {
                if let reportCard = viewModel.reportCard {
                    ReportCardView(reportCard: reportCard)
                } else {
                    LoadingView()
                }
            }
            .alert(
                String(localized: "error.title"),
                isPresented: $viewModel.showError,
                presenting: viewModel.error
            ) { _ in
                Button(String(localized: "common.ok")) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert(
                String(localized: "success.title"),
                isPresented: $viewModel.showSuccess
            ) {
                Button(String(localized: "common.ok")) {}
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .task {
                viewModel.setup(tenantContext: tenantContext, authManager: authManager)
                await viewModel.loadResults()
                if viewModel.capabilities.canEnterGrades {
                    await viewModel.loadExams()
                }
            }
        }
    }
}

// MARK: - Teacher Grades Content

struct TeacherGradesContent: View {
    @Bindable var viewModel: GradesViewModel
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker(String(localized: "grade.view"), selection: $selectedTab) {
                Text(String(localized: "grade.tab.exams")).tag(0)
                Text(String(localized: "grade.tab.results")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                // Exams list
                Group {
                    switch viewModel.examsState {
                    case .idle, .loading:
                        LoadingView()
                    case .loaded:
                        ExamListView(
                            exams: viewModel.exams,
                            onSelect: { exam in
                                viewModel.selectedExam = exam
                            },
                            onEnterMarks: { exam in
                                viewModel.showEnterMarksForm(for: exam)
                            }
                        )
                        .refreshable {
                            await viewModel.loadExams()
                        }
                    case .empty:
                        EmptyStateView(
                            title: String(localized: "grade.empty.exams.title"),
                            message: String(localized: "grade.empty.exams.message"),
                            systemImage: "doc.text",
                            action: { viewModel.showCreateExamForm() },
                            actionTitle: String(localized: "grade.action.createExam")
                        )
                    case .error(let error):
                        ErrorStateView(
                            error: error,
                            retryAction: { Task { await viewModel.loadExams() } }
                        )
                    }
                }
            } else {
                // Results list
                gradeResultsView
            }
        }
    }

    @ViewBuilder
    private var gradeResultsView: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                LoadingView()
            case .loaded:
                GradesTable(
                    rows: viewModel.rows,
                    onSelect: { _ in }
                )
                .refreshable {
                    await viewModel.refresh()
                }
            case .empty:
                EmptyStateView(
                    title: String(localized: "grade.empty.results.title"),
                    message: String(localized: "grade.empty.results.message"),
                    systemImage: "chart.bar"
                )
            case .error(let error):
                ErrorStateView(
                    error: error,
                    retryAction: { Task { await viewModel.loadResults() } }
                )
            }
        }
    }
}

// MARK: - Student Grades Content

struct StudentGradesContent: View {
    @Bindable var viewModel: GradesViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: String(localized: "filter.all"),
                        isSelected: viewModel.filters.examType == nil,
                        action: { viewModel.filterByExamType(nil) }
                    )

                    ForEach(ExamType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: viewModel.filters.examType == type,
                            action: { viewModel.filterByExamType(type) }
                        )
                    }
                }
            }
            .padding()

            // Results
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    LoadingView()
                case .loaded:
                    GradesTable(
                        rows: viewModel.rows,
                        onSelect: { _ in }
                    )
                    .refreshable {
                        await viewModel.refresh()
                    }
                case .empty:
                    EmptyStateView(
                        title: String(localized: "grade.empty.results.title"),
                        message: String(localized: "grade.empty.student.message"),
                        systemImage: "chart.bar"
                    )
                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: { Task { await viewModel.loadResults() } }
                    )
                }
            }
        }
    }
}

// MARK: - No Access

struct NoAccessGradesContent: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .padding()
            Text(String(localized: "grades.noAccess"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    GradesContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
