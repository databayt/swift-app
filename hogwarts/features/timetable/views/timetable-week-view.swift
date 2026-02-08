import SwiftUI

/// Weekly grid view for timetable (7 cols x N period rows)
/// Mirrors: src/components/platform/timetable/week-view.tsx
struct TimetableWeekView: View {
    @Bindable var viewModel: TimetableViewModel

    /// Working days to display (Sunday-Thursday for Arabic schools)
    private let workingDays: [DayOfWeek] = [
        .sunday, .monday, .tuesday, .wednesday, .thursday
    ]

    /// Max period number across all entries
    private var maxPeriod: Int {
        let max = viewModel.entries.compactMap(\.periodNumber).max() ?? 0
        return Swift.max(max, 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Day header row
                HStack(spacing: 0) {
                    // Period column header
                    Text(String(localized: "timetable.period"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)

                    ForEach(workingDays, id: \.self) { day in
                        Text(day.shortName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(day == DayOfWeek.today ? .blue : .primary)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(day == DayOfWeek.today ? String(localized: "a11y.timetable.todayColumn \(day.shortName)") : day.shortName)
                    }
                }
                .padding(.vertical, 8)
                .background(.quaternary)
                .accessibilityElement(children: .contain)

                Divider()

                // Period rows
                ForEach(1...maxPeriod, id: \.self) { period in
                    HStack(spacing: 0) {
                        // Period number
                        Text("\(period)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                            .accessibilityLabel(String(localized: "a11y.timetable.periodNumber \(period)"))

                        // Day cells
                        ForEach(workingDays, id: \.self) { day in
                            let entry = entryFor(day: day, period: period)
                            WeekCellView(
                                entry: entry,
                                isToday: day == DayOfWeek.today
                            )
                            .onTapGesture {
                                if let entry {
                                    viewModel.showDetail(for: entry)
                                }
                            }
                        }
                    }
                    .frame(minHeight: 60)

                    Divider()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    /// Find entry for a specific day and period
    private func entryFor(day: DayOfWeek, period: Int) -> TimetableEntry? {
        viewModel.entries.first { entry in
            entry.dayOfWeek == day.rawValue && entry.periodNumber == period
        }
    }
}

// MARK: - Week Cell

struct WeekCellView: View {
    let entry: TimetableEntry?
    let isToday: Bool

    var body: some View {
        Group {
            if let entry {
                VStack(spacing: 2) {
                    Text(entry.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    if let room = entry.classroomName {
                        Text(room)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isToday ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.displayName + (entry.classroomName.map { ", \($0)" } ?? ""))
                .accessibilityHint(String(localized: "a11y.timetable.tapForDetails"))
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .padding(2)
    }
}
