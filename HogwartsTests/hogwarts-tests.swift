import XCTest
@testable import Hogwarts

final class HogwartsTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup code before each test
    }

    override func tearDownWithError() throws {
        // Cleanup code after each test
    }

    func testAttendanceStatusDisplayName() throws {
        XCTAssertEqual(AttendanceStatus.present.rawValue, "PRESENT")
        XCTAssertEqual(AttendanceStatus.absent.rawValue, "ABSENT")
        XCTAssertEqual(AttendanceStatus.late.rawValue, "LATE")
    }

    func testAttendanceMethodRawValues() throws {
        XCTAssertEqual(AttendanceMethod.manual.rawValue, "MANUAL")
        XCTAssertEqual(AttendanceMethod.qrCode.rawValue, "QR_CODE")
    }

    func testValidationDateNotInFuture() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let result = AttendanceValidation.validateDate(futureDate)
        XCTAssertFalse(result.isValid)
    }

    func testValidationDateValid() throws {
        let today = Date()
        let result = AttendanceValidation.validateDate(today)
        XCTAssertTrue(result.isValid)
    }
}
