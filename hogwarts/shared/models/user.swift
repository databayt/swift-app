import Foundation
import SwiftData

/// User model
/// Mirrors: prisma/models/auth.prisma User model
@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var email: String
    var name: String?
    var nameAr: String?
    var role: String
    var schoolId: String?
    var imageUrl: String?
    var phone: String?
    var emailVerified: Date?
    var isTwoFactorEnabled: Bool

    // Sync metadata
    var lastSyncedAt: Date?

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }

    init(
        id: String,
        email: String,
        name: String? = nil,
        role: UserRole = .user,
        schoolId: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role.rawValue
        self.schoolId = schoolId
        self.isTwoFactorEnabled = false
    }
}

// MARK: - API Response Model

/// User response from API
struct User: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let name: String?
    let nameAr: String?
    let role: String
    let schoolId: String?
    let imageUrl: String?
    let phone: String?
    let emailVerified: Date?
    let isTwoFactorEnabled: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    var userRole: UserRole {
        UserRole(rawValue: role) ?? .user
    }

    var displayName: String {
        name ?? email
    }
}

// MARK: - User Role

/// User roles
/// Mirrors: prisma/models/auth.prisma UserRole enum
enum UserRole: String, Codable, CaseIterable {
    case developer = "DEVELOPER"
    case admin = "ADMIN"
    case teacher = "TEACHER"
    case student = "STUDENT"
    case guardian = "GUARDIAN"
    case accountant = "ACCOUNTANT"
    case staff = "STAFF"
    case user = "USER"

    var displayName: String {
        switch self {
        case .developer: return String(localized: "role.developer")
        case .admin: return String(localized: "role.admin")
        case .teacher: return String(localized: "role.teacher")
        case .student: return String(localized: "role.student")
        case .guardian: return String(localized: "role.guardian")
        case .accountant: return String(localized: "role.accountant")
        case .staff: return String(localized: "role.staff")
        case .user: return String(localized: "role.user")
        }
    }

    /// Check if role has admin-level access
    var isAdmin: Bool {
        self == .developer || self == .admin
    }

    /// Check if role is staff (can manage school data)
    var isStaff: Bool {
        switch self {
        case .developer, .admin, .teacher, .accountant, .staff:
            return true
        default:
            return false
        }
    }
}
