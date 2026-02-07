# DASH-003: Guardian Dashboard

**Epic**: Dashboard (EPIC-002)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: L

---

## User Story

**As a** guardian (parent)
**I want** to see an overview of my children's school activity
**So that** I can stay informed about their education

---

## Acceptance Criteria

### AC-1: Dashboard Layout
**Given** a guardian opens the app
**When** they are on the dashboard tab
**Then** they see:
- Children selector (if multiple children)
- Selected child's today schedule
- Selected child's recent grades
- Selected child's attendance summary
- Recent messages from teachers

### AC-2: Multiple Children
**Given** the guardian has multiple children enrolled
**When** they view the dashboard
**Then** a child selector is shown at the top
**And** they can switch between children to see each child's data

### AC-3: Single Child
**Given** the guardian has one child enrolled
**When** they view the dashboard
**Then** the child's name is shown as a header (no selector needed)
**And** the dashboard shows that child's data directly

### AC-4: Child's Schedule
**Given** a child is selected
**When** the guardian views the schedule section
**Then** today's classes are shown with subject, time, and teacher

### AC-5: Child's Grades
**Given** a child is selected
**When** recent grades are available
**Then** the last 5 results are shown with subject and score
**And** tapping opens the full grade view

### AC-6: Child's Attendance
**Given** a child is selected
**When** attendance data is available
**Then** a summary shows this term's attendance (present/absent/late)
**And** a visual indicator (e.g., attendance percentage ring)

### AC-7: Offline Dashboard
**Given** the device is offline
**When** the guardian opens the dashboard
**Then** cached data is displayed with "Last updated" banner

### AC-8: RTL Layout
**Given** the app language is Arabic
**When** the guardian views the dashboard
**Then** all elements mirror correctly for RTL

---

## Offline Behavior

| Section | Online | Offline |
|---------|--------|---------|
| Children list | Fetch from API | Show cached children |
| Child's schedule | Fetch from API | Show cached timetable |
| Child's grades | Fetch from API | Show cached grades |
| Child's attendance | Fetch from API | Show cached summary |

---

## Technical Subtasks

- [ ] Create `GuardianDashboard` view
- [ ] Create `GuardianDashboardViewModel`
- [ ] Create child selector component (horizontal scroll or picker)
- [ ] Fetch guardian's children from API (`/api/students?guardianId={id}`)
- [ ] Create schedule, grades, attendance cards (reuse from DASH-001)
- [ ] Handle multiple children switching
- [ ] Handle single child auto-selection
- [ ] Handle offline state
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests for ViewModel
- [ ] Add accessibility labels
- [ ] Verify RTL layout

---

## Files to Create/Modify

### Create
- `hogwarts/features/dashboard/views/guardian-dashboard.swift`
- `hogwarts/features/dashboard/viewmodels/guardian-dashboard-view-model.swift`
- `hogwarts/shared/ui/child-selector.swift` - Reusable child picker component

### Modify
- `hogwarts/features/dashboard/views/dashboard-content.swift` - Route to guardian dashboard
- `hogwarts/features/dashboard/services/dashboard-actions.swift` - Add guardian data fetching

---

## Dependencies

- **Depends on**: AUTH-001/002/003 + AUTH-004 + AUTH-006
- **Blocks**: None

---

## Web App Reference

- Guardian features: `/Users/abdout/hogwarts/src/components/school-dashboard/`
- Student-Guardian model: Prisma `Guardian`, `StudentGuardian` relationship

---

## Definition of Done

- [ ] Dashboard shows children overview
- [ ] Multiple children switching works
- [ ] Single child auto-selects
- [ ] Schedule, grades, attendance displayed per child
- [ ] Pull-to-refresh works
- [ ] Offline mode shows cached data
- [ ] Unit tests pass
- [ ] Localized (ar + en)
- [ ] RTL layout verified
- [ ] Accessibility labels added
- [ ] Story status updated
