# AUTH-002: Facebook OAuth Sign-In

**Epic**: Authentication (EPIC-001)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: M

---

## User Story

**As a** user (any role)
**I want** to sign in with my Facebook account
**So that** I can access the app using my existing social account

---

## Acceptance Criteria

### AC-1: Successful Facebook Sign-In
**Given** the user is on the login screen
**When** they tap "Sign in with Facebook"
**Then** the Facebook OAuth flow launches (in-app browser or app switch)
**And** after authenticating, they are signed in
**And** redirected to school selection or dashboard

### AC-2: Facebook Account Not Registered
**Given** the user taps "Sign in with Facebook"
**When** their Facebook account is not registered in the system
**Then** an error message is shown: "Account not found"

### AC-3: Facebook Sign-In Cancelled
**Given** the user taps "Sign in with Facebook"
**When** they cancel the Facebook auth flow
**Then** they return to the login screen without error

### AC-4: Network Error
**Given** the device has no internet connection
**When** the user taps "Sign in with Facebook"
**Then** an error message is shown: "No internet connection"

---

## Offline Behavior

| Action | Online | Offline |
|--------|--------|---------|
| Sign in | Facebook OAuth flow | Show "No internet" error |

---

## Technical Subtasks

- [ ] Integrate Facebook SDK via SPM
- [ ] Configure Facebook App ID in Info.plist
- [ ] Create Facebook OAuth button in login view
- [ ] Implement `AuthManager.signInWithFacebook()` method
- [ ] Handle OAuth callback and exchange for JWT
- [ ] Store session in Keychain
- [ ] Handle error states
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests
- [ ] Add accessibility labels

---

## Files to Create/Modify

### Modify
- `hogwarts/core/auth/auth-manager.swift` - Add `signInWithFacebook()` method
- `hogwarts/features/auth/views/login-view.swift` - Add Facebook sign-in button
- `hogwarts/features/auth/services/auth-actions.swift` - Facebook OAuth API calls

---

## Dependencies

- **Depends on**: AUTH-006 (Session Management)
- **Blocks**: DASH-001, DASH-002, DASH-003

---

## Web App Reference

- Facebook provider: NextAuth Facebook provider in `/Users/abdout/hogwarts/src/auth.config.ts`

---

## Definition of Done

- [ ] Facebook sign-in flow works end-to-end
- [ ] JWT stored in Keychain
- [ ] Error states handled
- [ ] Unit tests pass
- [ ] Localized (ar + en)
- [ ] Accessibility labels added
- [ ] Story status updated
