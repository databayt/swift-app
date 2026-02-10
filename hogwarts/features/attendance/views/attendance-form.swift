import SwiftUI

/// Attendance form for marking attendance
/// Mirrors: src/components/platform/attendance/form.tsx
struct AttendanceForm: View {
    let mode: AttendanceFormMode
    @Bindable var viewModel: AttendanceViewModel

    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var selectedStatus: AttendanceStatus = .present
    @State private var notes = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .markSingle(let studentId):
                    SingleStudentForm(
                        studentId: studentId,
                        selectedStatus: $selectedStatus,
                        notes: $notes,
                        date: viewModel.selectedDate
                    )

                case .markClass:
                    ClassAttendanceForm(viewModel: viewModel)

                case .submitExcuse:
                    EmptyView() // Handled by ExcuseFormView

                case .reviewExcuse(let excuse):
                    ExcuseReviewForm(excuse: excuse, viewModel: viewModel)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .accessibilityLabel(String(localized: "a11y.button.cancel"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        submitForm()
                    }
                    .disabled(isSubmitting)
                    .accessibilityLabel(String(localized: "a11y.button.saveAttendance"))
                }
            }
        }
    }

    private func submitForm() {
        isSubmitting = true

        Task {
            var success = false

            switch mode {
            case .markSingle(let studentId):
                success = await viewModel.markAttendance(
                    studentId: studentId,
                    status: selectedStatus,
                    notes: notes.isEmpty ? nil : notes
                )

            case .markClass:
                success = await viewModel.bulkMarkAttendance()

            case .submitExcuse, .reviewExcuse:
                break
            }

            isSubmitting = false

            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Single Student Form

struct SingleStudentForm: View {
    let studentId: String
    @Binding var selectedStatus: AttendanceStatus
    @Binding var notes: String
    let date: Date

    var body: some View {
        Form {
            Section {
                // Date display
                HStack {
                    Text(String(localized: "attendance.form.date"))
                    Spacer()
                    Text(date, style: .date)
                        .foregroundStyle(.secondary)
                }

                // Status picker
                Picker(String(localized: "attendance.form.status"), selection: $selectedStatus) {
                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        HStack {
                            Image(systemName: status.icon)
                            Text(status.displayName)
                        }
                        .tag(status)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel(String(localized: "a11y.attendance.statusPicker \(selectedStatus.displayName)"))
            }

            Section(String(localized: "attendance.form.notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .accessibilityLabel(String(localized: "a11y.attendance.notesField"))
                    .accessibilityHint(String(localized: "a11y.attendance.notesHint"))
            }

            // Quick status buttons
            Section(String(localized: "attendance.form.quickSelect")) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        StatusButton(
                            status: status,
                            isSelected: selectedStatus == status,
                            action: { selectedStatus = status }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Class Attendance Form

struct ClassAttendanceForm: View {
    @Bindable var viewModel: AttendanceViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Date and quick actions header
            VStack(spacing: 12) {
                HStack {
                    Text(viewModel.selectedDate, style: .date)
                        .font(.headline)
                    Spacer()
                    Menu {
                        Button {
                            viewModel.markAll(status: .present)
                        } label: {
                            Label(
                                String(localized: "attendance.action.markAllPresent"),
                                systemImage: "checkmark.circle"
                            )
                        }

                        Button {
                            viewModel.markAll(status: .absent)
                        } label: {
                            Label(
                                String(localized: "attendance.action.markAllAbsent"),
                                systemImage: "xmark.circle"
                            )
                        }
                    } label: {
                        Label(
                            String(localized: "attendance.action.quickMark"),
                            systemImage: "bolt.fill"
                        )
                        .font(.subheadline)
                    }
                }
                .padding()

                Divider()
            }

            // Student list
            switch viewModel.classAttendanceState {
            case .idle, .loading:
                LoadingView()

            case .loaded:
                List {
                    ForEach($viewModel.markRows) { $row in
                        StudentMarkRow(row: $row)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(UIColor.systemBackground).opacity(0.5))
                                    .padding(.vertical, 4)
                            )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

            case .error(let error):
                ErrorStateView(
                    error: error,
                    retryAction: {
                        if case .markClass(let classId) = viewModel.formMode {
                            Task {
                                await viewModel.loadClassAttendance(
                                    classId: classId,
                                    date: viewModel.selectedDate
                                )
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Student Mark Row

struct StudentMarkRow: View {
    @Binding var row: AttendanceMarkRow

    var body: some View {
        HStack(spacing: 12) {
            // Student photo
            AsyncImage(url: URL(string: row.studentPhoto ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .accessibilityHidden(true)

            // Student info
            VStack(alignment: .leading, spacing: 2) {
                Text(row.studentName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(row.grNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status picker
            Menu {
                ForEach(AttendanceStatus.allCases, id: \.self) { status in
                    Button {
                        row.status = status
                    } label: {
                        HStack {
                            Image(systemName: status.icon)
                            Text(status.displayName)
                            if row.status == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: row.status.icon)
                    Text(row.status.displayName)
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor(row.status).opacity(0.2))
                .foregroundStyle(statusColor(row.status))
                .clipShape(Capsule())
                .accessibilityLabel(String(localized: "a11y.attendance.status \(row.status.displayName)"))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "a11y.attendance.studentMark \(row.studentName) \(row.status.displayName)"))
    }

    private func statusColor(_ status: AttendanceStatus) -> Color {
        switch status {
        case .present: return .green
        case .absent: return .red
        case .late: return .orange
        case .excused: return .blue
        case .sick: return .purple
        case .holiday: return .gray
        }
    }
}

// MARK: - Status Button

struct StatusButton: View {
    let status: AttendanceStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.title2)
                Text(status.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? statusColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? statusColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? statusColor : .clear, lineWidth: 2)
            )
        }
        .accessibilityLabel(String(localized: "a11y.attendance.quickSelect \(status.displayName)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var statusColor: Color {
        switch status {
        case .present: return .green
        case .absent: return .red
        case .late: return .orange
        case .excused: return .blue
        case .sick: return .purple
        case .holiday: return .gray
        }
    }
}

// MARK: - Excuse Form View

struct ExcuseFormView: View {
    let studentId: String
    let date: Date
    @Bindable var viewModel: AttendanceViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var reason = ""
    @State private var documentUrl = ""
    @State private var errors: [String: String] = [:]
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Date display
                    HStack {
                        Text(String(localized: "attendance.excuse.date"))
                        Spacer()
                        Text(date, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String(localized: "attendance.excuse.reason")) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 120)
                        .accessibilityLabel(String(localized: "a11y.excuse.reasonField"))
                        .accessibilityHint(String(localized: "a11y.excuse.reasonHint"))

                    if let error = errors["reason"] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section(String(localized: "attendance.excuse.document")) {
                    TextField(
                        String(localized: "attendance.excuse.documentUrl"),
                        text: $documentUrl
                    )
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(String(localized: "a11y.excuse.documentUrlField"))
                    .accessibilityHint(String(localized: "a11y.excuse.documentUrlHint"))

                    Text(String(localized: "attendance.excuse.documentHint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "attendance.excuse.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.submit")) {
                        submitExcuse()
                    }
                    .disabled(isSubmitting || reason.isEmpty)
                    .accessibilityLabel(String(localized: "a11y.button.submitExcuse"))
                }
            }
        }
    }

    private func submitExcuse() {
        // Validate
        let validation = AttendanceValidation.validateExcuseForm(
            studentId: studentId,
            date: date,
            reason: reason,
            documentUrl: documentUrl.isEmpty ? nil : documentUrl
        )

        guard validation.isValid else {
            errors = validation.errors
            return
        }

        isSubmitting = true

        Task {
            let success = await viewModel.submitExcuse(
                studentId: studentId,
                date: date,
                reason: reason,
                documentUrl: documentUrl.isEmpty ? nil : documentUrl
            )

            isSubmitting = false

            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Excuse Review Form

struct ExcuseReviewForm: View {
    let excuse: AttendanceExcuse
    @Bindable var viewModel: AttendanceViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var reviewNotes = ""
    @State private var isSubmitting = false

    var body: some View {
        Form {
            // Excuse details
            Section(String(localized: "attendance.excuse.details")) {
                HStack {
                    Text(String(localized: "attendance.excuse.date"))
                    Spacer()
                    Text(excuse.date, style: .date)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "attendance.excuse.reason"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(excuse.reason)
                }

                if let documentUrl = excuse.documentUrl,
                   let url = URL(string: documentUrl) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(String(localized: "attendance.excuse.viewDocument"))
                        }
                    }
                }
            }

            // Review notes
            Section(String(localized: "attendance.excuse.reviewNotes")) {
                TextEditor(text: $reviewNotes)
                    .frame(minHeight: 80)
                    .accessibilityLabel(String(localized: "a11y.excuse.reviewNotesField"))
                    .accessibilityHint(String(localized: "a11y.excuse.reviewNotesHint"))
            }

            // Action buttons
            Section {
                HStack(spacing: 16) {
                    Button {
                        reviewExcuse(approved: false)
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text(String(localized: "attendance.excuse.reject"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isSubmitting)
                    .accessibilityLabel(String(localized: "a11y.button.rejectExcuse"))

                    Button {
                        reviewExcuse(approved: true)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(String(localized: "attendance.excuse.approve"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isSubmitting)
                    .accessibilityLabel(String(localized: "a11y.button.approveExcuse"))
                }
            }
        }
    }

    private func reviewExcuse(approved: Bool) {
        isSubmitting = true

        Task {
            let success = await viewModel.reviewExcuse(
                excuse: excuse,
                approved: approved,
                notes: reviewNotes.isEmpty ? nil : reviewNotes
            )

            isSubmitting = false

            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Student") {
    AttendanceForm(
        mode: .markSingle(studentId: "student-1"),
        viewModel: AttendanceViewModel()
    )
}

#Preview("Class") {
    AttendanceForm(
        mode: .markClass(classId: "class-1"),
        viewModel: AttendanceViewModel()
    )
}
