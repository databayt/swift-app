# DASH-002: Teacher Dashboard

**Epic**: Dashboard (EPIC-002)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: L

---

## User Story

**As a** teacher
**I want** to see my dashboard with today's classes, pending attendance, and recent notifications
**So that** I can manage my teaching day efficiently

---

## Acceptance Criteria

### AC-1: Dashboard Layout
**Given** a teacher opens the app
**When** they are on the dashboard tab
**Then** they see:
- Today's teaching schedule (classes with times and rooms)
- Pending attendance (classes not yet marked today)
- Recent notifications (messages, announcements)
- Quick actions (take attendance, enter grades)

### AC-2: Today's Classes
**Given** the teacher has classes today
**When** they view the schedule section
**Then** each class shows subject, time, room, year level, and student count
**And** the current/next class is highlighted

### AC-3: Pending Attendance
**Given** the teacher has classes today
**When** some classes haven't had attendance marked
**Then** a "Pending Attendance" section shows unmarked classes
**And** tapping a class opens the attendance form for that class

### AC-4: All Attendance Marked
**Given** the teacher has marked attendance for all today's classes
**When** they view the dashboard
**Then** the pending section shows a checkmark: "All attendance marked"

### AC-5: Quick Actions
**Given** the teacher views the dashboard
**When** they see the quick actions section
**Then** buttons are available for: "Take Attendance", "Enter Grades", "Messages"

### AC-6: Pull to Refresh
**Given** the teacher is on the dashboard
**When** they pull down to refresh
**Then** all dashboard data is refreshed

### AC-7: Offline Dashboard
**Given** the device is offline
**When** the teacher opens the dashboard
**Then** cached data is displayed with "Last updated" banner

---

## Offline Behavior

| Section | Online | Offline |
|---------|--------|---------|
| Today's classes | Fetch from API | Show cached timetable |
| Pending attendance | Fetch from API | Show cached status |
| Notifications | Fetch from API | Show cached notifications |
| Take attendance | Full flow | Queue offline |

---

## Technical Subtasks

- [ ] Create `TeacherDashboard` view
- [ ] Create `TeacherDashboardViewModel` with parallel data fetching
- [ ] Create "Today's Classes" card component
- [ ] Create "Pending Attendance" card with action buttons
- [ ] Create "Quick Actions" section
- [ ] Implement navigation to attendance form from pending section
- [ ] Handle offline state
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests for ViewModel
- [ ] Add accessibility labels
- [ ] Verify RTL layout

---

## Files to Create/Modify

### Create
- `hogwarts/features/dashboard/views/teacher-dashboard.swift`
- `hogwarts/features/dashboard/viewmodels/teacher-dashboard-view-model.swift`

### Modify
- `hogwarts/features/dashboard/views/dashboard-content.swift` - Route to teacher dashboard
- `hogwarts/features/dashboard/services/dashboard-actions.swift` - Add teacher data fetching

---

## Dependencies

- **Depends on**: AUTH-001/002/003 + AUTH-004 + AUTH-006
- **Blocks**: None (but pairs well with ATT-002 for attendance flow)

---

## Web App Reference

- Teacher dashboard: `/Users/abdout/hogwarts/src/components/school-dashboard/dashboard/`

---

## Definition of Done

- [ ] Dashboard shows classes, pending attendance, notifications
- [ ] Quick actions navigate to correct features
- [ ] Pending attendance taps open attendance form
- [ ] Pull-to-refresh works
- [ ] Offline mode shows cached data
- [ ] Unit tests pass
- [ ] Localized (ar + en)
- [ ] RTL layout verified
- [ ] Accessibility labels added
- [ ] Story status updated
