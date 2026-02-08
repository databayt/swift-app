import SwiftUI
import Charts

/// Attendance charts — donut breakdown + trend line
/// Mirrors: Attendance analytics visualization
struct AttendanceChartsView: View {
    let stats: AttendanceStatsDisplay
    let records: [AttendanceRow]

    @State private var selectedChart: ChartType = .breakdown

    enum ChartType: String, CaseIterable {
        case breakdown
        case trend

        var label: String {
            switch self {
            case .breakdown: return String(localized: "attendance.chart.breakdown")
            case .trend: return String(localized: "attendance.chart.trend")
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Chart type picker
            Picker(String(localized: "attendance.chart.type"), selection: $selectedChart) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(String(localized: "a11y.attendance.chartType"))
            .padding(.horizontal)

            switch selectedChart {
            case .breakdown:
                breakdownChart
            case .trend:
                trendChart
            }
        }
    }

    // MARK: - Breakdown Donut Chart

    @ViewBuilder
    private var breakdownChart: some View {
        let data = stats.breakdown
        if !data.isEmpty {
            VStack(spacing: 16) {
                Text(String(localized: "attendance.chart.breakdown"))
                    .font(.headline)

                Chart(data, id: \.status) { item in
                    SectorMark(
                        angle: .value(item.status.displayName, item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(statusColor(item.status))
                    .annotation(position: .overlay) {
                        if item.percentage > 5 {
                            Text("\(Int(item.percentage))%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "a11y.attendance.breakdownChart \(Int(stats.attendanceRate))"))

                // Center label
                .overlay {
                    VStack(spacing: 2) {
                        Text("\(Int(stats.attendanceRate))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(String(localized: "attendance.stats.rate"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Legend
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(data, id: \.status) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor(item.status))
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                            Text(item.status.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.status.displayName): \(item.count)")
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        } else {
            noDataView
        }
    }

    // MARK: - Trend Line Chart

    @ViewBuilder
    private var trendChart: some View {
        let weeklyData = computeWeeklyTrend()
        if !weeklyData.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "attendance.chart.trend"))
                    .font(.headline)
                    .padding(.horizontal)

                Chart(weeklyData) { point in
                    LineMark(
                        x: .value(String(localized: "attendance.chart.week"), point.weekLabel),
                        y: .value(String(localized: "attendance.chart.rate"), point.rate)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value(String(localized: "attendance.chart.week"), point.weekLabel),
                        y: .value(String(localized: "attendance.chart.rate"), point.rate)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value(String(localized: "attendance.chart.week"), point.weekLabel),
                        y: .value(String(localized: "attendance.chart.rate"), point.rate)
                    )
                    .foregroundStyle(point.rate >= 90 ? .green : .orange)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)%")
                            }
                        }
                    }
                }
                .frame(height: 220)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "a11y.attendance.trendChart"))
                .padding(.horizontal)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        } else {
            noDataView
        }
    }

    // MARK: - Helpers

    private struct WeeklyPoint: Identifiable {
        let id = UUID()
        let weekLabel: String
        let rate: Double
    }

    private func computeWeeklyTrend() -> [WeeklyPoint] {
        let calendar = Calendar.current
        let sortedRecords = records.sorted { $0.date < $1.date }

        guard !sortedRecords.isEmpty else { return [] }

        // Group records by week
        var weekGroups: [(week: Int, records: [AttendanceRow])] = []
        var currentWeek: Int?
        var currentGroup: [AttendanceRow] = []

        for record in sortedRecords {
            let week = calendar.component(.weekOfYear, from: record.date)
            if week != currentWeek {
                if let w = currentWeek, !currentGroup.isEmpty {
                    weekGroups.append((week: w, records: currentGroup))
                }
                currentWeek = week
                currentGroup = [record]
            } else {
                currentGroup.append(record)
            }
        }
        if let w = currentWeek, !currentGroup.isEmpty {
            weekGroups.append((week: w, records: currentGroup))
        }

        // Compute rate per week
        return weekGroups.suffix(12).map { group in
            let total = group.records.count
            let present = group.records.filter { $0.status == .present || $0.status == .late }.count
            let rate = total > 0 ? Double(present) / Double(total) * 100 : 0
            return WeeklyPoint(
                weekLabel: String(localized: "attendance.chart.weekLabel \(group.week)"),
                rate: rate
            )
        }
    }

    @ViewBuilder
    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(String(localized: "attendance.chart.noData"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
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
