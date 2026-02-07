# DASH-001: Student Dashboard

**Epic**: Dashboard (EPIC-002)
**Priority**: P0
**Sprint**: 1
**Status**: pending
**Estimated Effort**: L

---

## User Story

**As a** student
**I want** to see my dashboard with today's schedule, recent grades, and attendance summary
**So that** I can quickly access my most important school information

---

## Acceptance Criteria

### AC-1: Dashboard Layout
**Given** a student opens the app
**When** they are authenticated and on the dashboard tab
**Then** they see:
- Today's schedule (classes with times)
- Recent grades (last 5 results)
- Attendance summary (this term: present/absent/late counts)
- Quick action buttons (view full schedule, view grades)

### AC-2: Today's Schedule
**Given** the student views the dashboard
**When** today has classes scheduled
**Then** a list of today's classes is shown with subject, time, room, and teacher
**And** the current/next class is highlighted

### AC-3: No Classes Today
**Given** today is a weekend or holiday
**When** the student views the dashboard
**Then** a message is shown: "No classes today"

### AC-4: Recent Grades
**Given** the student has exam results
**When** they view the recent grades section
**Then** the last 5 results are shown with subject, score, and grade
**And** tapping a grade navigates to grade details

### AC-5: Attendance Summary
**Given** the student views the dashboard
**When** attendance data is available
**Then** a summary shows this term's attendance (e.g., "45 Present, 2 Absent, 1 Late")
**And** a visual indicator (progress ring or bar)

### AC-6: Pull to Refresh
**Given** the student is on the dashboard
**When** they pull down to refresh
**Then** all dashboard data is refreshed from the API

### AC-7: Offline Dashboard
**Given** the device is offline
**When** the student opens the dashboard
**Then** cached data is displayed
**And** a banner shows "Last updated: {timestamp}"

### AC-8: RTL Layout
**Given** the app language is Arabic
**When** the student views the dashboard
**Then** all elements are correctly aligned for RTL

---

## Offline Behavior

| Section | Online | Offline |
|---------|--------|---------|
| Today's schedule | Fetch from API | Show cached timetable |
| Recent grades | Fetch from API | Show cached grades |
| Attendance summary | Fetch from API | Show cached summary |

---

## Technical Subtasks

- [ ] Create `StudentDashboard` view
- [ ] Create `StudentDashboardViewModel` with parallel data fetching
- [ ] Create "Today's Schedule" card component
- [ ] Create "Recent Grades" card component
- [ ] Create "Attendance Summary" card component
- [ ] Create dashboard actions (fetch schedule, grades, attendance)
- [ ] Implement pull-to-refresh
- [ ] Handle offline state with cached data
- [ ] Add "last updated" timestamp display
- [ ] Add localization strings (ar + en)
- [ ] Write unit tests for ViewModel
- [ ] Add accessibility labels
- [ ] Verify RTL layout

---

## Files to Create/Modify

### Create
- `hogwarts/features/dashboard/views/student-dashboard.swift`
- `hogwarts/features/dashboard/viewmodels/student-dashboard-view-model.swift`
- `hogwarts/features/dashboard/services/dashboard-actions.swift`
- `hogwarts/features/dashboard/helpers/dashboard-types.swift`

### Modify
- `hogwarts/features/dashboard/views/dashboard-content.swift` - Route to role-specific dashboard

---

## Dependencies

- **Depends on**: AUTH-001/002/003 (authentication), AUTH-004 (school selection), AUTH-006 (session)
- **Blocks**: None

---

## Web App Reference

- Dashboard: `/Users/abdout/hogwarts/src/components/school-dashboard/dashboard/`
- Student view components

---

## Definition of Done

- [ ] Dashboard shows today's schedule, grades, attendance
- [ ] Current/next class highlighted
- [ ] Pull-to-refresh works
- [ ] Offline mode shows cached data with timestamp
- [ ] Unit tests pass for ViewModel
- [ ] Localized (ar + en)
- [ ] RTL layout verified
- [ ] Accessibility labels added
- [ ] Story status updated
