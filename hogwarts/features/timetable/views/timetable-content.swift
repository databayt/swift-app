import SwiftUI

/// Main timetable view
/// Mirrors: src/components/platform/timetable/content.tsx
struct TimetableContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = TimetableViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Display mode toggle
                Picker(String(localized: "timetable.view.mode"), selection: $viewModel.displayMode) {
                    ForEach(TimetableDisplayMode.allCases, id: \.self) { mode in
                        Label(mode.label, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: viewModel.displayMode) { _, _ in
                    Task { await viewModel.refresh() }
                }

                // Term info
                if let termName = viewModel.termName {
                    Text(termName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }

                Divider()

                // Content
                Group {
                    switch viewModel.viewState {
                    case .idle, .loading:
                        LoadingView()

                    case .loaded:
                        if viewModel.displayMode == .week {
                            TimetableWeekView(viewModel: viewModel)
                        } else {
                            TimetableDayView(viewModel: viewModel)
                        }

                    case .empty:
                        EmptyStateView(
                            title: String(localized: "timetable.empty.title"),
                            message: String(localized: "timetable.empty.message"),
                            systemImage: "calendar"
                        )

                    case .error(let error):
                        ErrorStateView(
                            error: error,
                            retryAction: {
                                Task { await viewModel.refresh() }
                            }
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "timetable.title"))
            .sheet(isPresented: $viewModel.isShowingClassDetail) {
                if let detail = viewModel.classDetail {
                    ClassDetailView(
                        classDetail: detail,
                        capabilities: viewModel.capabilities
                    )
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
            .task {
                viewModel.setup(tenantContext: tenantContext, authManager: authManager)
                await viewModel.loadWeeklySchedule()
            }
        }
    }
}

#Preview {
    TimetableContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
