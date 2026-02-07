# Product Requirements Document (PRD)
## Hogwarts iOS App

**Version**: 2.0
**Last Updated**: 2026-02-08
**Status**: Approved

---

## 1. Executive Summary

### 1.1 Product Vision
Hogwarts iOS is the native mobile companion for the Hogwarts school management platform. It provides offline-first access to critical school features for students, teachers, parents, and staff.

### 1.2 Goals
- **G1**: Enable mobile access to school information for all 8 user roles
- **G2**: Provide offline-first functionality for areas with poor connectivity
- **G3**: Support bilingual usage (Arabic RTL + English LTR)
- **G4**: Integrate seamlessly with existing Hogwarts web platform
- **G5**: Mirror web app feature patterns for consistent data experience

### 1.3 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Store Rating | 4.5+ | App Store Connect |
| Crash-Free Rate | 99.5%+ | Xcode Organizer / Sentry |
| Daily Active Users | 60% of web users | Analytics |
| Offline Usage | 30%+ sessions | Local analytics |
| App Launch Time | < 2 seconds | Performance profiling |
| Attendance Marking Time | < 30 seconds per class | User testing |
| Sync Success Rate | 95%+ | Sync engine metrics |
| Test Coverage | 80%+ | Xcode coverage report |

---

## 2. User Personas

### 2.1 Student (Primary)
- **Age**: 6-18 years
- **Needs**: View grades, schedule, assignments, attendance
- **Pain Points**: Slow school wifi, Arabic interface needed
- **Goals**: Quick access to daily information
- **Key Journeys**: Check schedule, view grades, see attendance record

### 2.2 Teacher
- **Role**: Classroom instructor
- **Needs**: Mark attendance, enter grades, communicate with parents
- **Pain Points**: Time-consuming manual processes, need offline marking
- **Goals**: Efficient classroom management from phone
- **Key Journeys**: Take attendance (< 30s), enter grades, message parent

### 2.3 Guardian (Parent)
- **Role**: Student's parent/guardian
- **Needs**: Monitor child's progress, communicate with teachers
- **Pain Points**: Lack of real-time information, multiple children
- **Goals**: Stay informed about child's education
- **Key Journeys**: Check child's attendance, view report card, message teacher

### 2.4 Admin
- **Role**: School administrator
- **Needs**: Overview of school operations, manage students
- **Pain Points**: Managing multiple systems, need mobile access
- **Goals**: Centralized school management on the go
- **Key Journeys**: View school stats, manage students, handle approvals

---

## 3. Features

### 3.1 Epic 1: Authentication (EPIC-001)
**Priority**: P0 (Critical)
**Sprint**: 1

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| AUTH-001 | Google OAuth | Sign in with Google account | All |
| AUTH-002 | Facebook OAuth | Sign in with Facebook account | All |
| AUTH-003 | Email/Password | Traditional credential login | All |
| AUTH-004 | School Selection | Multi-tenant school picker after login | All |
| AUTH-005 | Biometric Unlock | Face ID / Touch ID for returning users | All |
| AUTH-006 | Session Management | JWT handling, refresh, expiry | All |

**Acceptance Criteria**:
- User can sign in via Google, Facebook, or email/password
- After auth, user selects school (multi-tenant)
- JWT stored securely in Keychain
- Session persists across app restarts
- Biometric unlock for returning users (opt-in)
- Graceful handling of expired tokens (auto-refresh or re-login)

**Offline Behavior**: Login requires connectivity. Cached session allows app use offline.

### 3.2 Epic 2: Dashboard (EPIC-002)
**Priority**: P0 (Critical)
**Sprint**: 1-2

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| DASH-001 | Student Dashboard | Today's schedule, recent grades, attendance summary | Student |
| DASH-002 | Teacher Dashboard | Today's classes, pending attendance, notifications | Teacher |
| DASH-003 | Guardian Dashboard | Children overview, alerts, recent activity | Guardian |
| DASH-004 | Admin Dashboard | School metrics, recent activity, quick actions | Admin, Developer |

**Acceptance Criteria**:
- Each role sees a tailored dashboard on login
- Dashboard loads within 2 seconds
- Shows today's relevant information prominently
- Quick action buttons for common tasks
- Pull-to-refresh updates data
- Works offline with cached data (shows "last updated" timestamp)

**Offline Behavior**: Shows cached dashboard data with "Last updated: X" banner.

### 3.3 Epic 3: Attendance (EPIC-003)
**Priority**: P0 (Critical)
**Sprint**: 2

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| ATT-001 | View History | Personal attendance record with stats | Student, Guardian |
| ATT-002 | Mark Attendance | Take class attendance (manual) | Teacher |
| ATT-003 | QR Check-in | Scan QR code for attendance | Student |
| ATT-004 | Submit Excuse | Request absence excuse with reason | Guardian |
| ATT-005 | Attendance Stats | Analytics charts and summaries | Teacher, Admin |
| ATT-006 | Bulk Attendance | Mark multiple students at once | Teacher |

**Acceptance Criteria (ATT-002 - Mark Attendance)**:
- Given a teacher views their current class
- When they tap "Take Attendance"
- Then they see a list of all students in the class
- And can mark each as Present/Absent/Late/Excused
- And can submit attendance (queued if offline)
- And attendance syncs when connectivity returns

**Sub-features from Web App**:
- Attendance statuses: PRESENT, ABSENT, LATE, EXCUSED, SICK, HOLIDAY
- Attendance methods: MANUAL, QR_CODE (more in future)
- Excuse workflow: Guardian submits -> Teacher/Admin approves
- Statistics: Per-student, per-class, per-day aggregations

**Offline Behavior**: View cached history offline. Mark attendance offline (queued). Sync on reconnect.

### 3.4 Epic 4: Grades & Results (EPIC-004)
**Priority**: P0 (Critical)
**Sprint**: 2

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| GRADE-001 | View Results | Individual exam/assignment results | Student, Guardian |
| GRADE-002 | Report Card | Term/year summary with all subjects | Student, Guardian |
| GRADE-003 | Grade History | Historical performance charts | Student, Guardian |
| GRADE-004 | Grade Entry | Enter student grades for exams | Teacher |
| GRADE-005 | GPA Display | Calculated GPA with breakdown | Student |

**Acceptance Criteria (GRADE-001 - View Results)**:
- Given a student opens the Grades tab
- When results are available
- Then they see a list of exams/assignments with scores
- And each result shows subject, date, score, grade letter
- And results are color-coded (green for pass, red for fail)

**Sub-features from Web App**:
- Grading systems: Percentage, Letter Grade, GPA
- Grade boundaries configurable per school
- Report card generation per term
- Grade override capability (admin only)

**Offline Behavior**: View cached grades offline. Grade entry queued offline.

### 3.5 Epic 5: Timetable (EPIC-005)
**Priority**: P1 (High)
**Sprint**: 3

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| TIME-001 | Weekly View | 7-day schedule grid | All |
| TIME-002 | Daily View | Single day timeline | All |
| TIME-003 | Class Details | Room, teacher, subject info | Student |

**Offline Behavior**: Full offline access (cached for 1 week).

### 3.6 Epic 6: Messaging (EPIC-006)
**Priority**: P1 (High)
**Sprint**: 3

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| MSG-001 | Conversation List | List of all chats | All |
| MSG-002 | Chat Interface | Send/receive messages | All |
| MSG-003 | Send/Receive | Real-time messaging | All |
| MSG-004 | Push Notifications | Message alerts via APNs | All |

**Offline Behavior**: View cached messages offline. Send queued offline.

### 3.7 Epic 7: Notifications (EPIC-007)
**Priority**: P1 (High)
**Sprint**: 3

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| NOTIF-001 | Notification List | All notifications | All |
| NOTIF-002 | Push Alerts | Real-time push via APNs | All |
| NOTIF-003 | Preferences | Notification settings per type | All |

### 3.8 Epic 8: Students Management (EPIC-008)
**Priority**: P0 (Critical)
**Sprint**: 2

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| STU-001 | Student List | Searchable, filterable student list | Teacher, Admin |
| STU-002 | Student Detail | Full student profile view | Teacher, Admin |
| STU-003 | Create/Edit Student | Add or update student information | Admin |

**Acceptance Criteria (STU-001 - Student List)**:
- Given a teacher opens the Students tab
- When the list loads
- Then they see all students in their school (scoped by schoolId)
- And can search by name
- And can filter by class, year level, status
- And each row shows name, class, year level, status badge

**Sub-features from Web App**:
- Student statuses: ACTIVE, INACTIVE, GRADUATED, TRANSFERRED, SUSPENDED
- Search across given name and surname
- Pagination (20 per page)
- Sorting by name, class, date enrolled
- Guardian linkage display

**Offline Behavior**: View cached student list offline. Create/edit queued offline.

### 3.9 Epic 9: Profile & Settings (EPIC-009)
**Priority**: P2 (Medium)
**Sprint**: 4

| Story ID | Feature | Description | User Roles |
|----------|---------|-------------|------------|
| PROF-001 | Profile View | Personal information display | All |
| PROF-002 | Edit Profile | Update name, phone, photo | All |
| PROF-003 | Language Toggle | Arabic/English switch | All |
| PROF-004 | Notification Settings | Per-type preferences | All |
| PROF-005 | Theme Settings | Light/Dark mode | All |
| PROF-006 | Logout | Sign out and clear session | All |

---

## 4. Role-Based Capabilities Matrix

| Feature | DEVELOPER | ADMIN | TEACHER | STUDENT | GUARDIAN | STAFF | ACCOUNTANT |
|---------|-----------|-------|---------|---------|----------|-------|------------|
| Dashboard | Admin view | Admin view | Teacher view | Student view | Guardian view | Staff view | Finance view |
| Students: View All | Y | Y | Own classes | N | Own children | Y | N |
| Students: Create | Y | Y | Y | N | N | N | N |
| Students: Edit | Y | Y | Own school | N | N | N | N |
| Students: Delete | Y | Y | N | N | N | N | N |
| Attendance: Mark | Y | Y | Y | N | N | N | N |
| Attendance: View Own | - | - | - | Y | Children | - | - |
| Attendance: View All | Y | Y | Own classes | N | N | Y | N |
| Grades: Enter | Y | Y | Y | N | N | N | N |
| Grades: View Own | - | - | - | Y | Children | - | - |
| Grades: View All | Y | Y | Own classes | N | N | N | N |
| Messages: Send | Y | Y | Y | Y | Y | Y | N |
| Settings: School | Y | Y | N | N | N | N | N |

---

## 5. Technical Requirements

### 5.1 Platform Requirements
- **iOS Version**: 18.0+
- **Devices**: iPhone (iPad future)
- **Languages**: Swift 6.0+
- **UI Framework**: SwiftUI

### 5.2 Architecture Requirements
- **Pattern**: MVVM + Feature-Based
- **Storage**: SwiftData for offline
- **Network**: URLSession with async/await
- **Auth**: Keychain for secure storage

### 5.3 Backend Integration
- **API**: Hogwarts Next.js API (`https://ed.databayt.org/api`)
- **Auth**: NextAuth.js compatible (JWT)
- **Multi-tenant**: schoolId scoping in every request
- **Push**: APNs (Apple Push Notification service)

### 5.4 Offline Requirements

| Feature | Read (Offline) | Write (Offline) | Sync Strategy |
|---------|---------------|-----------------|---------------|
| Dashboard | Cached data | N/A | App launch |
| Students | Cached list | Queue create/edit | 1 hour cache |
| Attendance | Cached history | Queue marking | 24 hour cache |
| Grades | Cached results | Queue entry | 24 hour cache |
| Timetable | Full offline | N/A | 1 week cache |
| Messages | Cached messages | Queue send | Real-time |
| Profile | Cached profile | Queue edits | Indefinite |

### 5.5 API Contract

All API requests follow the pattern:
```
Authorization: Bearer {jwt_token}
Content-Type: application/json

// Response format
{
  "success": true,
  "data": { ... }
}

// Error format
{
  "success": false,
  "error": "Error message"
}
```

### 5.6 Security Requirements
- JWT tokens stored in Keychain (not UserDefaults)
- Biometric authentication option (Face ID / Touch ID)
- Session timeout (24 hours)
- Certificate pinning (production)
- No sensitive data in logs or crash reports
- Secure input fields for passwords

---

## 6. User Journeys

### 6.1 Student: Check Today's Schedule
1. Open app (biometric unlock)
2. View dashboard with today's classes
3. Tap class for details (room, teacher, time)

### 6.2 Teacher: Take Attendance
1. Open app
2. Dashboard shows "Take Attendance" for current class
3. Tap to open attendance form
4. Mark students present/absent/late (< 30 seconds)
5. Submit (queued if offline, syncs when connected)

### 6.3 Guardian: View Child's Grades
1. Open app
2. Select child (if multiple children)
3. View grades dashboard with recent results
4. Tap subject for detailed grade history

### 6.4 Admin: Manage Students
1. Open app
2. Navigate to Students
3. Search/filter student list
4. Tap student for detail view
5. Edit student information if needed

---

## 7. Design Guidelines

### 7.1 Visual Design
- Follow Apple Human Interface Guidelines
- Consistent with Hogwarts web branding
- Support light and dark modes
- Accessible color contrast (WCAG AA)

### 7.2 Navigation
- Tab bar for main sections (role-dependent tabs)
- NavigationStack for drill-down
- Pull-to-refresh for all lists
- Swipe gestures where appropriate

### 7.3 Accessibility
- VoiceOver support on all screens
- Dynamic Type support (no hardcoded font sizes)
- Sufficient touch targets (44pt minimum)
- Screen reader labels on all interactive elements

---

## 8. Release Plan

### 8.1 MVP (v1.0) - Sprints 1-5
- Authentication (all methods)
- Dashboard (all roles)
- Attendance (view + mark + QR)
- Grades (view + report card)
- Students (list + detail + CRUD)
- Timetable (view)
- Basic messaging
- Push notifications
- Profile/Settings

### 8.2 Future Releases (v1.x)
- Assignments management
- Fee payment integration
- Library system
- Event calendar
- Document uploads
- Kiosk mode for attendance
- Geofencing attendance
- Advanced analytics

---

## 9. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| API compatibility | High | Medium | Version API endpoints, feature flags |
| Offline sync conflicts | Medium | High | Clear conflict resolution per entity |
| RTL layout issues | Medium | Medium | Thorough RTL testing, SwiftUI handles most |
| Push notification delivery | Medium | Low | APNs best practices, silent push fallback |
| App Store rejection | High | Low | Follow HIG strictly, no private APIs |
| Performance on older devices | Medium | Medium | Profile on iPhone SE, lazy loading |

---

## 10. Appendix

### 10.1 Glossary
- **schoolId**: Unique tenant identifier for multi-tenant isolation
- **JWT**: JSON Web Token for authentication
- **RTL**: Right-to-left (Arabic layout direction)
- **SwiftData**: Apple's persistence framework (iOS 18+)
- **APNs**: Apple Push Notification service

### 10.2 References
- [Hogwarts Web App](https://ed.databayt.org)
- [Web Codebase](/Users/abdout/hogwarts/)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
