# AUTH-003: Email/Password Login

**Epic**: Authentication (EPIC-001)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: M

---

## User Story

**As a** user (any role)
**I want** to sign in with my email and password
**So that** I can access the app without a social account

---

## Acceptance Criteria

### AC-1: Successful Login
**Given** the user is on the login screen
**When** they enter valid email and password and tap "Sign In"
**Then** they are authenticated and redirected to school selection or dashboard

### AC-2: Invalid Credentials
**Given** the user enters wrong email or password
**When** they tap "Sign In"
**Then** an error message is shown: "Invalid email or password"
**And** the password field is cleared
**And** the email field retains its value

### AC-3: Empty Fields
**Given** the user leaves email or password empty
**When** they tap "Sign In"
**Then** validation errors are shown on the empty fields
**And** the sign-in request is not sent

### AC-4: Email Format Validation
**Given** the user enters an invalid email format
**When** they tap "Sign In"
**Then** a validation error is shown: "Invalid email format"

### AC-5: Network Error
**Given** the device has no internet connection
**When** the user taps "Sign In"
**Then** an error message is shown: "No internet connection"

### AC-6: Loading State
**Given** the user submits valid credentials
**When** the sign-in request is in progress
**Then** a loading indicator is shown
**And** the sign-in button is disabled

### AC-7: RTL Layout
**Given** the app language is Arabic (RTL)
**When** the user views the login screen
**Then** the form layout mirrors correctly (labels, fields, buttons)

---

## Offline Behavior

| Action | Online | Offline |
|--------|--------|---------|
| Sign in | Submit to API | Show "No internet" error |
| Session check | Verify with server | Use cached session if valid |

---

## Technical Subtasks

- [ ] Create email/password form fields in login view
- [ ] Add client-side validation (email format, non-empty)
- [ ] Implement `AuthManager.signIn(email:password:)` method
- [ ] Handle API response (success, invalid credentials, server error)
- [ ] Store JWT and session in Keychain
- [ ] Add loading state and button disable during request
- [ ] Handle keyboard dismissal and return key navigation
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests for validation and sign-in
- [ ] Write UI test for login flow
- [ ] Add accessibility labels and hints
- [ ] Verify RTL layout

---

## Files to Create/Modify

### Modify
- `hogwarts/core/auth/auth-manager.swift` - Add credential sign-in method
- `hogwarts/features/auth/views/login-view.swift` - Add email/password form

### Create
- `hogwarts/features/auth/helpers/auth-validation.swift` - Email/password validation
- `hogwarts/features/auth/viewmodels/login-view-model.swift` - Login form state management

---

## Dependencies

- **Depends on**: AUTH-006 (Session Management)
- **Blocks**: DASH-001, DASH-002, DASH-003

---

## Web App Reference

- Credentials provider: `/Users/abdout/hogwarts/src/auth.config.ts`
- Sign-in page: `/Users/abdout/hogwarts/src/app/[lang]/(auth)/login/`

---

## Test Accounts

| Email | Password | Role |
|-------|----------|------|
| `student@databayt.org` | `1234` | STUDENT |
| `teacher@databayt.org` | `1234` | TEACHER |
| `admin@databayt.org` | `1234` | ADMIN |
| `parent@databayt.org` | `1234` | GUARDIAN |

---

## Definition of Done

- [ ] Email/password login works end-to-end
- [ ] Client-side validation works (email format, empty fields)
- [ ] Server errors handled (invalid credentials, server error)
- [ ] Loading state shown during request
- [ ] JWT stored in Keychain
- [ ] Unit tests pass
- [ ] UI test for login flow passes
- [ ] Localized (ar + en)
- [ ] RTL layout verified
- [ ] Accessibility labels added
- [ ] Story status updated
