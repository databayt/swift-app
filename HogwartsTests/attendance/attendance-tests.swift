import Foundation
import Testing
@testable import Hogwarts

/// Tests for Attendance feature types, validation, and capabilities
@Suite("Attendance")
struct AttendanceTests {

    // MARK: - AttendanceStatus Raw Values

    @Test("AttendanceStatus PRESENT rawValue")
    func presentRawValue() {
        #expect(AttendanceStatus.present.rawValue == "PRESENT")
    }

    @Test("AttendanceStatus ABSENT rawValue")
    func absentRawValue() {
        #expect(AttendanceStatus.absent.rawValue == "ABSENT")
    }

    @Test("AttendanceStatus LATE rawValue")
    func lateRawValue() {
        #expect(AttendanceStatus.late.rawValue == "LATE")
    }

    @Test("AttendanceStatus EXCUSED rawValue")
    func excusedRawValue() {
        #expect(AttendanceStatus.excused.rawValue == "EXCUSED")
    }

    @Test("AttendanceStatus SICK rawValue")
    func sickRawValue() {
        #expect(AttendanceStatus.sick.rawValue == "SICK")
    }

    @Test("AttendanceStatus HOLIDAY rawValue")
    func holidayRawValue() {
        #expect(AttendanceStatus.holiday.rawValue == "HOLIDAY")
    }

    @Test("AttendanceStatus has 6 cases")
    func statusCaseCount() {
        #expect(AttendanceStatus.allCases.count == 6)
    }

    // MARK: - AttendanceMethod Raw Values

    @Test("AttendanceMethod MANUAL rawValue")
    func manualMethodRawValue() {
        #expect(AttendanceMethod.manual.rawValue == "MANUAL")
    }

    @Test("AttendanceMethod QR_CODE rawValue")
    func qrCodeMethodRawValue() {
        #expect(AttendanceMethod.qrCode.rawValue == "QR_CODE")
    }

    // MARK: - AttendanceStats

    @Test("AttendanceStats attendanceRate calculation")
    func attendanceRateCalculation() {
        let stats = AttendanceStats(
            totalDays: 100,
            presentDays: 80,
            absentDays: 10,
            lateDays: 5,
            excusedDays: 3,
            sickDays: 2
        )
        // rate = (present + late) / total * 100 = (80 + 5) / 100 * 100 = 85
        #expect(stats.attendanceRate == 85.0)
    }

    @Test("AttendanceStats attendanceRate zero total days")
    func attendanceRateZeroDays() {
        let stats = AttendanceStats(
            totalDays: 0,
            presentDays: 0,
            absentDays: 0,
            lateDays: 0,
            excusedDays: 0,
            sickDays: 0
        )
        #expect(stats.attendanceRate == 0)
    }

    @Test("AttendanceStats presentPercentage calculation")
    func presentPercentageCalculation() {
        let stats = AttendanceStats(
            totalDays: 200,
            presentDays: 150,
            absentDays: 30,
            lateDays: 10,
            excusedDays: 5,
            sickDays: 5
        )
        #expect(stats.presentPercentage == 75.0)
    }

    @Test("AttendanceStats absentPercentage calculation")
    func absentPercentageCalculation() {
        let stats = AttendanceStats(
            totalDays: 200,
            presentDays: 150,
            absentDays: 30,
            lateDays: 10,
            excusedDays: 5,
            sickDays: 5
        )
        #expect(stats.absentPercentage == 15.0)
    }

    // MARK: - AttendanceStatsDisplay breakdown

    @Test("AttendanceStatsDisplay breakdown filters zero counts")
    func statsDisplayBreakdownFiltersZeros() {
        let stats = AttendanceStats(
            totalDays: 10,
            presentDays: 8,
            absentDays: 2,
            lateDays: 0,
            excusedDays: 0,
            sickDays: 0
        )
        let display = AttendanceStatsDisplay(from: stats)
        // Only present and absent should appear (late, excused, sick are 0)
        #expect(display.breakdown.count == 2)
    }

    @Test("AttendanceStatsDisplay breakdown percentages sum correctly")
    func statsDisplayBreakdownPercentages() {
        let stats = AttendanceStats(
            totalDays: 10,
            presentDays: 5,
            absentDays: 3,
            lateDays: 1,
            excusedDays: 1,
            sickDays: 0
        )
        let display = AttendanceStatsDisplay(from: stats)
        let totalPercentage = display.breakdown.reduce(0) { $0 + $1.percentage }
        #expect(totalPercentage == 100.0)
    }

    @Test("AttendanceStatsDisplay empty breakdown for zero total")
    func statsDisplayEmptyBreakdown() {
        let stats = AttendanceStats(
            totalDays: 0,
            presentDays: 0,
            absentDays: 0,
            lateDays: 0,
            excusedDays: 0,
            sickDays: 0
        )
        let display = AttendanceStatsDisplay(from: stats)
        #expect(display.breakdown.isEmpty)
    }

    // MARK: - AttendanceFilters queryParams

    @Test("AttendanceFilters default queryParams include page and pageSize")
    func filtersDefaultQueryParams() {
        let filters = AttendanceFilters()
        let params = filters.queryParams
        #expect(params["page"] == "1")
        #expect(params["pageSize"] == "20")
        #expect(params["sortBy"] == "date")
        #expect(params["sortOrder"] == "desc")
    }

    @Test("AttendanceFilters queryParams includes optional fields when set")
    func filtersQueryParamsWithOptionals() {
        var filters = AttendanceFilters()
        filters.studentId = "stu_123"
        filters.classId = "cls_456"
        filters.status = .absent
        let params = filters.queryParams
        #expect(params["studentId"] == "stu_123")
        #expect(params["classId"] == "cls_456")
        #expect(params["status"] == "ABSENT")
    }

    @Test("AttendanceFilters queryParams omits nil optional fields")
    func filtersQueryParamsOmitsNils() {
        let filters = AttendanceFilters()
        let params = filters.queryParams
        #expect(params["studentId"] == nil)
        #expect(params["classId"] == nil)
        #expect(params["status"] == nil)
        #expect(params["dateFrom"] == nil)
        #expect(params["dateTo"] == nil)
    }

    // MARK: - AttendanceCapabilities for roles

    @Test("Admin capabilities allow full access")
    func adminCapabilities() {
        let caps = AttendanceCapabilities.forRole(.admin)
        #expect(caps.canMarkAttendance)
        #expect(caps.canViewClassAttendance)
        #expect(caps.canReviewExcuse)
        #expect(caps.canOverrideRecords)
        #expect(caps.canViewReports)
    }

    @Test("Student capabilities are restricted")
    func studentCapabilities() {
        let caps = AttendanceCapabilities.forRole(.student)
        #expect(!caps.canMarkAttendance)
        #expect(!caps.canViewClassAttendance)
        #expect(caps.canViewOwnAttendance)
        #expect(caps.canQRCheckIn)
        #expect(!caps.canOverrideRecords)
    }

    @Test("Guardian capabilities allow excuse submission")
    func guardianCapabilities() {
        let caps = AttendanceCapabilities.forRole(.guardian)
        #expect(!caps.canMarkAttendance)
        #expect(caps.canViewOwnAttendance)
        #expect(caps.canSubmitExcuse)
        #expect(!caps.canReviewExcuse)
    }

    @Test("Teacher capabilities allow marking and reviewing")
    func teacherCapabilities() {
        let caps = AttendanceCapabilities.forRole(.teacher)
        #expect(caps.canMarkAttendance)
        #expect(caps.canViewClassAttendance)
        #expect(caps.canReviewExcuse)
        #expect(!caps.canOverrideRecords)
        #expect(caps.canViewReports)
    }

    @Test("Accountant capabilities deny all attendance features")
    func accountantCapabilities() {
        let caps = AttendanceCapabilities.forRole(.accountant)
        #expect(!caps.canMarkAttendance)
        #expect(!caps.canViewClassAttendance)
        #expect(!caps.canViewOwnAttendance)
        #expect(!caps.canSubmitExcuse)
        #expect(!caps.canReviewExcuse)
        #expect(!caps.canQRCheckIn)
        #expect(!caps.canOverrideRecords)
        #expect(!caps.canViewReports)
    }

    // MARK: - AttendanceValidation

    @Test("Validate date rejects future dates")
    func validateDateRejectsFuture() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let result = AttendanceValidation.validateDate(futureDate)
        #expect(!result.isValid)
    }

    @Test("Validate date accepts today")
    func validateDateAcceptsToday() {
        let result = AttendanceValidation.validateDate(Date())
        #expect(result.isValid)
    }

    @Test("Validate date rejects dates older than 30 days")
    func validateDateRejectsOld() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let result = AttendanceValidation.validateDate(oldDate)
        #expect(!result.isValid)
    }

    @Test("Validate notes accepts nil")
    func validateNotesAcceptsNil() {
        let result = AttendanceValidation.validateNotes(nil)
        #expect(result.isValid)
    }

    @Test("Validate notes rejects over 500 chars")
    func validateNotesRejectsLong() {
        let longNotes = String(repeating: "a", count: 501)
        let result = AttendanceValidation.validateNotes(longNotes)
        #expect(!result.isValid)
    }

    @Test("Validate QR code accepts valid UUID format")
    func validateQRCodeAcceptsUUID() {
        let result = AttendanceValidation.validateQRCode("550e8400-e29b-41d4-a716-446655440000")
        #expect(result.isValid)
    }

    @Test("Validate QR code rejects empty string")
    func validateQRCodeRejectsEmpty() {
        let result = AttendanceValidation.validateQRCode("")
        #expect(!result.isValid)
    }

    // MARK: - AttendanceExcuse.ExcuseStatus

    @Test("ExcuseStatus rawValues are correct")
    func excuseStatusRawValues() {
        #expect(AttendanceExcuse.ExcuseStatus.pending.rawValue == "PENDING")
        #expect(AttendanceExcuse.ExcuseStatus.approved.rawValue == "APPROVED")
        #expect(AttendanceExcuse.ExcuseStatus.rejected.rawValue == "REJECTED")
    }

    // MARK: - QRSession

    @Test("QRSession isExpired returns true for past date")
    func qrSessionExpired() {
        let session = QRSession(
            id: "qr_1",
            classId: "cls_1",
            periodId: nil,
            code: "ABC123",
            expiresAt: Date().addingTimeInterval(-60),
            schoolId: "school_1"
        )
        #expect(session.isExpired)
    }

    @Test("QRSession isExpired returns false for future date")
    func qrSessionNotExpired() {
        let session = QRSession(
            id: "qr_1",
            classId: "cls_1",
            periodId: nil,
            code: "ABC123",
            expiresAt: Date().addingTimeInterval(3600),
            schoolId: "school_1"
        )
        #expect(!session.isExpired)
    }
}
