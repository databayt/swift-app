import SwiftUI

/// Report Card Display
/// Mirrors: src/components/platform/grades/report-card.tsx
struct ReportCardView: View {
    let reportCard: ReportCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    reportHeader

                    // Subject grades table
                    subjectGradesSection

                    // Summary card
                    summaryCard

                    // Attendance card
                    if let attendance = reportCard.attendance {
                        attendanceCard(attendance)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "grade.reportCard.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: reportCardText,
                        subject: Text(String(localized: "grade.reportCard.shareSubject")),
                        message: Text(reportCardSummary)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var reportHeader: some View {
        VStack(spacing: 12) {
            // Student photo placeholder
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(.secondary)

            Text(reportCard.studentName)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label(reportCard.grNumber, systemImage: "number")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let yearLevel = reportCard.yearLevel {
                    Label(yearLevel, systemImage: "graduationcap")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let semester = reportCard.semester {
                Text(semester)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subject Grades

    @ViewBuilder
    private var subjectGradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "grade.reportCard.subjects"))
                .font(.headline)

            ForEach(reportCard.subjects) { subject in
                SubjectGradeRow(subject: subject)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Summary Card

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text(String(localized: "grade.reportCard.summary"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // Overall average
                SummaryStatView(
                    value: String(format: "%.1f%%", reportCard.overallAverage),
                    label: String(localized: "grade.reportCard.average"),
                    color: reportCard.overallAverage >= 50 ? .green : .red
                )

                // GPA
                SummaryStatView(
                    value: String(format: "%.2f", reportCard.gpa),
                    label: String(localized: "grade.reportCard.gpa"),
                    color: .blue
                )

                // Grade
                SummaryStatView(
                    value: GradeCalculator.letterGrade(for: reportCard.overallAverage),
                    label: String(localized: "grade.reportCard.grade"),
                    color: .purple
                )

                // Rank
                if let rank = reportCard.rank, let total = reportCard.totalStudents {
                    SummaryStatView(
                        value: "\(rank)/\(total)",
                        label: String(localized: "grade.reportCard.rank"),
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Attendance Card

    @ViewBuilder
    private func attendanceCard(_ attendance: ReportCardAttendance) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "grade.reportCard.attendance"))
                    .font(.headline)
                Spacer()
                Text("\(Int(attendance.attendanceRate))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(attendance.attendanceRate >= 90 ? .green : .orange)
            }

            HStack(spacing: 16) {
                AttendanceStatPill(
                    count: attendance.presentDays,
                    label: String(localized: "attendance.status.present"),
                    color: .green
                )
                AttendanceStatPill(
                    count: attendance.absentDays,
                    label: String(localized: "attendance.status.absent"),
                    color: .red
                )
                AttendanceStatPill(
                    count: attendance.lateDays,
                    label: String(localized: "attendance.status.late"),
                    color: .orange
                )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(attendance.attendanceRate >= 90 ? .green : .orange)
                        .frame(width: geometry.size.width * min(attendance.attendanceRate / 100, 1.0))
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Share

    private var reportCardText: String {
        """
        \(String(localized: "grade.reportCard.title"))
        \(reportCard.studentName) - \(reportCard.grNumber)
        \(String(localized: "grade.reportCard.average")): \(String(format: "%.1f%%", reportCard.overallAverage))
        GPA: \(String(format: "%.2f", reportCard.gpa))
        """
    }

    private var reportCardSummary: String {
        reportCard.subjects.map { "\($0.displayName): \($0.grade)" }.joined(separator: "\n")
    }
}

// MARK: - Subject Grade Row

struct SubjectGradeRow: View {
    let subject: SubjectGrade
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Subject header
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(subject.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(String(format: "%.1f%%", subject.average))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(subject.grade)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(gradeColor.opacity(0.2))
                        .foregroundStyle(gradeColor)
                        .clipShape(Capsule())

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .padding(.vertical, 8)

            // Exam breakdown
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(subject.exams) { exam in
                        HStack {
                            Text(exam.examName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(String(format: "%.1f", exam.marks))/\(String(format: "%.0f", exam.totalMarks))")
                                .font(.caption)
                            Text("(\(Int(exam.percentage))%)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 8)
            }

            Divider()
        }
    }

    private var gradeColor: Color {
        switch subject.average {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

// MARK: - Helper Views

struct SummaryStatView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AttendanceStatPill: View {
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

// MARK: - Preview

#Preview {
    ReportCardView(reportCard: ReportCard(
        studentId: "s1",
        studentName: "Ahmed Mohamed",
        grNumber: "GR001",
        yearLevel: "Grade 10",
        semester: "Semester 1 - 2025/2026",
        subjects: [
            SubjectGrade(
                id: "sg1",
                subjectName: "Mathematics",
                subjectNameAr: "الرياضيات",
                exams: [
                    ExamScore(id: "e1", examName: "Midterm", marks: 85, totalMarks: 100, percentage: 85),
                    ExamScore(id: "e2", examName: "Final", marks: 90, totalMarks: 100, percentage: 90)
                ],
                average: 87.5,
                grade: "A"
            )
        ],
        overallAverage: 87.5,
        gpa: 3.7,
        rank: 5,
        totalStudents: 30,
        attendance: ReportCardAttendance(
            totalDays: 100,
            presentDays: 95,
            absentDays: 3,
            lateDays: 2,
            attendanceRate: 95
        )
    ))
}
