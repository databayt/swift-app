import SwiftUI

/// Class detail sheet with class info and student list (for teachers)
/// Mirrors: src/components/platform/timetable/class-detail.tsx
struct ClassDetailView: View {
    let classDetail: ClassDetailResponse
    let capabilities: TimetableCapabilities

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Class Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "timetable.classInfo"))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 8) {
                            InfoRow(
                                label: String(localized: "timetable.className"),
                                value: classDetail.displayName
                            )

                            if let subject = classDetail.displaySubject {
                                InfoRow(
                                    label: String(localized: "timetable.subject"),
                                    value: subject
                                )
                            }

                            if let teacher = classDetail.teacherName {
                                InfoRow(
                                    label: String(localized: "timetable.teacher"),
                                    value: teacher
                                )
                            }

                            if let room = classDetail.room {
                                InfoRow(
                                    label: String(localized: "timetable.room"),
                                    value: room
                                )
                            }

                            if let count = classDetail.studentCount {
                                InfoRow(
                                    label: String(localized: "timetable.studentCount"),
                                    value: "\(count)"
                                )
                            }
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

                    // Students List Card (teachers/admin only)
                    if capabilities.canViewStudentList,
                       let students = classDetail.students, !students.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "timetable.students") + " (\(students.count))")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 0) {
                                ForEach(students) { student in
                                    StudentRowGlass(student: student)

                                    if student.id != students.last?.id {
                                        Divider()
                                            .padding(.leading, 52)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.quaternary, lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "timetable.classDetail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .accessibilityLabel(String(localized: "a11y.button.done"))
                }
            }
        }
    }
}

// MARK: - Helper Components

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct StudentRowGlass: View {
    let student: ClassStudent

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: student.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.quaternary, lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(student.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let gr = student.grNumber {
                    Text(gr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
