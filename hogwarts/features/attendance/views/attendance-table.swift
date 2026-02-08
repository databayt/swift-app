import SwiftUI

/// Attendance table/list view
/// Mirrors: src/components/platform/attendance/table.tsx
struct AttendanceTable: View {
    let rows: [AttendanceRow]
    var canEdit: Bool = false
    var onEdit: ((AttendanceRow) -> Void)?

    @State private var selection = Set<String>()

    var body: some View {
        List(selection: $selection) {
            ForEach(rows) { row in
                AttendanceRowView(row: row)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if canEdit {
                            onEdit?(row)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if canEdit {
                            Button {
                                onEdit?(row)
                            } label: {
                                Label(String(localized: "common.edit"), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Attendance Row View

struct AttendanceRowView: View {
    let row: AttendanceRow

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            // Student photo
            AsyncImage(url: URL(string: row.studentPhoto ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .accessibilityHidden(true)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(row.studentName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(row.grNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let className = row.className {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(className)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let periodName = row.periodName {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(periodName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Time marked
                if let markedAt = row.markedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(markedAt, style: .time)
                            .font(.caption2)
                        if let markedBy = row.markedByName {
                            Text("by \(markedBy)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Status badge
            AttendanceStatusBadge(status: row.status)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "a11y.attendance.row \(row.studentName) \(row.status.displayName)"))
    }
}

// MARK: - Attendance Status Badge

struct AttendanceStatusBadge: View {
    let status: AttendanceStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(Capsule())
        .accessibilityLabel(String(localized: "a11y.attendance.status \(status.displayName)"))
    }

    private var backgroundColor: Color {
        switch status {
        case .present:
            return .green.opacity(0.2)
        case .absent:
            return .red.opacity(0.2)
        case .late:
            return .orange.opacity(0.2)
        case .excused:
            return .blue.opacity(0.2)
        case .sick:
            return .purple.opacity(0.2)
        case .holiday:
            return .gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .present:
            return .green
        case .absent:
            return .red
        case .late:
            return .orange
        case .excused:
            return .blue
        case .sick:
            return .purple
        case .holiday:
            return .gray
        }
    }
}

// MARK: - Grouped Attendance Table

struct GroupedAttendanceTable: View {
    let rows: [AttendanceRow]
    var canEdit: Bool = false
    var onEdit: ((AttendanceRow) -> Void)?

    private var groupedByDate: [(Date, [AttendanceRow])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: rows) { row in
            calendar.startOfDay(for: row.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedByDate, id: \.0) { date, records in
                Section {
                    ForEach(records) { row in
                        AttendanceRowView(row: row)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if canEdit {
                                    onEdit?(row)
                                }
                            }
                    }
                } header: {
                    Text(date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Compact Attendance List

struct CompactAttendanceList: View {
    let rows: [AttendanceRow]

    var body: some View {
        ForEach(rows) { row in
            HStack(spacing: 8) {
                // Status icon
                Image(systemName: row.status.icon)
                    .foregroundStyle(statusColor(row.status))
                    .frame(width: 24)

                // Date
                Text(row.date, style: .date)
                    .font(.subheadline)

                Spacer()

                // Status text
                Text(row.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
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

// MARK: - Attendance Calendar View

struct AttendanceCalendarView: View {
    let rows: [AttendanceRow]
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let weekdays: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    private var attendanceByDate: [Date: AttendanceStatus] {
        var result: [Date: AttendanceStatus] = [:]
        for row in rows {
            let day = calendar.startOfDay(for: row.date)
            result[day] = row.status
        }
        return result
    }

    private var monthDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday
        let offset = firstWeekday >= 0 ? firstWeekday : firstWeekday + 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button {
                    selectedDate = calendar.date(
                        byAdding: .month,
                        value: -1,
                        to: selectedDate
                    ) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(.headline)

                Spacer()

                Button {
                    selectedDate = calendar.date(
                        byAdding: .month,
                        value: 1,
                        to: selectedDate
                    ) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            status: attendanceByDate[calendar.startOfDay(for: date)],
                            isToday: calendar.isDateInToday(date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: AttendanceStatus.present.displayName)
                LegendItem(color: .red, label: AttendanceStatus.absent.displayName)
                LegendItem(color: .orange, label: AttendanceStatus.late.displayName)
                LegendItem(color: .blue, label: AttendanceStatus.excused.displayName)
            }
            .font(.caption)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let status: AttendanceStatus?
    let isToday: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : .primary)

            if let status = status {
                Circle()
                    .fill(statusColor(status))
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(
            isToday ? Color.accentColor : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
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

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AttendanceTable(
            rows: [
                AttendanceRow(from: Attendance(
                    id: "1",
                    studentId: "s1",
                    classId: "c1",
                    periodId: nil,
                    date: Date(),
                    status: "PRESENT",
                    method: "MANUAL",
                    notes: nil,
                    schoolId: "school1",
                    markedById: "t1",
                    markedAt: Date(),
                    createdAt: nil,
                    updatedAt: nil,
                    student: StudentInfo(
                        id: "s1",
                        grNumber: "GR001",
                        givenName: "Ahmed",
                        surname: "Mohamed",
                        photoUrl: nil
                    ),
                    class_: ClassInfo(id: "c1", name: "Grade 10-A", nameAr: nil),
                    period: nil,
                    markedBy: UserInfo(id: "t1", name: "Mr. Smith", email: "smith@school.com")
                ))
            ],
            canEdit: true,
            onEdit: { _ in }
        )
    }
}
