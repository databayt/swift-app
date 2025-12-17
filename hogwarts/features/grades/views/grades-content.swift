import SwiftUI

/// Grades view
/// Mirrors: src/components/platform/grades/content.tsx
struct GradesContent: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "grades.current")) {
                    Text("Current semester grades")
                        .foregroundStyle(.secondary)
                }

                Section(String(localized: "grades.history")) {
                    Text("Past grades")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "grades.title"))
        }
    }
}

#Preview {
    GradesContent()
        .environment(AuthManager())
}
