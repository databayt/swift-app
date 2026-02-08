import Foundation
import Testing
@testable import Hogwarts

/// Tests for Profile feature types, validation, and preferences
@Suite("Profile")
struct ProfileTests {

    // MARK: - AppTheme

    @Test("AppTheme system rawValue")
    func themeSystemRaw() {
        #expect(AppTheme.system.rawValue == "system")
    }

    @Test("AppTheme light rawValue")
    func themeLightRaw() {
        #expect(AppTheme.light.rawValue == "light")
    }

    @Test("AppTheme dark rawValue")
    func themeDarkRaw() {
        #expect(AppTheme.dark.rawValue == "dark")
    }

    @Test("AppTheme has 3 cases")
    func themeCaseCount() {
        #expect(AppTheme.allCases.count == 3)
    }

    @Test("AppTheme icons are correct")
    func themeIcons() {
        #expect(AppTheme.system.icon == "gear")
        #expect(AppTheme.light.icon == "sun.max")
        #expect(AppTheme.dark.icon == "moon")
    }

    @Test("AppTheme displayName is non-empty for all cases")
    func themeDisplayNames() {
        for theme in AppTheme.allCases {
            #expect(!theme.displayName.isEmpty)
        }
    }

    @Test("AppTheme can be initialized from rawValue")
    func themeFromRawValue() {
        #expect(AppTheme(rawValue: "light") == .light)
        #expect(AppTheme(rawValue: "dark") == .dark)
        #expect(AppTheme(rawValue: "system") == .system)
    }

    @Test("AppTheme invalid rawValue returns nil")
    func themeInvalidRawValue() {
        #expect(AppTheme(rawValue: "invalid") == nil)
    }

    // MARK: - NotificationPreferences

    @Test("NotificationPreferences default has all enabled")
    func defaultPreferences() {
        let prefs = NotificationPreferences.default
        #expect(prefs.attendance)
        #expect(prefs.grade)
        #expect(prefs.message)
        #expect(prefs.announcement)
        #expect(prefs.system)
    }

    @Test("NotificationPreferences can be modified")
    func modifyPreferences() {
        var prefs = NotificationPreferences.default
        prefs.attendance = false
        prefs.grade = false
        #expect(!prefs.attendance)
        #expect(!prefs.grade)
        #expect(prefs.message)
    }

    // MARK: - ProfileValidation

    @Test("ProfileValidation accepts valid profile data")
    func validateProfileValid() {
        let result = ProfileValidation.validateUpdateProfile(
            name: "Harry Potter",
            nameAr: "هاري بوتر",
            phone: "+966501234567"
        )
        #expect(result.isValid)
        #expect(result.errors.isEmpty)
    }

    @Test("ProfileValidation rejects empty name")
    func validateProfileEmptyName() {
        let result = ProfileValidation.validateUpdateProfile(
            name: "   ",
            nameAr: nil,
            phone: nil
        )
        #expect(!result.isValid)
        #expect(result.errors["name"] != nil)
    }

    @Test("ProfileValidation rejects name over 100 chars")
    func validateProfileLongName() {
        let longName = String(repeating: "a", count: 101)
        let result = ProfileValidation.validateUpdateProfile(
            name: longName,
            nameAr: nil,
            phone: nil
        )
        #expect(!result.isValid)
        #expect(result.errors["name"] != nil)
    }

    @Test("ProfileValidation rejects invalid phone")
    func validateProfileInvalidPhone() {
        let result = ProfileValidation.validateUpdateProfile(
            name: "Harry",
            nameAr: nil,
            phone: "abc"
        )
        #expect(!result.isValid)
        #expect(result.errors["phone"] != nil)
    }

    @Test("ProfileValidation accepts nil phone")
    func validateProfileNilPhone() {
        let result = ProfileValidation.validateUpdateProfile(
            name: "Harry",
            nameAr: nil,
            phone: nil
        )
        #expect(result.isValid)
    }

    @Test("ProfileValidation accepts empty phone")
    func validateProfileEmptyPhone() {
        let result = ProfileValidation.validateUpdateProfile(
            name: "Harry",
            nameAr: nil,
            phone: ""
        )
        #expect(result.isValid)
    }

    @Test("ProfileValidation rejects nameAr over 100 chars")
    func validateProfileLongNameAr() {
        let longNameAr = String(repeating: "ا", count: 101)
        let result = ProfileValidation.validateUpdateProfile(
            name: "Harry",
            nameAr: longNameAr,
            phone: nil
        )
        #expect(!result.isValid)
        #expect(result.errors["nameAr"] != nil)
    }

    // MARK: - UserRole

    @Test("UserRole isAdmin returns true for developer and admin")
    func userRoleIsAdmin() {
        #expect(UserRole.developer.isAdmin)
        #expect(UserRole.admin.isAdmin)
        #expect(!UserRole.teacher.isAdmin)
        #expect(!UserRole.student.isAdmin)
    }

    @Test("UserRole isStaff returns true for staff roles")
    func userRoleIsStaff() {
        #expect(UserRole.developer.isStaff)
        #expect(UserRole.admin.isStaff)
        #expect(UserRole.teacher.isStaff)
        #expect(UserRole.accountant.isStaff)
        #expect(UserRole.staff.isStaff)
        #expect(!UserRole.student.isStaff)
        #expect(!UserRole.guardian.isStaff)
        #expect(!UserRole.user.isStaff)
    }

    @Test("UserRole rawValues match backend enum")
    func userRoleRawValues() {
        #expect(UserRole.developer.rawValue == "DEVELOPER")
        #expect(UserRole.admin.rawValue == "ADMIN")
        #expect(UserRole.teacher.rawValue == "TEACHER")
        #expect(UserRole.student.rawValue == "STUDENT")
        #expect(UserRole.guardian.rawValue == "GUARDIAN")
        #expect(UserRole.accountant.rawValue == "ACCOUNTANT")
        #expect(UserRole.staff.rawValue == "STAFF")
        #expect(UserRole.user.rawValue == "USER")
    }
}
