import SwiftUI

/// Main attendance view
/// Mirrors: src/components/platform/attendance/content.tsx
struct AttendanceContent: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext
    @State private var viewModel = AttendanceViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker
                DatePicker(
                    String(localized: "attendance.date"),
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accessibilityLabel(String(localized: "a11y.attendance.datePicker"))
                .padding()
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    Task { await viewModel.loadAttendanceForDate(newDate) }
                }

                Divider()

                // Role-based content
                Group {
                    if viewModel.capabilities.canMarkAttendance {
                        TeacherAttendanceContent(viewModel: viewModel)
                    } else if viewModel.capabilities.canQRCheckIn {
                        StudentAttendanceContent(viewModel: viewModel)
                    } else if viewModel.capabilities.canSubmitExcuse {
                        GuardianAttendanceContent(viewModel: viewModel)
                    } else {
                        ViewOnlyAttendanceContent(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(String(localized: "attendance.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.capabilities.canMarkAttendance {
                        Menu {
                            if viewModel.teacherClasses.isEmpty {
                                Button {
                                    viewModel.showMarkClassForm(classId: viewModel.selectedClassId ?? "")
                                } label: {
                                    Label(
                                        String(localized: "attendance.action.markClass"),
                                        systemImage: "person.3"
                                    )
                                }
                            } else {
                                ForEach(viewModel.teacherClasses) { cls in
                                    Button {
                                        viewModel.showMarkClassForm(classId: cls.id)
                                    } label: {
                                        Label(cls.displayName, systemImage: "person.3")
                                    }
                                }
                            }

                            Divider()

                            Button {
                                viewModel.showMarkForm(studentId: "")
                            } label: {
                                Label(
                                    String(localized: "attendance.action.markStudent"),
                                    systemImage: "person"
                                )
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(String(localized: "a11y.button.markAttendance"))
                    } else if viewModel.capabilities.canQRCheckIn {
                        Button {
                            viewModel.showQRScanner()
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                        }
                        .accessibilityLabel(String(localized: "a11y.button.scanQR"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingForm) {
                if let mode = viewModel.formMode {
                    AttendanceForm(
                        mode: mode,
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $viewModel.isShowingQRScanner) {
                QRScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingExcuseForm) {
                if case .submitExcuse(let studentId, let date) = viewModel.formMode {
                    ExcuseFormView(
                        studentId: studentId,
                        date: date,
                        viewModel: viewModel
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
                await viewModel.loadAttendanceForDate(viewModel.selectedDate)
                await viewModel.loadStats()
                await viewModel.loadTeacherClasses()
            }
        }
    }
}

// MARK: - Teacher View

struct TeacherAttendanceContent: View {
    @Bindable var viewModel: AttendanceViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Class selector
            if !viewModel.teacherClasses.isEmpty {
                Picker(String(localized: "attendance.class"), selection: Binding(
                    get: { viewModel.selectedClassId ?? "" },
                    set: { newValue in
                        viewModel.selectedClassId = newValue
                        viewModel.filterByClass(newValue.isEmpty ? nil : newValue)
                    }
                )) {
                    Text(String(localized: "filter.allClasses")).tag("")
                    ForEach(viewModel.teacherClasses) { cls in
                        Text(cls.displayName).tag(cls.id)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(String(localized: "a11y.attendance.classFilter"))
                .padding(.horizontal)
            }

            // Stats summary (if viewing student)
            if viewModel.filters.studentId != nil, let stats = viewModel.statsDisplay {
                AttendanceStatsBar(stats: stats)
            }

            // Filter bar
            AttendanceToolbar(viewModel: viewModel)

            // Content
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    LoadingView()

                case .loaded:
                    AttendanceTable(
                        rows: viewModel.rows,
                        canEdit: true,
                        onEdit: { row in
                            viewModel.showMarkForm(studentId: row.studentId)
                        }
                    )
                    .refreshable {
                        await viewModel.refresh()
                    }

                case .empty:
                    EmptyStateView(
                        title: String(localized: "attendance.empty.title"),
                        message: String(localized: "attendance.empty.teacher.message"),
                        systemImage: "calendar.badge.checkmark",
                        action: {
                            viewModel.showMarkClassForm(classId: "")
                        },
                        actionTitle: String(localized: "attendance.action.markClass")
                    )

                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: {
                            Task { await viewModel.loadAttendance() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Student View

struct StudentAttendanceContent: View {
    @Bindable var viewModel: AttendanceViewModel
    @State private var displayMode: AttendanceDisplayMode = .list

    enum AttendanceDisplayMode: String, CaseIterable {
        case list, calendar, charts

        var label: String {
            switch self {
            case .list: return String(localized: "attendance.view.list")
            case .calendar: return String(localized: "attendance.view.calendar")
            case .charts: return String(localized: "attendance.view.charts")
            }
        }

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            case .charts: return "chart.pie"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats card
            if let stats = viewModel.statsDisplay {
                AttendanceStatsCard(stats: stats)
                    .padding()
            }

            // Display mode picker
            Picker(String(localized: "attendance.view.mode"), selection: $displayMode) {
                ForEach(AttendanceDisplayMode.allCases, id: \.self) { mode in
                    Label(mode.label, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(String(localized: "a11y.attendance.displayMode"))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // History (list or calendar)
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    LoadingView()

                case .loaded:
                    if displayMode == .charts {
                        if let stats = viewModel.statsDisplay {
                            ScrollView {
                                AttendanceChartsView(
                                    stats: stats,
                                    records: viewModel.rows
                                )
                            }
                            .refreshable {
                                await viewModel.refresh()
                            }
                        }
                    } else if displayMode == .calendar {
                        ScrollView {
                            AttendanceCalendarView(
                                rows: viewModel.rows,
                                selectedDate: $viewModel.selectedDate
                            )
                            .padding(.vertical)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    } else {
                        List {
                            ForEach(viewModel.rows) { row in
                                AttendanceHistoryRow(row: row)
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }

                case .empty:
                    EmptyStateView(
                        title: String(localized: "attendance.empty.title"),
                        message: String(localized: "attendance.empty.student.message"),
                        systemImage: "calendar.badge.checkmark"
                    )

                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: {
                            Task { await viewModel.loadAttendance() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Guardian View

struct GuardianAttendanceContent: View {
    @Bindable var viewModel: AttendanceViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Stats card
            if let stats = viewModel.statsDisplay {
                AttendanceStatsCard(stats: stats)
                    .padding()
            }

            // Excuse list link
            NavigationLink {
                ExcuseListView()
            } label: {
                Label(
                    String(localized: "excuse.viewAll"),
                    systemImage: "doc.text.magnifyingglass"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            // Excuse button
            if AttendanceValidation.canSubmitExcuse(for: viewModel.selectedDate) {
                Button {
                    if let studentId = viewModel.filters.studentId {
                        viewModel.showExcuseForm(studentId: studentId, date: viewModel.selectedDate)
                    }
                } label: {
                    Label(
                        String(localized: "attendance.action.submitExcuse"),
                        systemImage: "doc.text"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
            }

            // History
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    LoadingView()

                case .loaded:
                    List {
                        ForEach(viewModel.rows) { row in
                            AttendanceHistoryRow(row: row)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refresh()
                    }

                case .empty:
                    EmptyStateView(
                        title: String(localized: "attendance.empty.title"),
                        message: String(localized: "attendance.empty.guardian.message"),
                        systemImage: "calendar.badge.checkmark"
                    )

                case .error(let error):
                    ErrorStateView(
                        error: error,
                        retryAction: {
                            Task { await viewModel.loadAttendance() }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - View Only

struct ViewOnlyAttendanceContent: View {
    @Bindable var viewModel: AttendanceViewModel

    var body: some View {
        VStack {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                .padding()

            Text(String(localized: "attendance.noAccess"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Toolbar

struct AttendanceToolbar: View {
    @Bindable var viewModel: AttendanceViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: String(localized: "filter.all"),
                        isSelected: viewModel.filters.status == nil,
                        action: { viewModel.filterByStatus(nil) }
                    )
                    .accessibilityLabel(String(localized: "a11y.filter.allStatuses"))
                    .accessibilityAddTraits(viewModel.filters.status == nil ? .isSelected : [])

                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: viewModel.filters.status == status,
                            action: { viewModel.filterByStatus(status) }
                        )
                        .accessibilityLabel(status.displayName)
                        .accessibilityAddTraits(viewModel.filters.status == status ? .isSelected : [])
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Stats Components

struct AttendanceStatsBar: View {
    let stats: AttendanceStatsDisplay

    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                value: "\(Int(stats.attendanceRate))%",
                label: String(localized: "attendance.stats.rate"),
                color: stats.attendanceRate >= 90 ? .green : .orange
            )

            Divider()
                .frame(height: 30)

            StatItem(
                value: "\(stats.presentDays)",
                label: String(localized: "attendance.stats.present"),
                color: .green
            )

            StatItem(
                value: "\(stats.absentDays)",
                label: String(localized: "attendance.stats.absent"),
                color: .red
            )

            StatItem(
                value: "\(stats.lateDays)",
                label: String(localized: "attendance.stats.late"),
                color: .orange
            )
        }
        .padding()
        .background(.quaternary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "a11y.attendance.statsBar"))
    }
}

struct AttendanceStatsCard: View {
    let stats: AttendanceStatsDisplay

    var body: some View {
        VStack(spacing: 16) {
            // Attendance rate
            HStack {
                VStack(alignment: .leading) {
                    Text(String(localized: "attendance.stats.rate"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int(stats.attendanceRate))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(stats.attendanceRate >= 90 ? .green : .orange)
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: stats.attendanceRate / 100)
                        .stroke(stats.attendanceRate >= 90 ? .green : .orange, lineWidth: 8)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 60, height: 60)
            }

            // Breakdown
            HStack(spacing: 20) {
                StatPill(
                    count: stats.presentDays,
                    label: String(localized: "attendance.status.present"),
                    color: .green
                )
                StatPill(
                    count: stats.absentDays,
                    label: String(localized: "attendance.status.absent"),
                    color: .red
                )
                StatPill(
                    count: stats.lateDays,
                    label: String(localized: "attendance.status.late"),
                    color: .orange
                )
            }
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "a11y.attendance.statsCard"))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct StatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - History Row

struct AttendanceHistoryRow: View {
    let row: AttendanceRow

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: row.status.icon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 40)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(row.date, style: .date)
                    .font(.headline)

                if let className = row.className {
                    Text(className)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let notes = row.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status badge
            Text(row.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
                .accessibilityLabel(String(localized: "a11y.attendance.status \(row.status.displayName)"))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch row.status {
        case .present: return .green
        case .absent: return .red
        case .late: return .orange
        case .excused: return .blue
        case .sick: return .purple
        case .holiday: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    AttendanceContent()
        .environment(AuthManager())
        .environment(TenantContext())
}
