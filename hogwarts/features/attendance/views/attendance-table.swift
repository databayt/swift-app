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

    private var attendanceByDate: [Date: AttendanceStatus] {
        let calendar = Calendar.current
        var result: [Date: AttendanceStatus] = [:]
        for row in rows {
            let day = calendar.startOfDay(for: row.date)
            result[day] = row.status
        }
        return result
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button {
                    selectedDate = Calendar.current.date(
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
                    selectedDate = Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: selectedDate
                    ) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: AttendanceStatus.present.displayName)
                LegendItem(color: .red, label: AttendanceStatus.absent.displayName)
                LegendItem(color: .orange, label: AttendanceStatus.late.displayName)
            }
            .font(.caption)

            // Calendar grid would go here
            // This is a simplified version - full implementation would need a calendar grid
            Text(String(localized: "attendance.calendar.placeholder"))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
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
