# AUTH-006: Session Management

**Epic**: Authentication (EPIC-001)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: L

---

## User Story

**As a** user
**I want** my session to persist securely across app restarts
**So that** I don't have to log in every time I open the app

---

## Acceptance Criteria

### AC-1: Session Persistence
**Given** the user has signed in
**When** they close and reopen the app
**Then** they are still signed in (if token is valid)
**And** redirected directly to dashboard

### AC-2: Token Expiry
**Given** the user's JWT has expired (24 hours)
**When** they open the app or make an API request
**Then** they are redirected to the login screen
**And** a message is shown: "Session expired, please sign in again"

### AC-3: Token Refresh
**Given** the user's JWT is about to expire
**When** an API request is made
**Then** the token is refreshed automatically in the background
**And** the new token replaces the old one in Keychain

### AC-4: Sign Out
**Given** the user taps "Sign Out"
**When** the action completes
**Then** all tokens are removed from Keychain
**And** all cached user data is cleared from SwiftData
**And** the user is redirected to login screen

### AC-5: Unauthorized Response
**Given** the user makes an API request
**When** the server returns 401 Unauthorized
**Then** the session is cleared
**And** the user is redirected to login screen

### AC-6: Keychain Security
**Given** the user is signed in
**When** tokens are stored
**Then** they are in Keychain with `.whenUnlockedThisDeviceOnly` accessibility
**And** NOT in UserDefaults or plain files

---

## Offline Behavior

| Action | Online | Offline |
|--------|--------|---------|
| Check session | Verify with server | Use cached token (trust expiry) |
| Refresh token | Request new token | Skip, use existing |
| Sign out | Clear server session | Clear local only |

---

## Technical Subtasks

- [ ] Implement JWT storage in Keychain (save, get, delete)
- [ ] Implement session validation on app launch
- [ ] Implement token refresh logic (before expiry)
- [ ] Handle 401 responses globally in APIClient
- [ ] Implement sign-out (clear Keychain + SwiftData cache)
- [ ] Create `Session` model with user, schoolId, role, accessToken
- [ ] Add token expiry checking (decode JWT, check `exp` claim)
- [ ] Add localization strings for session messages
- [ ] Write unit tests for all session flows
- [ ] Write integration test for token refresh

---

## Files to Create/Modify

### Modify
- `hogwarts/core/auth/auth-manager.swift` - Session lifecycle management
- `hogwarts/core/auth/keychain-service.swift` - Token CRUD operations
- `hogwarts/core/network/api-client.swift` - 401 handling, token injection

### Create
- `hogwarts/features/auth/helpers/auth-types.swift` - Session, AuthError, TokenPayload types

---

## Dependencies

- **Depends on**: None (foundational)
- **Blocks**: AUTH-001, AUTH-002, AUTH-003 (all auth methods need session management)
- **Blocks**: All API-consuming features

---

## Web App Reference

- NextAuth session: `/Users/abdout/hogwarts/src/auth.ts`
- JWT config: NextAuth JWT strategy with 24h expiry

---

## Definition of Done

- [ ] JWT stored securely in Keychain
- [ ] Session persists across app restarts
- [ ] Expired tokens redirect to login
- [ ] Token refresh works transparently
- [ ] Sign out clears all local data
- [ ] 401 responses handled globally
- [ ] Unit tests pass for all session flows
- [ ] No tokens in UserDefaults or logs
- [ ] Story status updated
