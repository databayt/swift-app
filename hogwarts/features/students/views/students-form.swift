import SwiftUI

/// Student create/edit form
/// Mirrors: src/components/platform/students/form.tsx
struct StudentsForm: View {
    let mode: StudentFormMode
    let yearLevels: [YearLevel]
    let onSubmit: (StudentCreateRequest) -> Void
    let onCancel: () -> Void

    // Form fields
    @State private var grNumber = ""
    @State private var givenName = ""
    @State private var surname = ""
    @State private var givenNameAr = ""
    @State private var surnameAr = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var dateOfBirth: Date?
    @State private var gender: String?
    @State private var nationality = ""
    @State private var yearLevelId: String?

    // Validation
    @State private var errors: [String: String] = [:]
    @State private var isSubmitting = false

    // Computed
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section(String(localized: "student.form.section.basic")) {
                    // GR Number (required, create only)
                    if !isEditing {
                        ValidatedTextField(
                            title: String(localized: "student.form.grNumber"),
                            text: $grNumber,
                            error: errors["grNumber"],
                            isRequired: true
                        )
                        .onChange(of: grNumber) { _, newValue in
                            validateField("grNumber", value: newValue)
                        }
                    }

                    // Given Name (required)
                    ValidatedTextField(
                        title: String(localized: "student.form.givenName"),
                        text: $givenName,
                        error: errors["givenName"],
                        isRequired: true
                    )
                    .onChange(of: givenName) { _, newValue in
                        validateField("givenName", value: newValue)
                    }

                    // Surname (required)
                    ValidatedTextField(
                        title: String(localized: "student.form.surname"),
                        text: $surname,
                        error: errors["surname"],
                        isRequired: true
                    )
                    .onChange(of: surname) { _, newValue in
                        validateField("surname", value: newValue)
                    }

                    // Arabic names (optional)
                    ValidatedTextField(
                        title: String(localized: "student.form.givenNameAr"),
                        text: $givenNameAr
                    )

                    ValidatedTextField(
                        title: String(localized: "student.form.surnameAr"),
                        text: $surnameAr
                    )
                }

                // Contact Section
                Section(String(localized: "student.form.section.contact")) {
                    ValidatedTextField(
                        title: String(localized: "student.form.email"),
                        text: $email,
                        error: errors["email"],
                        keyboardType: .emailAddress
                    )
                    .onChange(of: email) { _, newValue in
                        validateField("email", value: newValue)
                    }

                    ValidatedTextField(
                        title: String(localized: "student.form.phone"),
                        text: $phone,
                        error: errors["phone"],
                        keyboardType: .phonePad
                    )
                    .onChange(of: phone) { _, newValue in
                        validateField("phone", value: newValue)
                    }

                    ValidatedTextField(
                        title: String(localized: "student.form.address"),
                        text: $address
                    )
                }

                // Personal Section
                Section(String(localized: "student.form.section.personal")) {
                    DatePicker(
                        String(localized: "student.form.dateOfBirth"),
                        selection: Binding(
                            get: { dateOfBirth ?? Date() },
                            set: { dateOfBirth = $0 }
                        ),
                        displayedComponents: .date
                    )

                    Picker(String(localized: "student.form.gender"), selection: $gender) {
                        Text(String(localized: "common.select")).tag(nil as String?)
                        Text(String(localized: "gender.male")).tag("MALE" as String?)
                        Text(String(localized: "gender.female")).tag("FEMALE" as String?)
                    }

                    ValidatedTextField(
                        title: String(localized: "student.form.nationality"),
                        text: $nationality
                    )

                    // Year Level picker
                    if !yearLevels.isEmpty {
                        Picker(String(localized: "student.form.yearLevel"), selection: $yearLevelId) {
                            Text(String(localized: "common.select")).tag(nil as String?)
                            ForEach(yearLevels) { level in
                                Text(level.name).tag(level.id as String?)
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: isEditing ? "common.save" : "common.create")) {
                        submitForm()
                    }
                    .disabled(isSubmitting || !isFormValid)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    // MARK: - Methods

    private func loadExistingData() {
        guard let student = mode.student else { return }

        grNumber = student.grNumber
        givenName = student.givenName ?? ""
        surname = student.surname ?? ""
        givenNameAr = student.givenNameAr ?? ""
        surnameAr = student.surnameAr ?? ""
        email = student.email ?? ""
        phone = student.phone ?? ""
        address = student.address ?? ""
        dateOfBirth = student.dateOfBirth
        gender = student.gender
        nationality = student.nationality ?? ""
        yearLevelId = student.yearLevelId
    }

    private func validateField(_ field: String, value: String) {
        let result: ValidationResult
        switch field {
        case "grNumber":
            result = StudentsValidation.validateGrNumber(value)
        case "givenName":
            result = StudentsValidation.validateGivenName(value)
        case "surname":
            result = StudentsValidation.validateSurname(value)
        case "email":
            result = StudentsValidation.validateEmail(value.isEmpty ? nil : value)
        case "phone":
            result = StudentsValidation.validatePhone(value.isEmpty ? nil : value)
        default:
            return
        }

        if case .invalid(let message) = result {
            errors[field] = message
        } else {
            errors.removeValue(forKey: field)
        }
    }

    private var isFormValid: Bool {
        // Required fields
        guard !grNumber.isEmpty || isEditing else { return false }
        guard !givenName.isEmpty else { return false }
        guard !surname.isEmpty else { return false }

        // No validation errors
        return errors.isEmpty
    }

    private func submitForm() {
        // Final validation
        let validation = StudentsValidation.validateCreateForm(
            grNumber: grNumber,
            givenName: givenName,
            surname: surname,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            dateOfBirth: dateOfBirth
        )

        guard validation.isValid else {
            errors = validation.errors
            return
        }

        isSubmitting = true

        let request = StudentCreateRequest(
            grNumber: grNumber,
            givenName: givenName,
            surname: surname,
            givenNameAr: givenNameAr.isEmpty ? nil : givenNameAr,
            surnameAr: surnameAr.isEmpty ? nil : surnameAr,
            dateOfBirth: dateOfBirth,
            gender: gender,
            nationality: nationality.isEmpty ? nil : nationality,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            yearLevelId: yearLevelId,
            batchId: nil,
            guardianId: nil
        )

        onSubmit(request)
    }
}

// MARK: - Validated Text Field

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    var error: String?
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                if isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            TextField("", text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    StudentsForm(
        mode: .create,
        yearLevels: [],
        onSubmit: { _ in },
        onCancel: {}
    )
}
