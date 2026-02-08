import SwiftUI

/// Daily timeline view with current-time indicator
/// Mirrors: src/components/platform/timetable/day-view.tsx
struct TimetableDayView: View {
    @Bindable var viewModel: TimetableViewModel

    /// Working days for day selector
    private let workingDays: [DayOfWeek] = [
        .sunday, .monday, .tuesday, .wednesday, .thursday
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workingDays, id: \.self) { day in
                        DaySelectorChip(
                            day: day,
                            isSelected: viewModel.selectedDay == day,
                            isToday: day == DayOfWeek.today
                        ) {
                            viewModel.selectDay(day)
                        }
                        .accessibilityLabel(String(localized: "a11y.timetable.daySelector \(day.shortName)"))
                        .accessibilityHint(viewModel.selectedDay == day ? String(localized: "a11y.timetable.daySelected") : String(localized: "a11y.timetable.dayTapToSelect"))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            Divider()

            // Timeline
            if viewModel.entriesForSelectedDay.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(String(localized: "timetable.noClasses"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.entriesForSelectedDay) { entry in
                            DayTimelineRow(
                                entry: entry,
                                capabilities: viewModel.capabilities
                            )
                            .onTapGesture {
                                viewModel.showDetail(for: entry)
                            }

                            if entry.id != viewModel.entriesForSelectedDay.last?.id {
                                TimelineConnector()
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }
}

// MARK: - Day Selector Chip

struct DaySelectorChip: View {
    let day: DayOfWeek
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)

                if isToday {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline Row

struct DayTimelineRow: View {
    let entry: TimetableEntry
    let capabilities: TimetableCapabilities

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.startTime)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(entry.endTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "a11y.timetable.timeRange \(entry.startTime) \(entry.endTime)"))

            // Period indicator
            Circle()
                .fill(.blue)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
                .accessibilityHidden(true)

            // Entry card
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    if let room = entry.classroomName {
                        Label(room, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let teacher = entry.teacherName {
                        Label(teacher, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let period = entry.periodNumber {
                    Text(String(localized: "timetable.period") + " \(period)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Timeline Connector

struct TimelineConnector: View {
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
                .frame(width: 50)

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 4)

            Spacer()
        }
        .accessibilityHidden(true)
    }
}
