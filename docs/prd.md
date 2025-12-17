# Product Requirements Document (PRD)
## Hogwarts iOS App

**Version**: 1.0
**Last Updated**: 2025-12-17
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

### 1.3 Success Metrics
| Metric | Target |
|--------|--------|
| App Store Rating | 4.5+ |
| Crash-Free Rate | 99.5%+ |
| Daily Active Users | 60% of web users |
| Offline Usage | 30%+ sessions |
| App Launch Time | < 2 seconds |

---

## 2. User Personas

### 2.1 Student (Primary)
- **Age**: 6-18 years
- **Needs**: View grades, schedule, assignments
- **Pain Points**: Slow school wifi, Arabic interface needed
- **Goals**: Quick access to daily information

### 2.2 Teacher
- **Role**: Classroom instructor
- **Needs**: Mark attendance, enter grades, communicate with parents
- **Pain Points**: Time-consuming manual processes
- **Goals**: Efficient classroom management

### 2.3 Guardian (Parent)
- **Role**: Student's parent/guardian
- **Needs**: Monitor child's progress, communicate with teachers
- **Pain Points**: Lack of real-time information
- **Goals**: Stay informed about child's education

### 2.4 Admin
- **Role**: School administrator
- **Needs**: Overview of school operations
- **Pain Points**: Managing multiple systems
- **Goals**: Centralized school management

---

## 3. Features

### 3.1 Epic 1: Authentication
**Priority**: P0 (Critical)
**Sprint**: 1

| Feature | Description | User Roles |
|---------|-------------|------------|
| Google OAuth | Sign in with Google | All |
| Facebook OAuth | Sign in with Facebook | All |
| Email/Password | Traditional login | All |
| School Selection | Multi-tenant school picker | All |
| Biometric Unlock | Face ID / Touch ID | All |
| Session Management | JWT token handling | All |

### 3.2 Epic 2: Dashboard
**Priority**: P0 (Critical)
**Sprint**: 1-2

| Feature | Description | User Roles |
|---------|-------------|------------|
| Student Dashboard | Grades, schedule, assignments | Student |
| Teacher Dashboard | Classes, attendance, notifications | Teacher |
| Guardian Dashboard | Children overview | Guardian |
| Admin Dashboard | School metrics | Admin, Developer |
| Quick Actions | Common task shortcuts | All |

### 3.3 Epic 3: Attendance
**Priority**: P0 (Critical)
**Sprint**: 2

| Feature | Description | User Roles |
|---------|-------------|------------|
| View History | Personal attendance record | Student, Guardian |
| Mark Attendance | Take class attendance | Teacher |
| QR Check-in | Scan QR for attendance | Student |
| Submit Excuse | Request absence excuse | Guardian |
| Attendance Stats | Analytics and charts | All |

### 3.4 Epic 4: Grades & Results
**Priority**: P0 (Critical)
**Sprint**: 2

| Feature | Description | User Roles |
|---------|-------------|------------|
| Exam Results | View individual results | Student, Guardian |
| Report Cards | Term/year summaries | Student, Guardian |
| Grade Entry | Enter student grades | Teacher |
| GPA Calculation | Automatic GPA display | Student |
| Grade History | Historical performance | Student, Guardian |

### 3.5 Epic 5: Timetable
**Priority**: P1 (High)
**Sprint**: 3

| Feature | Description | User Roles |
|---------|-------------|------------|
| Weekly View | 7-day schedule grid | All |
| Daily View | Single day timeline | All |
| Class Details | Room, teacher info | Student |
| Teaching Schedule | Teacher's classes | Teacher |

### 3.6 Epic 6: Messaging
**Priority**: P1 (High)
**Sprint**: 3

| Feature | Description | User Roles |
|---------|-------------|------------|
| Conversations | List of chats | All |
| Send/Receive | Real-time messaging | All |
| Group Chat | Multi-person conversations | All |
| Push Notifications | Message alerts | All |
| Offline Queue | Send when back online | All |

### 3.7 Epic 7: Notifications
**Priority**: P1 (High)
**Sprint**: 3

| Feature | Description | User Roles |
|---------|-------------|------------|
| Notification List | All notifications | All |
| Push Alerts | Real-time push | All |
| Preferences | Notification settings | All |
| Read/Unread | Status management | All |

### 3.8 Epic 8: Profile & Settings
**Priority**: P2 (Medium)
**Sprint**: 4

| Feature | Description | User Roles |
|---------|-------------|------------|
| Profile View | Personal information | All |
| Edit Profile | Update details | All |
| Language Toggle | Arabic/English switch | All |
| Theme Settings | Light/Dark mode | All |
| Notification Settings | Preferences | All |
| Logout | Sign out | All |

---

## 4. Technical Requirements

### 4.1 Platform Requirements
- **iOS Version**: 17.0+
- **Devices**: iPhone (iPad future)
- **Languages**: Swift 5.9+
- **UI Framework**: SwiftUI

### 4.2 Architecture Requirements
- **Pattern**: MVVM + Clean Architecture
- **Storage**: SwiftData for offline
- **Network**: URLSession with async/await
- **Auth**: Keychain for secure storage

### 4.3 Backend Integration
- **API**: Hogwarts Next.js API
- **Auth**: NextAuth.js compatible
- **Multi-tenant**: schoolId scoping
- **Push**: APNs (Apple Push Notification service)

### 4.4 Offline Requirements
| Feature | Offline Support |
|---------|-----------------|
| Dashboard | Read cached data |
| Attendance | View history, queue new |
| Grades | View cached results |
| Timetable | Full offline access |
| Messages | View cached, queue send |
| Profile | View and edit locally |

### 4.5 Localization Requirements
- **Arabic (ar)**: RTL layout, Tajawal font, Hijri calendar option
- **English (en)**: LTR layout, SF Pro font, Gregorian calendar
- **Number Format**: Arabic numerals option

### 4.6 Security Requirements
- JWT tokens stored in Keychain
- Biometric authentication option
- Session timeout (24 hours)
- Certificate pinning (production)
- No sensitive data in logs

---

## 5. User Journeys

### 5.1 Student: Check Today's Schedule
1. Open app (biometric unlock)
2. View dashboard with today's classes
3. Tap class for details
4. See room, teacher, and time

### 5.2 Teacher: Take Attendance
1. Open app
2. Navigate to Attendance
3. Select class/period
4. Mark students present/absent
5. Submit (queued if offline)

### 5.3 Guardian: View Child's Grades
1. Open app
2. Select child (if multiple)
3. View grades dashboard
4. Tap subject for details
5. See historical performance

---

## 6. Design Guidelines

### 6.1 Visual Design
- Follow Apple Human Interface Guidelines
- Consistent with Hogwarts web branding
- Support light and dark modes
- Accessible color contrast (WCAG AA)

### 6.2 Navigation
- Tab bar for main sections
- Back navigation standard
- Pull-to-refresh for lists
- Swipe gestures where appropriate

### 6.3 Accessibility
- VoiceOver support
- Dynamic Type support
- Sufficient touch targets (44pt)
- Screen reader labels

---

## 7. Release Plan

### 7.1 MVP (v1.0)
- Authentication (all methods)
- Dashboard (all roles)
- Attendance (view + mark)
- Grades (view)
- Timetable (view)
- Basic messaging
- Push notifications
- Profile/Settings

### 7.2 Future Releases (v1.x)
- Assignments management
- Fee payment
- Library system
- Event calendar
- Document uploads

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| API compatibility | High | Version API endpoints |
| Offline sync conflicts | Medium | Clear conflict resolution rules |
| RTL layout issues | Medium | Thorough RTL testing |
| Push notification delivery | Medium | APNs best practices |
| App Store rejection | High | Follow guidelines strictly |

---

## 9. Appendix

### 9.1 Glossary
- **schoolId**: Unique tenant identifier
- **JWT**: JSON Web Token for authentication
- **RTL**: Right-to-left (Arabic layout)
- **SwiftData**: Apple's persistence framework

### 9.2 References
- [Hogwarts Web App](https://ed.databayt.org)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
