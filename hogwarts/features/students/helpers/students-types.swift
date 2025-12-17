import Foundation

/// Type definitions for Students feature
/// Mirrors: src/components/platform/students/types.ts

// MARK: - Request Types

/// Create student request
struct StudentCreateRequest: Encodable {
    let grNumber: String
    let givenName: String
    let surname: String
    let givenNameAr: String?
    let surnameAr: String?
    let dateOfBirth: Date?
    let gender: String?
    let nationality: String?
    let email: String?
    let phone: String?
    let address: String?
    let yearLevelId: String?
    let batchId: String?
    let guardianId: String?
}

/// Update student request
struct StudentUpdateRequest: Encodable {
    let givenName: String?
    let surname: String?
    let givenNameAr: String?
    let surnameAr: String?
    let dateOfBirth: Date?
    let gender: String?
    let nationality: String?
    let email: String?
    let phone: String?
    let address: String?
    let yearLevelId: String?
    let batchId: String?
    let status: String?
    let photoUrl: String?
    let bloodType: String?
    let allergies: String?
    let medicalConditions: String?
}

// MARK: - Filter Types

/// Student list filters
/// Mirrors: Search params in content.tsx
struct StudentFilters {
    var search: String?
    var status: StudentStatus?
    var yearLevelId: String?
    var batchId: String?
    var page: Int = 1
    var pageSize: Int = 20
    var sortBy: SortField = .name
    var sortOrder: SortOrder = .ascending

    enum SortField: String {
        case name = "givenName"
        case grNumber = "grNumber"
        case createdAt = "createdAt"
        case status = "status"
    }

    enum SortOrder: String {
        case ascending = "asc"
        case descending = "desc"
    }

    /// Convert to query parameters
    var queryParams: [String: String] {
        var params: [String: String] = [:]

        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        if let status = status {
            params["status"] = status.rawValue
        }
        if let yearLevelId = yearLevelId {
            params["yearLevelId"] = yearLevelId
        }
        if let batchId = batchId {
            params["batchId"] = batchId
        }

        params["page"] = String(page)
        params["pageSize"] = String(pageSize)
        params["sortBy"] = sortBy.rawValue
        params["sortOrder"] = sortOrder.rawValue

        return params
    }
}

// MARK: - View State

/// Students list view state
enum StudentsViewState {
    case idle
    case loading
    case loaded([Student])
    case error(Error)
    case empty

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var students: [Student] {
        if case .loaded(let students) = self { return students }
        return []
    }
}

/// Student form mode
enum StudentFormMode {
    case create
    case edit(Student)

    var title: String {
        switch self {
        case .create:
            return String(localized: "student.form.createTitle")
        case .edit:
            return String(localized: "student.form.editTitle")
        }
    }

    var student: Student? {
        if case .edit(let student) = self { return student }
        return nil
    }
}

// MARK: - Table Row

/// Row type for students table
/// Mirrors: Column definitions in columns.tsx
struct StudentRow: Identifiable, Hashable {
    let id: String
    let grNumber: String
    let name: String
    let nameAr: String?
    let email: String?
    let phone: String?
    let status: StudentStatus
    let yearLevel: String?
    let photoUrl: String?

    init(from student: Student) {
        self.id = student.id
        self.grNumber = student.grNumber
        self.name = student.fullName
        self.nameAr = [student.givenNameAr, student.surnameAr]
            .compactMap { $0 }
            .joined(separator: " ")
        self.email = student.email
        self.phone = student.phone
        self.status = student.studentStatus
        self.yearLevel = student.yearLevel?.name
        self.photoUrl = student.photoUrl
    }
}
