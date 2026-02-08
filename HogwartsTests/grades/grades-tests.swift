import Foundation
import Testing
@testable import Hogwarts

/// Tests for Grades feature: GradeCalculator, ExamType, ExamResult, validation
@Suite("Grades")
struct GradesTests {

    // MARK: - GradeCalculator.letterGrade

    @Test("GradeCalculator returns A+ for 95%")
    func letterGradeAPlus() {
        #expect(GradeCalculator.letterGrade(for: 95) == "A+")
    }

    @Test("GradeCalculator returns A+ for 90% (boundary)")
    func letterGradeAPlusBoundary() {
        #expect(GradeCalculator.letterGrade(for: 90) == "A+")
    }

    @Test("GradeCalculator returns A for 85%")
    func letterGradeA() {
        #expect(GradeCalculator.letterGrade(for: 85) == "A")
    }

    @Test("GradeCalculator returns A for 89.9%")
    func letterGradeAUpperBound() {
        #expect(GradeCalculator.letterGrade(for: 89.9) == "A")
    }

    @Test("GradeCalculator returns B+ for 80%")
    func letterGradeBPlus() {
        #expect(GradeCalculator.letterGrade(for: 80) == "B+")
    }

    @Test("GradeCalculator returns B for 75%")
    func letterGradeB() {
        #expect(GradeCalculator.letterGrade(for: 75) == "B")
    }

    @Test("GradeCalculator returns C+ for 70%")
    func letterGradeCPlus() {
        #expect(GradeCalculator.letterGrade(for: 70) == "C+")
    }

    @Test("GradeCalculator returns C for 65%")
    func letterGradeC() {
        #expect(GradeCalculator.letterGrade(for: 65) == "C")
    }

    @Test("GradeCalculator returns D+ for 60%")
    func letterGradeDPlus() {
        #expect(GradeCalculator.letterGrade(for: 60) == "D+")
    }

    @Test("GradeCalculator returns D for 50%")
    func letterGradeD() {
        #expect(GradeCalculator.letterGrade(for: 50) == "D")
    }

    @Test("GradeCalculator returns F for 49%")
    func letterGradeF() {
        #expect(GradeCalculator.letterGrade(for: 49) == "F")
    }

    @Test("GradeCalculator returns F for 0%")
    func letterGradeFZero() {
        #expect(GradeCalculator.letterGrade(for: 0) == "F")
    }

    // MARK: - GradeCalculator.gpa

    @Test("GPA is 4.0 for 95%")
    func gpa40() {
        #expect(GradeCalculator.gpa(for: 95) == 4.0)
    }

    @Test("GPA is 3.7 for 87%")
    func gpa37() {
        #expect(GradeCalculator.gpa(for: 87) == 3.7)
    }

    @Test("GPA is 3.3 for 82%")
    func gpa33() {
        #expect(GradeCalculator.gpa(for: 82) == 3.3)
    }

    @Test("GPA is 3.0 for 77%")
    func gpa30() {
        #expect(GradeCalculator.gpa(for: 77) == 3.0)
    }

    @Test("GPA is 2.7 for 72%")
    func gpa27() {
        #expect(GradeCalculator.gpa(for: 72) == 2.7)
    }

    @Test("GPA is 2.3 for 67%")
    func gpa23() {
        #expect(GradeCalculator.gpa(for: 67) == 2.3)
    }

    @Test("GPA is 2.0 for 62%")
    func gpa20() {
        #expect(GradeCalculator.gpa(for: 62) == 2.0)
    }

    @Test("GPA is 1.0 for 55%")
    func gpa10() {
        #expect(GradeCalculator.gpa(for: 55) == 1.0)
    }

    @Test("GPA is 0.0 for 30%")
    func gpa00() {
        #expect(GradeCalculator.gpa(for: 30) == 0.0)
    }

    // MARK: - ExamType

    @Test("ExamType rawValues are correct")
    func examTypeRawValues() {
        #expect(ExamType.midterm.rawValue == "MIDTERM")
        #expect(ExamType.final_.rawValue == "FINAL")
        #expect(ExamType.quiz.rawValue == "QUIZ")
        #expect(ExamType.test.rawValue == "TEST")
        #expect(ExamType.practical.rawValue == "PRACTICAL")
        #expect(ExamType.assignment.rawValue == "ASSIGNMENT")
    }

    @Test("ExamType has 6 cases")
    func examTypeCaseCount() {
        #expect(ExamType.allCases.count == 6)
    }

    // MARK: - ExamStatus

    @Test("ExamStatus rawValues are correct")
    func examStatusRawValues() {
        #expect(ExamStatus.draft.rawValue == "DRAFT")
        #expect(ExamStatus.scheduled.rawValue == "SCHEDULED")
        #expect(ExamStatus.completed.rawValue == "COMPLETED")
        #expect(ExamStatus.published.rawValue == "PUBLISHED")
    }

    @Test("ExamStatus has 4 cases")
    func examStatusCaseCount() {
        #expect(ExamStatus.allCases.count == 4)
    }

    // MARK: - ResultStatus

    @Test("ResultStatus rawValues are correct")
    func resultStatusRawValues() {
        #expect(ResultStatus.pending.rawValue == "PENDING")
        #expect(ResultStatus.graded.rawValue == "GRADED")
        #expect(ResultStatus.published.rawValue == "PUBLISHED")
    }

    // MARK: - ExamResult computed properties

    @Test("ExamResult isPassing returns true when marks >= passingMarks")
    func examResultIsPassing() {
        let exam = Exam(
            id: "exam_1", title: "Math Midterm", classId: "cls_1",
            subjectId: "sub_1", schoolId: "school_1", description: nil,
            examDate: "2025-03-01", totalMarks: 100, passingMarks: 50,
            examType: "MIDTERM", status: "PUBLISHED", createdAt: nil,
            updatedAt: nil, subject: nil
        )
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 75, percentage: nil,
            grade: nil, status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: exam, student: nil
        )
        #expect(result.isPassing)
    }

    @Test("ExamResult isPassing returns false when marks < passingMarks")
    func examResultIsFailing() {
        let exam = Exam(
            id: "exam_1", title: "Math Midterm", classId: "cls_1",
            subjectId: "sub_1", schoolId: "school_1", description: nil,
            examDate: "2025-03-01", totalMarks: 100, passingMarks: 50,
            examType: "MIDTERM", status: "PUBLISHED", createdAt: nil,
            updatedAt: nil, subject: nil
        )
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 30, percentage: nil,
            grade: nil, status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: exam, student: nil
        )
        #expect(!result.isPassing)
    }

    @Test("ExamResult isPassing returns false when marks is nil")
    func examResultIsPassingNilMarks() {
        let exam = Exam(
            id: "exam_1", title: "Math Midterm", classId: "cls_1",
            subjectId: "sub_1", schoolId: "school_1", description: nil,
            examDate: "2025-03-01", totalMarks: 100, passingMarks: 50,
            examType: "MIDTERM", status: "PUBLISHED", createdAt: nil,
            updatedAt: nil, subject: nil
        )
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: nil, percentage: nil,
            grade: nil, status: "PENDING", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: exam, student: nil
        )
        #expect(!result.isPassing)
    }

    @Test("ExamResult percentageValue calculates from marks and totalMarks")
    func examResultPercentageCalculation() {
        let exam = Exam(
            id: "exam_1", title: "Math Midterm", classId: "cls_1",
            subjectId: "sub_1", schoolId: "school_1", description: nil,
            examDate: "2025-03-01", totalMarks: 200, passingMarks: 100,
            examType: "MIDTERM", status: "PUBLISHED", createdAt: nil,
            updatedAt: nil, subject: nil
        )
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 150, percentage: nil,
            grade: nil, status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: exam, student: nil
        )
        #expect(result.percentageValue == 75.0)
    }

    @Test("ExamResult percentageValue returns stored percentage if available")
    func examResultPercentageStored() {
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 150, percentage: 80.0,
            grade: nil, status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: nil, student: nil
        )
        #expect(result.percentageValue == 80.0)
    }

    @Test("ExamResult gradeLabel uses GradeCalculator when grade is nil")
    func examResultGradeLabelCalculated() {
        let exam = Exam(
            id: "exam_1", title: "Math Midterm", classId: "cls_1",
            subjectId: "sub_1", schoolId: "school_1", description: nil,
            examDate: "2025-03-01", totalMarks: 100, passingMarks: 50,
            examType: "MIDTERM", status: "PUBLISHED", createdAt: nil,
            updatedAt: nil, subject: nil
        )
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 92, percentage: nil,
            grade: nil, status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: exam, student: nil
        )
        #expect(result.gradeLabel == "A+")
    }

    @Test("ExamResult gradeLabel returns stored grade when available")
    func examResultGradeLabelStored() {
        let result = ExamResult(
            id: "res_1", examId: "exam_1", studentId: "stu_1",
            schoolId: "school_1", marks: 92, percentage: 92.0,
            grade: "A+", status: "GRADED", remarks: nil,
            createdAt: nil, updatedAt: nil, exam: nil, student: nil
        )
        #expect(result.gradeLabel == "A+")
    }

    // MARK: - GradesValidation

    @Test("Validate exam title rejects empty")
    func validateExamTitleEmpty() {
        let result = GradesValidation.validateExamTitle("")
        #expect(!result.isValid)
    }

    @Test("Validate exam title rejects too short")
    func validateExamTitleTooShort() {
        let result = GradesValidation.validateExamTitle("Ab")
        #expect(!result.isValid)
    }

    @Test("Validate exam title accepts valid")
    func validateExamTitleValid() {
        let result = GradesValidation.validateExamTitle("Math Midterm Exam")
        #expect(result.isValid)
    }

    @Test("Validate total marks rejects zero")
    func validateTotalMarksZero() {
        let result = GradesValidation.validateTotalMarks(0)
        #expect(!result.isValid)
    }

    @Test("Validate total marks rejects negative")
    func validateTotalMarksNegative() {
        let result = GradesValidation.validateTotalMarks(-10)
        #expect(!result.isValid)
    }

    @Test("Validate total marks accepts valid")
    func validateTotalMarksValid() {
        let result = GradesValidation.validateTotalMarks(100)
        #expect(result.isValid)
    }

    @Test("Validate total marks rejects over 1000")
    func validateTotalMarksTooHigh() {
        let result = GradesValidation.validateTotalMarks(1001)
        #expect(!result.isValid)
    }

    @Test("Validate passing marks rejects exceeding total")
    func validatePassingMarksExceedsTotal() {
        let result = GradesValidation.validatePassingMarks(110, totalMarks: 100)
        #expect(!result.isValid)
    }

    @Test("Validate passing marks accepts valid")
    func validatePassingMarksValid() {
        let result = GradesValidation.validatePassingMarks(50, totalMarks: 100)
        #expect(result.isValid)
    }

    @Test("Validate marks rejects exceeding total")
    func validateMarksExceedsTotal() {
        let result = GradesValidation.validateMarks(110, totalMarks: 100)
        #expect(!result.isValid)
    }

    @Test("Validate marks accepts valid")
    func validateMarksValid() {
        let result = GradesValidation.validateMarks(85, totalMarks: 100)
        #expect(result.isValid)
    }

    // MARK: - GradeCapabilities

    @Test("Admin grade capabilities allow all")
    func adminGradeCapabilities() {
        let caps = GradeCapabilities.forRole(.admin)
        #expect(caps.canViewGrades)
        #expect(caps.canEnterGrades)
        #expect(caps.canCreateExams)
        #expect(caps.canPublishGrades)
        #expect(caps.canViewReportCard)
        #expect(caps.canViewClassGrades)
    }

    @Test("Student grade capabilities are restricted")
    func studentGradeCapabilities() {
        let caps = GradeCapabilities.forRole(.student)
        #expect(caps.canViewGrades)
        #expect(!caps.canEnterGrades)
        #expect(!caps.canCreateExams)
        #expect(!caps.canPublishGrades)
        #expect(caps.canViewReportCard)
        #expect(!caps.canViewClassGrades)
    }

    @Test("Staff grade capabilities deny all")
    func staffGradeCapabilities() {
        let caps = GradeCapabilities.forRole(.staff)
        #expect(!caps.canViewGrades)
        #expect(!caps.canEnterGrades)
        #expect(!caps.canCreateExams)
    }

    // MARK: - GradeFilters

    @Test("GradeFilters default queryParams")
    func gradeFiltersDefaults() {
        let filters = GradeFilters()
        let params = filters.queryParams
        #expect(params["page"] == "1")
        #expect(params["pageSize"] == "20")
        #expect(params["sortBy"] == "examDate")
        #expect(params["sortOrder"] == "desc")
    }

    @Test("GradeFilters queryParams includes optional fields when set")
    func gradeFiltersWithOptionals() {
        var filters = GradeFilters()
        filters.studentId = "stu_1"
        filters.examType = .midterm
        filters.status = .published
        let params = filters.queryParams
        #expect(params["studentId"] == "stu_1")
        #expect(params["examType"] == "MIDTERM")
        #expect(params["status"] == "PUBLISHED")
    }
}
