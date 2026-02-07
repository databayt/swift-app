# AUTH-001: Google OAuth Sign-In

**Epic**: Authentication (EPIC-001)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: M

---

## User Story

**As a** user (any role)
**I want** to sign in with my Google account
**So that** I can access the app without creating a separate password

---

## Acceptance Criteria

### AC-1: Successful Google Sign-In
**Given** the user is on the login screen
**When** they tap "Sign in with Google"
**Then** the Google OAuth sheet appears
**And** after selecting their account, they are signed in
**And** redirected to school selection (if multiple schools) or dashboard

### AC-2: Google Account Not Registered
**Given** the user taps "Sign in with Google"
**When** their Google account is not registered in the system
**Then** an error message is shown: "Account not found"
**And** they remain on the login screen

### AC-3: Google Sign-In Cancelled
**Given** the user taps "Sign in with Google"
**When** they cancel the Google OAuth sheet
**Then** they return to the login screen without error

### AC-4: Network Error During Sign-In
**Given** the device has no internet connection
**When** the user taps "Sign in with Google"
**Then** an error message is shown: "No internet connection"

### AC-5: Token Storage
**Given** the user successfully signs in with Google
**When** the session is established
**Then** the JWT token is stored securely in Keychain
**And** the user's role and schoolId are cached locally

---

## Offline Behavior

| Action | Online | Offline |
|--------|--------|---------|
| Sign in | Google OAuth flow | Show "No internet" error |
| Session check | Verify with server | Use cached session |

---

## Technical Subtasks

- [ ] Integrate GoogleSignIn SDK via SPM
- [ ] Create Google OAuth button in login view
- [ ] Implement `AuthManager.signInWithGoogle()` method
- [ ] Handle OAuth callback and exchange for JWT
- [ ] Store JWT and session in Keychain via `KeychainService`
- [ ] Set `currentUser` and `schoolId` in `AuthManager`
- [ ] Handle error states (not registered, cancelled, network)
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests for `AuthManager.signInWithGoogle()`
- [ ] Write UI test for Google sign-in flow
- [ ] Add accessibility labels to Google sign-in button

---

## Files to Create/Modify

### Modify
- `hogwarts/core/auth/auth-manager.swift` - Add `signInWithGoogle()` method
- `hogwarts/features/auth/views/login-view.swift` - Add Google sign-in button

### Create
- `hogwarts/features/auth/services/auth-actions.swift` - OAuth API calls
- `hogwarts/features/auth/helpers/auth-types.swift` - Session, AuthError types

---

## Dependencies

- **Depends on**: AUTH-006 (Session Management - for token storage)
- **Blocks**: DASH-001, DASH-002, DASH-003 (need auth to show dashboard)

---

## Web App Reference

- Auth config: `/Users/abdout/hogwarts/src/auth.config.ts`
- Google provider: NextAuth Google provider configuration
- Callback: `/Users/abdout/hogwarts/src/app/api/auth/[...nextauth]/route.ts`

---

## Definition of Done

- [ ] Google sign-in flow works end-to-end
- [ ] JWT stored in Keychain
- [ ] Error states handled (not registered, cancelled, offline)
- [ ] Unit tests pass
- [ ] Localized (ar + en)
- [ ] Accessibility labels on sign-in button
- [ ] Story status updated in `docs/bmad-workflow-status.yaml`
