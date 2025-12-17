import SwiftUI

/// Students table/list view
/// Mirrors: src/components/platform/students/table.tsx
struct StudentsTable: View {
    let rows: [StudentRow]
    let onSelect: (StudentRow) -> Void
    let onDelete: ([StudentRow]) -> Void

    @State private var selection = Set<String>()
    @State private var sortOrder = [KeyPathComparator(\StudentRow.name)]

    var body: some View {
        List(selection: $selection) {
            ForEach(rows) { row in
                StudentRowView(row: row)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(row)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDelete([row])
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }

                        Button {
                            onSelect(row)
                        } label: {
                            Label(String(localized: "common.edit"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }

            if !selection.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        let selectedRows = rows.filter { selection.contains($0.id) }
                        onDelete(selectedRows)
                        selection.removeAll()
                    } label: {
                        Label(
                            String(localized: "common.delete"),
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Student Row View

struct StudentRowView: View {
    let row: StudentRow

    @Environment(\.locale) private var locale

    private var displayName: String {
        if locale.language.languageCode?.identifier == "ar" {
            return row.nameAr ?? row.name
        }
        return row.name
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: row.photoUrl ?? "")) { image in
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
                Text(displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(row.grNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let yearLevel = row.yearLevel {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(yearLevel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Status badge
            StatusBadge(status: row.status)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: StudentStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .active:
            return .green.opacity(0.2)
        case .inactive:
            return .gray.opacity(0.2)
        case .graduated:
            return .blue.opacity(0.2)
        case .transferred:
            return .orange.opacity(0.2)
        case .suspended:
            return .red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .active:
            return .green
        case .inactive:
            return .gray
        case .graduated:
            return .blue
        case .transferred:
            return .orange
        case .suspended:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudentsTable(
            rows: [
                StudentRow(from: Student(
                    id: "1",
                    grNumber: "GR001",
                    userId: "u1",
                    schoolId: "s1",
                    yearLevelId: nil,
                    batchId: nil,
                    status: "ACTIVE",
                    givenName: "Ahmed",
                    surname: "Mohamed",
                    givenNameAr: "أحمد",
                    surnameAr: "محمد",
                    dateOfBirth: nil,
                    gender: "MALE",
                    nationality: nil,
                    photoUrl: nil,
                    email: "ahmed@school.com",
                    phone: nil,
                    address: nil,
                    bloodType: nil,
                    allergies: nil,
                    medicalConditions: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    user: nil,
                    yearLevel: YearLevel(id: "yl1", name: "Grade 10", nameAr: "الصف العاشر", order: 10)
                ))
            ],
            onSelect: { _ in },
            onDelete: { _ in }
        )
    }
}
