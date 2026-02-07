# AUTH-004: School Selection

**Epic**: Authentication (EPIC-001)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: M

---

## User Story

**As a** user who belongs to multiple schools
**I want** to select which school to use after signing in
**So that** I see data scoped to the correct school (multi-tenant)

---

## Acceptance Criteria

### AC-1: Single School - Auto-Select
**Given** the user signs in and belongs to only one school
**When** authentication completes
**Then** they are automatically redirected to the dashboard
**And** the schoolId is set in the session

### AC-2: Multiple Schools - Show Picker
**Given** the user signs in and belongs to multiple schools
**When** authentication completes
**Then** a school selection screen is shown
**And** each school shows name and logo

### AC-3: School Selection
**Given** the user sees the school picker
**When** they tap a school
**Then** the schoolId is set in the session
**And** they are redirected to the dashboard
**And** all subsequent API calls include this schoolId

### AC-4: Remember Last School
**Given** the user has previously selected a school
**When** they open the app next time
**Then** the last selected school is pre-selected or auto-used

### AC-5: Switch School
**Given** the user is on the dashboard
**When** they navigate to settings and tap "Switch School"
**Then** the school picker is shown again

### AC-6: No School (USER role)
**Given** the user has role USER (not assigned to any school)
**When** they sign in
**Then** they see a "No school assigned" message
**And** a prompt to contact their school administrator

---

## Offline Behavior

| Action | Online | Offline |
|--------|--------|---------|
| Load schools | Fetch from API | Use cached school list |
| Select school | Set in session | Set in session (cached) |

---

## Technical Subtasks

- [ ] Create school selection view
- [ ] Fetch user's schools from API after auth
- [ ] Implement school selection logic in AuthManager
- [ ] Cache selected schoolId in Keychain
- [ ] Handle single-school auto-selection
- [ ] Handle no-school state for USER role
- [ ] Add "Switch School" option in settings
- [ ] Cache school list in SwiftData
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests
- [ ] Add accessibility labels

---

## Files to Create/Modify

### Create
- `hogwarts/features/auth/views/school-selection-view.swift` - School picker UI
- `hogwarts/features/auth/viewmodels/school-selection-view-model.swift` - Selection logic

### Modify
- `hogwarts/core/auth/auth-manager.swift` - Add schoolId management
- `hogwarts/core/auth/tenant-context.swift` - Set active school context
- `hogwarts/app/hogwarts-app.swift` - Add school selection to auth flow

---

## Dependencies

- **Depends on**: AUTH-001 or AUTH-002 or AUTH-003 (need auth first)
- **Blocks**: All feature modules (they all need schoolId)

---

## Web App Reference

- Tenant context: `/Users/abdout/hogwarts/src/lib/tenant-context.ts`
- School model: Prisma `School` model with `name`, `domain`, `logoUrl`

---

## Definition of Done

- [ ] Single school auto-selects
- [ ] Multiple schools show picker
- [ ] SchoolId persisted and used in all API calls
- [ ] Switch school works from settings
- [ ] No-school state handled for USER role
- [ ] Unit tests pass
- [ ] Localized (ar + en)
- [ ] Accessibility labels added
- [ ] Story status updated
