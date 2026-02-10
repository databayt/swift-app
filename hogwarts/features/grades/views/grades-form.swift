import SwiftUI
import os

/// Grade entry form - Create Exam or Enter Marks
/// Mirrors: src/components/platform/grades/form.tsx
struct GradesForm: View {
    @Bindable var viewModel: GradesViewModel
    @Environment(TenantContext.self) private var tenantContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.formMode {
                case .createExam, .editExam:
                    CreateExamForm(viewModel: viewModel)
                case .enterMarks(let exam):
                    EnterMarksForm(viewModel: viewModel, exam: exam)
                }
            }
            .navigationTitle(viewModel.formMode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Create Exam Form

struct CreateExamForm: View {
    @Bindable var viewModel: GradesViewModel
    @Environment(TenantContext.self) private var tenantContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedClassId: String?
    @State private var selectedSubjectId: String?
    @State private var examDate = Date()
    @State private var totalMarks = "100"
    @State private var passingMarks = "50"
    @State private var examType: ExamType = .test
    @State private var description = ""

    @State private var errors: [String: String] = [:]
    @State private var isSubmitting = false

    @State private var availableClasses: [TeacherClassItem] = []
    @State private var availableSubjects: [SubjectInfo] = []

    private let actions = AttendanceActions()
    private let gradesActions = GradesActions()

    var body: some View {
        Form {
            Section(String(localized: "grade.form.section.details")) {
                ValidatedTextField(
                    title: String(localized: "grade.form.title"),
                    text: $title,
                    error: errors["title"],
                    isRequired: true
                )

                Picker(String(localized: "grade.form.examType"), selection: $examType) {
                    ForEach(ExamType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .accessibilityLabel(String(localized: "a11y.picker.examType"))
                .accessibilityHint(String(localized: "a11y.hint.selectExamType"))

                TextField(String(localized: "grade.form.description"), text: $description, axis: .vertical)
                    .lineLimit(3)
                    .accessibilityLabel(String(localized: "a11y.field.examDescription"))
                    .accessibilityHint(String(localized: "a11y.hint.enterExamDescription"))
            }

            Section(String(localized: "grade.form.section.class")) {
                Picker(String(localized: "grade.form.class"), selection: $selectedClassId) {
                    Text(String(localized: "common.select")).tag(nil as String?)
                    ForEach(availableClasses) { cls in
                        Text(cls.displayName).tag(cls.id as String?)
                    }
                }
                .accessibilityLabel(String(localized: "a11y.picker.class"))
                .accessibilityHint(String(localized: "a11y.hint.selectClass"))
                .onChange(of: selectedClassId) { _, newValue in
                    if let classId = newValue {
                        Task { await loadSubjects(classId: classId) }
                    }
                }

                if !availableSubjects.isEmpty {
                    Picker(String(localized: "grade.form.subject"), selection: $selectedSubjectId) {
                        Text(String(localized: "common.select")).tag(nil as String?)
                        ForEach(availableSubjects) { subject in
                            Text(subject.displayName).tag(subject.id as String?)
                        }
                    }
                    .accessibilityLabel(String(localized: "a11y.picker.subject"))
                    .accessibilityHint(String(localized: "a11y.hint.selectSubject"))
                }

                if let error = errors["classId"] {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                if let error = errors["subjectId"] {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section(String(localized: "grade.form.section.marks")) {
                DatePicker(
                    String(localized: "grade.form.examDate"),
                    selection: $examDate,
                    displayedComponents: .date
                )

                HStack {
                    VStack(alignment: .leading) {
                        Text(String(localized: "grade.form.totalMarks"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("100", text: $totalMarks)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel(String(localized: "a11y.field.totalMarks"))
                            .accessibilityHint(String(localized: "a11y.hint.enterTotalMarks"))
                    }

                    VStack(alignment: .leading) {
                        Text(String(localized: "grade.form.passingMarks"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("50", text: $passingMarks)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel(String(localized: "a11y.field.passingMarks"))
                            .accessibilityHint(String(localized: "a11y.hint.enterPassingMarks"))
                    }
                }

                if let error = errors["totalMarks"] {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                if let error = errors["passingMarks"] {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await submitExam() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(String(localized: "grade.form.createExam"))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSubmitting)
                .accessibilityLabel(String(localized: "a11y.button.createExam"))
            }
        }
        .task {
            await loadClasses()
            loadExistingData()
        }
    }

    private func loadExistingData() {
        if case .editExam(let exam) = viewModel.formMode {
            title = exam.title
            selectedClassId = exam.classId
            selectedSubjectId = exam.subjectId
            examType = exam.examTypeEnum
            totalMarks = String(format: "%.0f", exam.totalMarks)
            passingMarks = String(format: "%.0f", exam.passingMarks)
            description = exam.description ?? ""
        }
    }

    private func loadClasses() async {
        guard let schoolId = tenantContext.schoolId else { return }
        do {
            availableClasses = try await actions.getTeacherClasses(schoolId: schoolId)
        } catch {
            Logger.grades.error("Failed to load classes: \(error)")
        }
    }

    private func loadSubjects(classId: String) async {
        guard let schoolId = tenantContext.schoolId else { return }
        do {
            availableSubjects = try await gradesActions.getSubjects(classId: classId, schoolId: schoolId)
        } catch {
            Logger.grades.error("Failed to load subjects: \(error)")
        }
    }

    private func submitExam() async {
        let total = Double(totalMarks) ?? 0
        let passing = Double(passingMarks) ?? 0

        let validation = GradesValidation.validateCreateExamForm(
            title: title,
            classId: selectedClassId,
            subjectId: selectedSubjectId,
            examDate: ISO8601DateFormatter().string(from: examDate),
            totalMarks: total,
            passingMarks: passing
        )

        guard validation.isValid else {
            errors = validation.errors
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = CreateExamRequest(
            title: title,
            classId: selectedClassId ?? "",
            subjectId: selectedSubjectId ?? "",
            description: description.isEmpty ? nil : description,
            examDate: ISO8601DateFormatter().string(from: examDate),
            totalMarks: total,
            passingMarks: passing,
            examType: examType.rawValue
        )

        let success = await viewModel.createExam(request)
        if success {
            dismiss()
        }
    }
}

// MARK: - Enter Marks Form

struct EnterMarksForm: View {
    @Bindable var viewModel: GradesViewModel
    @Environment(TenantContext.self) private var tenantContext
    @Environment(\.dismiss) private var dismiss

    let exam: Exam

    @State private var entryRows: [GradeEntryRow] = []
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errors: [String: String] = [:]

    private let attendanceActions = AttendanceActions()

    var body: some View {
        VStack(spacing: 0) {
            // Exam info header
            VStack(alignment: .leading, spacing: 8) {
                Text(exam.title)
                    .font(.headline)

                HStack {
                    if let subject = exam.subject {
                        Text(subject.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(localized: "grade.form.totalMarksLabel \(String(format: "%.0f", exam.totalMarks))"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.quaternary)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if entryRows.isEmpty {
                Spacer()
                Text(String(localized: "grade.form.noStudents"))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                // Student marks list
                List {
                    ForEach($entryRows) { $row in
                        MarksEntryRowView(
                            row: $row,
                            totalMarks: exam.totalMarks,
                            error: errors[row.studentId]
                        )
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.systemBackground).opacity(0.5))
                                .padding(.vertical, 4)
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                // Submit button
                Button {
                    Task { await submitMarks() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(String(localized: "grade.form.submitMarks"))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSubmitting)
                .padding()
                .accessibilityLabel(String(localized: "a11y.button.submitMarks"))
            }
        }
        .task {
            await loadStudents()
        }
    }

    private func loadStudents() async {
        guard let schoolId = tenantContext.schoolId else { return }

        do {
            let students = try await attendanceActions.getClassStudents(
                classId: exam.classId,
                schoolId: schoolId
            )

            entryRows = students.map { GradeEntryRow(student: $0) }
            isLoading = false
        } catch {
            isLoading = false
            Logger.grades.error("Failed to load students: \(error)")
        }
    }

    private func submitMarks() async {
        let validation = GradesValidation.validateMarksEntryForm(
            entries: entryRows,
            totalMarks: exam.totalMarks
        )

        guard validation.isValid else {
            errors = validation.errors
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let markEntries = entryRows.compactMap { row -> SubmitMarksRequest.MarkEntry? in
            guard !row.marks.isEmpty, let marks = Double(row.marks) else { return nil }
            return SubmitMarksRequest.MarkEntry(
                studentId: row.studentId,
                marks: marks,
                remarks: row.remarks.isEmpty ? nil : row.remarks
            )
        }

        let request = SubmitMarksRequest(
            examId: exam.id,
            results: markEntries
        )

        let success = await viewModel.submitMarks(request)
        if success {
            dismiss()
        }
    }
}

// MARK: - Marks Entry Row

struct MarksEntryRowView: View {
    @Binding var row: GradeEntryRow
    let totalMarks: Double
    let error: String?

    private var percentage: Double {
        guard let marks = Double(row.marks), totalMarks > 0 else { return 0 }
        return (marks / totalMarks) * 100
    }

    private var gradeLabel: String {
        guard !row.marks.isEmpty else { return "-" }
        return GradeCalculator.letterGrade(for: percentage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.studentName)
                        .font(.headline)
                    Text(row.grNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Grade badge
                Text(gradeLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradeColor.opacity(0.2))
                    .foregroundStyle(gradeColor)
                    .clipShape(Capsule())
                    .accessibilityLabel(String(localized: "a11y.label.grade \(gradeLabel)"))
            }

            HStack(spacing: 12) {
                // Marks field
                HStack {
                    TextField("0", text: $row.marks)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(String(localized: "a11y.field.marksFor \(row.studentName)"))
                        .accessibilityHint(String(localized: "a11y.hint.enterMarksOutOf \(String(format: "%.0f", totalMarks))"))

                    Text("/ \(String(format: "%.0f", totalMarks))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Remarks field
                TextField(String(localized: "grade.form.remarks"), text: $row.remarks)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(String(localized: "a11y.field.remarksFor \(row.studentName)"))
                    .accessibilityHint(String(localized: "a11y.hint.enterRemarks"))
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var gradeColor: Color {
        guard !row.marks.isEmpty else { return .gray }
        let isPassing = (Double(row.marks) ?? 0) >= (totalMarks * 0.5)
        if !isPassing { return .red }
        switch percentage {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    GradesForm(viewModel: GradesViewModel())
        .environment(TenantContext())
}
