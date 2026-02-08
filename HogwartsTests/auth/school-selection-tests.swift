import Foundation
import Testing
@testable import Hogwarts

/// Tests for School Selection (AUTH-004)
@Suite("School Selection")
struct SchoolSelectionTests {

    @Test("School decodes from JSON")
    func schoolDecode() throws {
        let json = """
        {
            "id": "school-1",
            "name": "Hogwarts Academy",
            "nameAr": "أكاديمية هوغوارتس",
            "domain": "hogwarts",
            "email": "info@hogwarts.edu",
            "phone": "+1234567890",
            "logoUrl": "https://example.com/logo.png",
            "plan": "PREMIUM",
            "maxStudents": 500,
            "maxTeachers": 50
        }
        """.data(using: .utf8)!

        let school = try JSONDecoder().decode(School.self, from: json)
        #expect(school.id == "school-1")
        #expect(school.name == "Hogwarts Academy")
        #expect(school.nameAr == "أكاديمية هوغوارتس")
        #expect(school.domain == "hogwarts")
        #expect(school.plan == .premium)
        #expect(school.maxStudents == 500)
    }

    @Test("School decodes with minimal fields")
    func schoolDecodeMinimal() throws {
        let json = """
        {
            "id": "school-2",
            "name": "Test School",
            "domain": "test"
        }
        """.data(using: .utf8)!

        let school = try JSONDecoder().decode(School.self, from: json)
        #expect(school.id == "school-2")
        #expect(school.nameAr == nil)
        #expect(school.plan == nil)
        #expect(school.logoUrl == nil)
    }

    @Test("TenantContext setTenant updates all fields")
    @MainActor
    func setTenant() {
        let context = TenantContext()
        let school = try! JSONDecoder().decode(
            School.self,
            from: """
            {"id":"s1","name":"Test","domain":"test"}
            """.data(using: .utf8)!
        )

        context.setTenant(schoolId: "s1", school: school)

        #expect(context.schoolId == "s1")
        #expect(context.school?.name == "Test")
        #expect(context.subdomain == "test")
        #expect(context.isValid)
    }

    @Test("TenantContext clear resets all fields")
    @MainActor
    func clearTenant() {
        let context = TenantContext()
        context.setTenant(schoolId: "s1")

        context.clear()

        #expect(context.schoolId == nil)
        #expect(context.school == nil)
        #expect(context.subdomain == nil)
        #expect(!context.isValid)
    }

    @Test("SchoolPlan raw values are uppercase")
    func schoolPlanValues() {
        #expect(School.SchoolPlan.basic.rawValue == "BASIC")
        #expect(School.SchoolPlan.premium.rawValue == "PREMIUM")
        #expect(School.SchoolPlan.enterprise.rawValue == "ENTERPRISE")
    }

    @Test("Keychain Key includes lastSchoolId")
    func keychainKeyExists() {
        let key = KeychainService.Key.lastSchoolId
        #expect(key.rawValue == "com.hogwarts.lastSchoolId")
    }
}
