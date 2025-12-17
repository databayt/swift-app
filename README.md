# Hogwarts iOS

Native iOS companion app for the Hogwarts school management platform.

## Tech Stack

- **Swift 5.9+** / **SwiftUI** / **iOS 17+**
- **SwiftData** - Offline-first persistence
- **MVVM + Clean Architecture** - Testable, scalable
- **BMAD Method** - Agile AI-driven development

## Quick Start

```bash
# Open in Xcode
open Hogwarts.xcodeproj

# Or via command line
xcodebuild -scheme Hogwarts -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

### Feature-Based Structure (Mirrors Hogwarts Web)

```
Hogwarts/
├── App/                          # App entry point
├── Core/                         # Shared infrastructure
│   ├── Network/                  # API client, endpoints
│   ├── Storage/                  # SwiftData, sync engine
│   ├── Auth/                     # Authentication
│   └── Extensions/               # Swift extensions
│
├── Shared/
│   ├── UI/                       # UI primitives (Button, Card, Input)
│   ├── Atom/                     # Composed components (2+ UI primitives)
│   └── Utils/                    # Utilities
│
└── Features/                     # Feature modules
    └── {Feature}/                # e.g., Students, Attendance
        ├── Models/
        │   └── {Feature}.swift           # Data models
        ├── Views/
        │   ├── {Feature}Content.swift    # Main view (mirrors content.tsx)
        │   ├── {Feature}Form.swift       # Form view (mirrors form.tsx)
        │   └── {Feature}Table.swift      # Table view (mirrors table.tsx)
        ├── ViewModels/
        │   └── {Feature}ViewModel.swift  # Business logic
        ├── Services/
        │   └── {Feature}Actions.swift    # API calls (mirrors actions.ts)
        └── Helpers/
            ├── {Feature}Validation.swift # Validation (mirrors validation.ts)
            └── {Feature}Types.swift      # Types (mirrors types.ts)
```

### Component Hierarchy (Atomic Design)

```
1. UI         → Shared/UI/         # Primitives (Button, Input, Card)
2. Atom       → Shared/Atom/       # Composed (2+ UI primitives)
3. Feature    → Features/{name}/   # Business components
4. Screen     → Features/{name}/   # Full screens
```

## Multi-Tenant Safety

**CRITICAL**: Always include `schoolId` in API requests.

```swift
// All API calls scoped by schoolId
let students = try await api.get("/students", schoolId: context.schoolId)
```

## Localization

- **Arabic (ar)** - RTL, default
- **English (en)** - LTR

## BMAD Workflow

| Phase | Status | Command |
|-------|--------|---------|
| Analysis | Complete | `/ios-analyst` |
| Planning | Complete | `/ios-architect` |
| Solutioning | In Progress | `/ios-architect` |
| Implementation | Pending | `/ios-dev` |

### Agent Commands

```bash
/ios-analyst    # Requirements analysis
/ios-architect  # Architecture decisions
/ios-dev        # Swift implementation
/ios-qa         # Testing
/ios-ui         # SwiftUI components
/ios-status     # Workflow status
/ios-next       # Advance workflow
```

## Offline-First

All features work offline with automatic sync:

| Feature | Offline | Sync |
|---------|---------|------|
| Dashboard | View cached | On launch |
| Attendance | View + queue | Real-time |
| Grades | View cached | Pull refresh |
| Messages | View + queue | Real-time |

## Testing

```bash
# Unit tests
xcodebuild test -scheme Hogwarts

# UI tests
xcodebuild test -scheme HogwartsUITests
```

**Target**: 80%+ code coverage

## Documentation

- [PRD](docs/prd.md) - Product requirements
- [Architecture](docs/architecture.md) - Technical design
- [Workflow Status](docs/bmad-workflow-status.yaml) - BMAD tracking

## Related

- [Hogwarts Web](https://ed.databayt.org) - Web platform
- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) - Development methodology
