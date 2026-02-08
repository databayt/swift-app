import SwiftUI

/// Excuse list view — shows submitted excuses for guardian, pending excuses for teacher/admin
/// Mirrors: src/components/platform/attendance/excuse-list.tsx
struct ExcuseListView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(TenantContext.self) private var tenantContext

    @State private var excuses: [AttendanceExcuse] = []
    @State private var isLoading = true
    @State private var error: Error?

    private let actions = AttendanceActions()

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if excuses.isEmpty {
                EmptyStateView(
                    title: String(localized: "excuse.empty.title"),
                    message: String(localized: "excuse.empty.message"),
                    systemImage: "doc.text"
                )
            } else {
                List {
                    ForEach(excuses) { excuse in
                        ExcuseRow(
                            excuse: excuse,
                            canReview: canReview,
                            onApprove: { await reviewExcuse(excuse, approved: true) },
                            onReject: { await reviewExcuse(excuse, approved: false) }
                        )
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadExcuses()
                }
            }
        }
        .navigationTitle(String(localized: "excuse.title"))
        .task {
            await loadExcuses()
        }
    }

    // MARK: - Computed

    private var canReview: Bool {
        let role = authManager.role
        return role == .teacher || role == .admin || role == .developer
    }

    // MARK: - Actions

    private func loadExcuses() async {
        guard let schoolId = tenantContext.schoolId else {
            isLoading = false
            return
        }

        do {
            if canReview {
                // Teacher/Admin sees pending excuses
                excuses = try await actions.getPendingExcuses(schoolId: schoolId)
            } else {
                // Guardian sees their submitted excuses
                let studentId = authManager.currentUser?.id ?? ""
                excuses = try await actions.getStudentExcuses(
                    studentId: studentId,
                    schoolId: schoolId
                )
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func reviewExcuse(_ excuse: AttendanceExcuse, approved: Bool) async {
        guard let schoolId = tenantContext.schoolId else { return }

        let request = ExcuseReviewRequest(
            excuseId: excuse.id,
            status: approved ? "APPROVED" : "REJECTED",
            reviewNotes: nil
        )

        _ = try? await actions.reviewExcuse(request, schoolId: schoolId)
        await loadExcuses()
    }
}

// MARK: - Excuse Row

struct ExcuseRow: View {
    let excuse: AttendanceExcuse
    let canReview: Bool
    let onApprove: () async -> Void
    let onReject: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: date + status
            HStack {
                Text(excuse.date, style: .date)
                    .font(.headline)

                Spacer()

                statusBadge
            }

            // Reason
            Text(excuse.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Document indicator
            if excuse.documentUrl != nil {
                Label(
                    String(localized: "excuse.hasDocument"),
                    systemImage: "paperclip"
                )
                .font(.caption)
                .foregroundStyle(.blue)
            }

            // Review actions (for teacher/admin on pending excuses)
            if canReview && excuse.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        Task { await onApprove() }
                    } label: {
                        Label(
                            String(localized: "excuse.action.approve"),
                            systemImage: "checkmark.circle"
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)

                    Button {
                        Task { await onReject() }
                    } label: {
                        Label(
                            String(localized: "excuse.action.reject"),
                            systemImage: "xmark.circle"
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(excuse.status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch excuse.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}
