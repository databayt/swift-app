import SwiftUI

/// ViewModel for school selection screen
/// Handles fetching schools, selection, and caching last school
@Observable
@MainActor
final class SchoolSelectionViewModel {
    private let api = APIClient.shared
    private let keychain = KeychainService()

    var schools: [School] = []
    var isLoading = false
    var error: Error?

    /// Last selected school ID from keychain
    var lastSchoolId: String? {
        keychain.get(.lastSchoolId)
    }

    /// Load schools for the current user
    func loadSchools() async {
        isLoading = true
        defer { isLoading = false }

        do {
            schools = try await api.get("/auth/schools", as: [School].self)
        } catch {
            self.error = error
        }
    }

    /// Select a school and update tenant context
    func selectSchool(_ school: School, tenantContext: TenantContext) {
        tenantContext.setTenant(schoolId: school.id, school: school)
        try? keychain.save(school.id, for: .lastSchoolId)
    }
}
