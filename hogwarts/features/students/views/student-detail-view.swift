import SwiftUI

/// Student detail view with tabs
/// Mirrors: src/components/platform/students/detail.tsx
struct StudentDetailView: View {
    let student: Student
    let yearLevels: [YearLevel]
    let onEdit: (Student) -> Void

    @Environment(TenantContext.self) private var tenantContext
    @State private var selectedTab = 0
    @State private var attendanceStats: AttendanceStats?
    @State private var recentResults: [ExamResult] = []
    @State private var isLoadingAttendance = true
    @State private var isLoadingGrades = true

    private let attendanceActions = AttendanceActions()
    private let gradesActions = GradesActions()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                studentHeader

                // Tab selector
                Picker(String(localized: "student.detail.view"), selection: $selectedTab) {
                    Text(String(localized: "student.detail.tab.info")).tag(0)
                    Text(String(localized: "student.detail.tab.attendance")).tag(1)
                    Text(String(localized: "student.detail.tab.grades")).tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                switch selectedTab {
                case 0:
                    infoSection
                case 1:
                    attendanceSection
                case 2:
                    gradesSection
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .navigationTitle(student.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onEdit(student)
                } label: {
                    Text(String(localized: "common.edit"))
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var studentHeader: some View {
        VStack(spacing: 12) {
            // Photo
            AsyncImage(url: URL(string: student.photoUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            // Name
            VStack(spacing: 4) {
                Text(student.fullName)
                    .font(.title2)
                    .fontWeight(.bold)

                if let nameAr = [student.givenNameAr, student.surnameAr].compactMap({ $0 }).joined(separator: " ") as String?,
                   !nameAr.isEmpty {
                    Text(nameAr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Badges
            HStack(spacing: 12) {
                // GR Number
                Label(student.grNumber, systemImage: "number")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())

                // Status
                Text(student.studentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                // Year level
                if let yearLevel = student.yearLevel {
                    Label(yearLevel.name, systemImage: "graduationcap")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Info Section

    @ViewBuilder
    private var infoSection: some View {
        VStack(spacing: 16) {
            // Personal info
            DetailSection(title: String(localized: "student.detail.personal")) {
                if let dob = student.dateOfBirth {
                    DetailRow(label: String(localized: "student.form.dateOfBirth"), value: dob.formatted(date: .long, time: .omitted))
                }
                if let gender = student.gender {
                    DetailRow(label: String(localized: "student.form.gender"), value: gender == "MALE" ? String(localized: "gender.male") : String(localized: "gender.female"))
                }
                if let nationality = student.nationality {
                    DetailRow(label: String(localized: "student.form.nationality"), value: nationality)
                }
            }

            // Contact info
            DetailSection(title: String(localized: "student.detail.contact")) {
                if let email = student.email {
                    DetailRow(label: String(localized: "student.form.email"), value: email, icon: "envelope")
                }
                if let phone = student.phone {
                    DetailRow(label: String(localized: "student.form.phone"), value: phone, icon: "phone")
                }
                if let address = student.address {
                    DetailRow(label: String(localized: "student.form.address"), value: address, icon: "mappin")
                }
            }

            // Medical info
            if student.bloodType != nil || student.allergies != nil || student.medicalConditions != nil {
                DetailSection(title: String(localized: "student.detail.medical")) {
                    if let bloodType = student.bloodType {
                        DetailRow(label: String(localized: "student.detail.bloodType"), value: bloodType, icon: "drop.fill")
                    }
                    if let allergies = student.allergies {
                        DetailRow(label: String(localized: "student.detail.allergies"), value: allergies, icon: "exclamationmark.triangle")
                    }
                    if let conditions = student.medicalConditions {
                        DetailRow(label: String(localized: "student.detail.medicalConditions"), value: conditions, icon: "heart.text.clipboard")
                    }
                }
            }
        }
    }

    // MARK: - Attendance Section

    @ViewBuilder
    private var attendanceSection: some View {
        if isLoadingAttendance {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
        } else if let stats = attendanceStats {
            let display = AttendanceStatsDisplay(from: stats)
            AttendanceStatsCard(stats: display)
        } else {
            Text(String(localized: "student.detail.noAttendance"))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        }
    }

    // MARK: - Grades Section

    @ViewBuilder
    private var gradesSection: some View {
        if isLoadingGrades {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
        } else if recentResults.isEmpty {
            Text(String(localized: "student.detail.noGrades"))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "student.detail.recentResults"))
                    .font(.headline)

                ForEach(recentResults.prefix(10)) { result in
                    let row = ExamResultRow(from: result)
                    ExamResultRowView(row: row)
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let schoolId = tenantContext.schoolId else { return }

        async let statsResult: () = loadAttendanceStats(schoolId: schoolId)
        async let gradesResult: () = loadGrades(schoolId: schoolId)
        _ = await (statsResult, gradesResult)
    }

    private func loadAttendanceStats(schoolId: String) async {
        do {
            attendanceStats = try await attendanceActions.getStats(
                studentId: student.id,
                schoolId: schoolId
            )
        } catch {
            print("Failed to load attendance stats: \(error)")
        }
        isLoadingAttendance = false
    }

    private func loadGrades(schoolId: String) async {
        do {
            let response = try await gradesActions.getStudentResults(
                studentId: student.id,
                schoolId: schoolId
            )
            recentResults = response.data
        } catch {
            print("Failed to load grades: \(error)")
        }
        isLoadingGrades = false
    }

    private var statusColor: Color {
        switch student.studentStatus {
        case .active: return .green
        case .inactive: return .gray
        case .graduated: return .blue
        case .transferred: return .orange
        case .suspended: return .red
        }
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudentDetailView(
            student: Student(
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
                nationality: "Saudi",
                photoUrl: nil,
                email: "ahmed@test.com",
                phone: "+966501234567",
                address: "Riyadh",
                bloodType: "A+",
                allergies: nil,
                medicalConditions: nil,
                createdAt: nil,
                updatedAt: nil,
                user: nil,
                yearLevel: YearLevel(id: "yl1", name: "Grade 10", nameAr: "الصف العاشر", order: 10)
            ),
            yearLevels: [],
            onEdit: { _ in }
        )
        .environment(TenantContext())
    }
}
