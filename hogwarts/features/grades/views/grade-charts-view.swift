import SwiftUI
import Charts

/// Grade history charts using Swift Charts
/// Mirrors: Grade analytics visualization
struct GradeChartsView: View {
    let results: [ExamResultRow]
    let reportCard: ReportCard?

    @State private var selectedChart: ChartType = .subjectAverages

    enum ChartType: String, CaseIterable {
        case subjectAverages
        case gradeProgression

        var label: String {
            switch self {
            case .subjectAverages: return String(localized: "grade.chart.subjectAverages")
            case .gradeProgression: return String(localized: "grade.chart.progression")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart type picker
                Picker(String(localized: "grade.chart.type"), selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityLabel(String(localized: "a11y.picker.chartType"))
                .accessibilityHint(String(localized: "a11y.hint.switchChartType"))

                // Chart content
                switch selectedChart {
                case .subjectAverages:
                    subjectAveragesChart
                case .gradeProgression:
                    gradeProgressionChart
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(String(localized: "grade.chart.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subject Averages Bar Chart

    @ViewBuilder
    private var subjectAveragesChart: some View {
        if let subjects = reportCard?.subjects, !subjects.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "grade.chart.subjectAverages"))
                    .font(.headline)
                    .padding(.horizontal)

                Chart(subjects) { subject in
                    BarMark(
                        x: .value(String(localized: "grade.chart.subject"), subject.displayName),
                        y: .value(String(localized: "grade.chart.average"), subject.average)
                    )
                    .foregroundStyle(barColor(for: subject.average))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", subject.average))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(height: 250)
                .padding(.horizontal)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .green, label: "90+")
                        .accessibilityLabel(String(localized: "a11y.legend.excellent"))
                    legendItem(color: .blue, label: "75-89")
                        .accessibilityLabel(String(localized: "a11y.legend.good"))
                    legendItem(color: .orange, label: "60-74")
                        .accessibilityLabel(String(localized: "a11y.legend.average"))
                    legendItem(color: .red, label: "<60")
                        .accessibilityLabel(String(localized: "a11y.legend.belowAverage"))
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .padding()
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "a11y.label.subjectAveragesChart \(subjects.count)"))
        } else {
            noDataView
        }
    }

    // MARK: - Grade Progression Line Chart

    @ViewBuilder
    private var gradeProgressionChart: some View {
        let sortedResults = results.sorted { $0.examDate < $1.examDate }
        if !sortedResults.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "grade.chart.progression"))
                    .font(.headline)
                    .padding(.horizontal)

                Chart(sortedResults) { result in
                    LineMark(
                        x: .value(String(localized: "grade.chart.exam"), result.examTitle),
                        y: .value(String(localized: "grade.chart.percentage"), result.percentage)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value(String(localized: "grade.chart.exam"), result.examTitle),
                        y: .value(String(localized: "grade.chart.percentage"), result.percentage)
                    )
                    .foregroundStyle(pointColor(for: result.percentage))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f%%", result.percentage))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(height: 250)
                .padding(.horizontal)

                // Stats summary
                if !sortedResults.isEmpty {
                    let avg = sortedResults.map(\.percentage).reduce(0, +) / Double(sortedResults.count)
                    let highest = sortedResults.map(\.percentage).max() ?? 0
                    let lowest = sortedResults.map(\.percentage).min() ?? 0

                    HStack(spacing: 20) {
                        miniStat(
                            value: String(format: "%.0f%%", avg),
                            label: String(localized: "grade.chart.avg"),
                            color: .blue
                        )
                        miniStat(
                            value: String(format: "%.0f%%", highest),
                            label: String(localized: "grade.chart.highest"),
                            color: .green
                        )
                        miniStat(
                            value: String(format: "%.0f%%", lowest),
                            label: String(localized: "grade.chart.lowest"),
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "a11y.label.gradeProgressionChart \(sortedResults.count)"))
        } else {
            noDataView
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(String(localized: "grade.chart.noData"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func barColor(for average: Double) -> Color {
        switch average {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }

    private func pointColor(for percentage: Double) -> Color {
        switch percentage {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}
