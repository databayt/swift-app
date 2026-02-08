import SwiftUI

/// Exam results table view
/// Mirrors: src/components/platform/grades/table.tsx
struct GradesTable: View {
    let rows: [ExamResultRow]
    var onSelect: ((ExamResultRow) -> Void)?

    var body: some View {
        List {
            ForEach(rows) { row in
                ExamResultRowView(row: row)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect?(row)
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Exam Result Row View

struct ExamResultRowView: View {
    let row: ExamResultRow

    var body: some View {
        HStack(spacing: 12) {
            // Grade circle
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(row.grade)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(gradeColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(row.examTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(row.subjectName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\u{2022}")
                        .foregroundStyle(.tertiary)

                    Text(row.examType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(row.examDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 4) {
                if let marks = row.marks {
                    Text("\(String(format: "%.1f", marks))/\(String(format: "%.0f", row.totalMarks))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text(String(localized: "grade.pending"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Percentage bar
                PercentageBar(
                    percentage: row.percentage,
                    isPassing: row.isPassing
                )
                .frame(width: 60)
            }
        }
        .padding(.vertical, 4)
    }

    private var gradeColor: Color {
        if !row.isPassing { return .red }
        switch row.percentage {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

// MARK: - Percentage Bar

struct PercentageBar: View {
    let percentage: Double
    let isPassing: Bool

    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPassing ? .green : .red)
                        .frame(width: geometry.size.width * min(percentage / 100, 1.0))
                }
            }
            .frame(height: 4)

            Text("\(Int(percentage))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Exam List (Teacher View)

struct ExamListView: View {
    let exams: [Exam]
    let onSelect: (Exam) -> Void
    let onEnterMarks: (Exam) -> Void

    var body: some View {
        List {
            ForEach(exams) { exam in
                ExamRowView(exam: exam)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(exam) }
                    .swipeActions(edge: .trailing) {
                        if exam.examStatusEnum == .completed || exam.examStatusEnum == .scheduled {
                            Button {
                                onEnterMarks(exam)
                            } label: {
                                Label(String(localized: "grade.action.enterMarks"), systemImage: "pencil.line")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct ExamRowView: View {
    let exam: Exam

    var body: some View {
        HStack(spacing: 12) {
            // Exam type icon
            Image(systemName: examIcon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(exam.title)
                    .font(.headline)

                HStack(spacing: 6) {
                    if let subject = exam.subject {
                        Text(subject.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\u{2022}")
                        .foregroundStyle(.tertiary)

                    Text(exam.examTypeEnum.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(exam.examDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status badge
            Text(exam.examStatusEnum.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var examIcon: String {
        switch exam.examTypeEnum {
        case .midterm: return "doc.text"
        case .final_: return "doc.text.fill"
        case .quiz: return "questionmark.circle"
        case .test: return "pencil.and.list.clipboard"
        case .practical: return "flask"
        case .assignment: return "doc.on.clipboard"
        }
    }

    private var statusColor: Color {
        switch exam.examStatusEnum {
        case .draft: return .gray
        case .scheduled: return .blue
        case .completed: return .orange
        case .published: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    GradesTable(rows: [])
}
