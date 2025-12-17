import SwiftUI

/// Tenant context for multi-tenant isolation
/// Mirrors: src/lib/tenant-context.ts
/// CRITICAL: All API requests must include schoolId
@Observable
final class TenantContext {
    /// Current school ID (tenant identifier)
    var schoolId: String?

    /// Current school details
    var school: School?

    /// School subdomain
    var subdomain: String?

    /// Check if tenant context is valid
    var isValid: Bool {
        schoolId != nil
    }

    /// Set tenant from session
    func setTenant(schoolId: String, school: School? = nil) {
        self.schoolId = schoolId
        self.school = school
        self.subdomain = school?.domain
    }

    /// Clear tenant (on logout)
    func clear() {
        schoolId = nil
        school = nil
        subdomain = nil
    }
}

/// School model for tenant context
/// Mirrors: prisma/models/school.prisma
struct School: Codable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let domain: String
    let email: String?
    let phone: String?
    let logoUrl: String?
    let plan: SchoolPlan?
    let maxStudents: Int?
    let maxTeachers: Int?

    enum SchoolPlan: String, Codable {
        case basic = "BASIC"
        case premium = "PREMIUM"
        case enterprise = "ENTERPRISE"
    }
}
