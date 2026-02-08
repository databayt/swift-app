import SwiftUI

/// GPA summary card displayed above grade results
/// Shows GPA (4.0 scale), overall average %, and letter grade
struct GPASummaryCard: View {
    let reportCard: ReportCard

    var body: some View {
        HStack(spacing: 0) {
            // GPA
            statColumn(
                value: String(format: "%.2f", reportCard.gpa),
                label: String(localized: "grade.gpa"),
                color: gpaColor
            )

            Divider()
                .frame(height: 40)

            // Overall Average
            statColumn(
                value: String(format: "%.0f%%", reportCard.overallAverage),
                label: String(localized: "grade.average"),
                color: averageColor
            )

            Divider()
                .frame(height: 40)

            // Letter Grade
            statColumn(
                value: GradeCalculator.letterGrade(for: reportCard.overallAverage),
                label: String(localized: "grade.letterGrade"),
                color: averageColor
            )

            // Rank (if available)
            if let rank = reportCard.rank, let total = reportCard.totalStudents {
                Divider()
                    .frame(height: 40)

                statColumn(
                    value: "\(rank)/\(total)",
                    label: String(localized: "grade.rank"),
                    color: .orange
                )
            }
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statColumn(value: String, label: String, color: Color) -> some View {
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

    private var gpaColor: Color {
        switch reportCard.gpa {
        case 3.5...: return .green
        case 2.5..<3.5: return .blue
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    private var averageColor: Color {
        switch reportCard.overallAverage {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

#Preview {
    GPASummaryCard(reportCard: ReportCard(
        studentId: "s1",
        studentName: "Ahmed",
        grNumber: "GR001",
        yearLevel: "Grade 10",
        semester: "Semester 1",
        subjects: [],
        overallAverage: 87.5,
        gpa: 3.7,
        rank: 5,
        totalStudents: 30,
        attendance: nil
    ))
    .padding()
}
