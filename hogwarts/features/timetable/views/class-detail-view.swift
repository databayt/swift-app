import SwiftUI

/// Class detail sheet with class info and student list (for teachers)
/// Mirrors: src/components/platform/timetable/class-detail.tsx
struct ClassDetailView: View {
    let classDetail: ClassDetailResponse
    let capabilities: TimetableCapabilities

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Class info section
                Section(String(localized: "timetable.classInfo")) {
                    LabeledContent(
                        String(localized: "timetable.className"),
                        value: classDetail.displayName
                    )

                    if let subject = classDetail.displaySubject {
                        LabeledContent(
                            String(localized: "timetable.subject"),
                            value: subject
                        )
                    }

                    if let teacher = classDetail.teacherName {
                        LabeledContent(
                            String(localized: "timetable.teacher"),
                            value: teacher
                        )
                    }

                    if let room = classDetail.room {
                        LabeledContent(
                            String(localized: "timetable.room"),
                            value: room
                        )
                    }

                    if let count = classDetail.studentCount {
                        LabeledContent(
                            String(localized: "timetable.studentCount"),
                            value: "\(count)"
                        )
                    }
                }

                // Student list section (teachers/admin only)
                if capabilities.canViewStudentList,
                   let students = classDetail.students, !students.isEmpty {
                    Section(String(localized: "timetable.students")) {
                        ForEach(students) { student in
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: student.imageUrl ?? "")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(student.displayName)
                                        .font(.subheadline)
                                    if let gr = student.grNumber {
                                        Text(gr)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "timetable.classDetail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
