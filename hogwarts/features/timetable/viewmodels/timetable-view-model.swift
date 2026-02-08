import SwiftUI
import SwiftData

/// ViewModel for Timetable feature
/// Mirrors: Logic from content.tsx + role-based views
@Observable
@MainActor
final class TimetableViewModel {
    // Dependencies
    private let actions = TimetableActions()
    private var tenantContext: TenantContext?
    private var authManager: AuthManager?

    // State
    var viewState: TimetableViewState = .idle
    var displayMode: TimetableDisplayMode = .week
    var selectedDate = Date()
    var selectedDay: DayOfWeek = DayOfWeek.today
    var selectedEntry: TimetableEntry?
    var classDetail: ClassDetailResponse?

    // Sheet state
    var isShowingClassDetail = false

    // Error handling
    var error: Error?
    var showError = false

    // MARK: - Computed Properties

    var entries: [TimetableEntry] {
        viewState.entries
    }

    var isLoading: Bool {
        viewState.isLoading
    }

    var capabilities: TimetableCapabilities {
        guard let role = authManager?.role else {
            return TimetableCapabilities.forRole(.user)
        }
        return TimetableCapabilities.forRole(role)
    }

    /// Entries filtered by selected day
    var entriesForSelectedDay: [TimetableEntry] {
        entries
            .filter { $0.dayOfWeek == selectedDay.rawValue }
            .sorted { ($0.periodNumber ?? 0) < ($1.periodNumber ?? 0) }
    }

    /// Entries grouped by day of week
    var entriesByDay: [DayOfWeek: [TimetableEntry]] {
        Dictionary(grouping: entries) { entry in
            DayOfWeek(rawValue: entry.dayOfWeek ?? 0) ?? .sunday
        }
        .mapValues { entries in
            entries.sorted { ($0.periodNumber ?? 0) < ($1.periodNumber ?? 0) }
        }
    }

    /// Term name from response
    var termName: String? {
        if case .loaded(let response) = viewState {
            return response.termName
        }
        return nil
    }

    // MARK: - Setup

    func setup(tenantContext: TenantContext, authManager: AuthManager) {
        self.tenantContext = tenantContext
        self.authManager = authManager
    }

    // MARK: - Load Actions

    /// Load weekly schedule (offline-first)
    func loadWeeklySchedule() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(APIError.unauthorized)
            return
        }

        viewState = .loading

        do {
            let response = try await actions.getWeeklySchedule(schoolId: schoolId)

            if response.entries.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(response)
            }

            // Cache to SwiftData
            cacheTimetableEntries(response.entries, schoolId: schoolId)
        } catch {
            // Offline fallback: read from SwiftData
            let cached = loadCachedTimetable(schoolId: schoolId)
            if !cached.isEmpty {
                let response = WeeklyScheduleResponse(
                    entries: cached,
                    termName: nil,
                    className: nil
                )
                viewState = .loaded(response)
            } else {
                viewState = .error(error)
                self.error = error
                showError = true
            }
        }
    }

    /// Load daily schedule for a specific date
    func loadDailySchedule() async {
        guard let schoolId = tenantContext?.schoolId else {
            viewState = .error(APIError.unauthorized)
            return
        }

        viewState = .loading

        do {
            let entries = try await actions.getDailySchedule(
                schoolId: schoolId,
                date: selectedDate
            )

            if entries.isEmpty {
                viewState = .empty
            } else {
                let response = WeeklyScheduleResponse(
                    entries: entries,
                    termName: nil,
                    className: nil
                )
                viewState = .loaded(response)
            }
        } catch {
            viewState = .error(error)
            self.error = error
            showError = true
        }
    }

    /// Load class details
    func loadClassDetail(classId: String) async {
        guard let schoolId = tenantContext?.schoolId else { return }

        do {
            classDetail = try await actions.getClassDetails(
                classId: classId,
                schoolId: schoolId
            )
            isShowingClassDetail = true
        } catch {
            self.error = error
            showError = true
        }
    }

    /// Show class detail for entry
    func showDetail(for entry: TimetableEntry) {
        selectedEntry = entry
        if let classId = entry.classId {
            Task { await loadClassDetail(classId: classId) }
        }
    }

    /// Refresh timetable
    func refresh() async {
        switch displayMode {
        case .week:
            await loadWeeklySchedule()
        case .day:
            await loadDailySchedule()
        }
    }

    /// Select day
    func selectDay(_ day: DayOfWeek) {
        selectedDay = day
    }

    /// Toggle display mode
    func toggleDisplayMode() {
        displayMode = displayMode == .week ? .day : .week
        Task { await refresh() }
    }

    // MARK: - SwiftData Cache

    /// Cache timetable entries to SwiftData
    private func cacheTimetableEntries(_ entries: [TimetableEntry], schoolId: String) {
        let context = DataContainer.shared.modelContext
        for entry in entries {
            let entryId = entry.id
            let descriptor = FetchDescriptor<TimetableModel>(
                predicate: #Predicate { $0.id == entryId }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: entry)
                existing.lastSyncedAt = Date()
            } else {
                let model = TimetableModel(from: entry, schoolId: schoolId)
                model.lastSyncedAt = Date()
                context.insert(model)
            }
        }
        try? context.save()
    }

    /// Load cached timetable from SwiftData
    private func loadCachedTimetable(schoolId: String) -> [TimetableEntry] {
        let context = DataContainer.shared.modelContext
        let descriptor = FetchDescriptor<TimetableModel>(
            predicate: #Predicate { $0.schoolId == schoolId },
            sortBy: [SortDescriptor(\.dayOfWeek), SortDescriptor(\.startTime)]
        )
        guard let models = try? context.fetch(descriptor) else { return [] }
        return models.map { TimetableEntry(from: $0) }
    }
}
