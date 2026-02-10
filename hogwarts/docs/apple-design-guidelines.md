# Apple Design Guidelines - Hogwarts iOS App

> **Design Philosophy**: The Hogwarts iOS app follows Apple's Human Interface Guidelines (HIG) and iOS 26+ design language. Our goal is to make the app feel indistinguishable from Apple's own applications like Health, Settings, and Messages.

---

## Table of Contents

1. [Design System Foundation](#design-system-foundation)
2. [Liquid Glass Aesthetic](#liquid-glass-aesthetic)
3. [Typography & Icons](#typography--icons)
4. [Spacing & Layout](#spacing--layout)
5. [Components & Patterns](#components--patterns)
6. [Interactive Elements](#interactive-elements)
7. [Forms & Lists](#forms--lists)
8. [Navigation](#navigation)
9. [Accessibility](#accessibility)
10. [Code Examples](#code-examples)

---

## Design System Foundation

### Materials (Glassmorphism)

The app uses Apple's native materials to create depth and visual hierarchy without harsh shadows.

#### Available Materials

```swift
// From lightest to thickest
.ultraThinMaterial    // For overlays, subtle glass effects
.thinMaterial         // Default for cards and containers
.regularMaterial      // For panels and grouped content
.thickMaterial        // For prominent surfaces and modals
```

#### Usage

- **Cards & Containers**: `.thinMaterial` with `.liquidGlassCard()` modifier
- **Overlays & Badges**: `.ultraThinMaterial` with `.glassOverlay()` modifier
- **Panels & Panels**: `.regularMaterial` with `.glassContainer()` modifier
- **Prominent Surfaces**: `.thickMaterial` with `.glassPanel()` modifier

### Continuous Corners (Squircles)

All corners use Apple's `.continuous` corner style instead of standard `RoundedRectangle`:

```swift
// ❌ OLD - Mathematical rounded rectangle
RoundedRectangle(cornerRadius: 16)

// ✅ NEW - Apple's continuous/squircle corners
RoundedRectangle(cornerRadius: 16, style: .continuous)
```

Benefits:
- Matches iOS System UI
- More aesthetically pleasing
- Better perceived quality

### Elevation Levels

Four standardized shadow levels for visual hierarchy:

| Level | Color Opacity | Radius | Y Offset |
|-------|--------------|--------|----------|
| `.flat` | None | 0 | 0 |
| `.low` | 5% | 4 | 2 |
| `.medium` | 8% | 12 | 4 |
| `.high` | 12% | 20 | 8 |

```swift
view.elevation(.low)      // Subtle shadow
view.elevation(.medium)   // Standard depth
view.elevation(.high)     // Prominent elevation
```

---

## Liquid Glass Aesthetic

The "Liquid Glass" or "Glassmorphism" aesthetic is achieved using Apple's materials with subtle stroke borders.

### Implementation

```swift
// Liquid Glass Card (recommended for most containers)
VStack {
    // Content
}
.liquidGlassCard(cornerRadius: 20, material: .thinMaterial)

// Glass Overlay (for lightweight overlays)
Text("Overlay")
    .glassOverlay(cornerRadius: 16)

// Glass Container (for standard panels)
VStack {
    // Content
}
.glassContainer(cornerRadius: 16)

// Glass Panel (for prominent surfaces)
VStack {
    // Content
}
.glassPanel(cornerRadius: 16)
```

### Visual Effects

Each modifier includes:
- **Material**: Translucent background that blurs content behind
- **Border**: Subtle `.quaternary` stroke for definition
- **Shadow**: Soft elevation shadow
- **Continuous corners**: Squircle style corners

### Common Patterns

#### Card Grid
```swift
VStack(spacing: 16) {
    ForEach(items) { item in
        HStack {
            VStack(alignment: .leading) {
                Text(item.title)
                    .appleHeadline()
                Text(item.description)
                    .appleCaption()
            }
            Spacer()
            Image(systemName: "chevron.right")
                .symbolRenderingMode(.hierarchical)
        }
        .standardPadding()
        .liquidGlassCard()
    }
}
.standardPadding()
```

#### Dashboard Header
```swift
HStack {
    VStack(alignment: .leading, spacing: 4) {
        Text("Welcome").appleCaption()
        Text(userName).appleTitle()
    }
    Spacer()
    AsyncImage(url: imageUrl) { image in
        image.resizable().scaledToFill()
    } placeholder: {
        Image(systemName: "person.circle.fill")
    }
    .frame(width: 50, height: 50)
    .clipShape(Circle())
}
.standardPadding()
.liquidGlassCard()
```

---

## Typography & Icons

### Apple Typography Scale

The app uses system fonts with standardized styles:

| Style | Font | Weight | Use Case |
|-------|------|--------|----------|
| `.appleLargeTitle()` | System, Rounded | Bold | Screen titles |
| `.appleTitle()` | System, Rounded | Bold | Section headers |
| `.appleHeadline()` | System, Rounded | Semibold | List item headers |
| `.appleBody()` | System | Regular | Body text |
| `.appleCaption()` | System | Medium | Secondary text |
| `.appleFootnote()` | System | Regular | Tertiary text |

### Usage

```swift
// ❌ OLD - Raw font specifications
Text("Title")
    .font(.system(.headline, design: .rounded, weight: .semibold))

// ✅ NEW - Semantic modifiers
Text("Title")
    .appleHeadline()
```

### SF Symbols

All icons use SF Symbols with hierarchical rendering mode:

```swift
// ❌ OLD - Monochrome symbols
Image(systemName: "person.circle.fill")
    .foregroundStyle(.blue)

// ✅ NEW - Hierarchical rendering
Image(systemName: "person.circle.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.blue)
```

#### Symbol Rendering Modes

- **`.hierarchical`** (Recommended): Uses foreground color + opacity for depth
- **`.monochrome`**: Single color (use for simple icons)
- **`.palette`**: Two-color variant (use sparingly)
- **`.multicolor`**: Apple's predefined colors (use for app icons only)

### Common Symbols

```swift
// Navigation
AppleSymbols.home       // house.fill
AppleSymbols.back       // chevron.left
AppleSymbols.menu       // line.3.horizontal

// Actions
AppleSymbols.add        // plus
AppleSymbols.delete     // trash
AppleSymbols.edit       // pencil
AppleSymbols.share      // square.and.arrow.up

// Status
AppleSymbols.checkmark  // checkmark.circle.fill
AppleSymbols.error      // exclamationmark.circle.fill
AppleSymbols.warning    // exclamationmark.triangle.fill

// School Domain
AppleSymbols.attendance // checkmark.circle.fill
AppleSymbols.grades     // chart.bar.fill
AppleSymbols.schedule   // calendar
AppleSymbols.students   // person.2.fill
AppleSymbols.messages   // bubble.left.fill
```

---

## Spacing & Layout

### 8pt Grid System

All spacing follows an 8-point grid for consistency:

| Constant | Value | Use Case |
|----------|-------|----------|
| `AppleSpacing.tiny` | 4pt | Tight spacing |
| `AppleSpacing.compact` | 8pt | Compact layouts |
| `AppleSpacing.small` | 12pt | Small spacing |
| `AppleSpacing.standard` | 16pt | **Default padding** |
| `AppleSpacing.comfortable` | 20pt | Tablet margins |
| `AppleSpacing.large` | 24pt | Large spacing |
| `AppleSpacing.extraLarge` | 32pt | Section spacing |
| `AppleSpacing.minTouchTarget` | 44pt | Minimum tap target |

### Convenience Modifiers

```swift
// Apply standard padding (16pt on all sides)
view.standardPadding()

// Apply compact padding (8pt)
view.compactPadding()

// Apply horizontal padding only
view.horizontalPadding(16)

// Apply vertical padding only
view.verticalPadding(16)
```

### Layout Rules

1. **Standard Screen Padding**: `AppleSpacing.standard` (16pt) on all sides
2. **Between Cards**: `AppleSpacing.comfortable` (20pt)
3. **Within Cards**: `AppleSpacing.standard` (16pt) padding
4. **Section Headers**: `AppleSpacing.large` (24pt) above
5. **List Rows**: `AppleSpacing.small` (12pt) vertical spacing

---

## Components & Patterns

### Dashboard Cards

Dashboard cards display key metrics or actions:

```swift
struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppleSpacing.small) {
            // Header
            HStack {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accentColor)

                Text(title)
                    .appleHeadline()

                Spacer()

                Image(systemName: "chevron.right")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tertiary)
            }

            // Content
            content()
        }
        .standardPadding()
        .liquidGlassCard()
    }
}
```

### Data Table Rows

Table rows use inset grouped lists:

```swift
struct TableRow<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .padding(.vertical, 4)
            )
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: 16,
                bottom: 0,
                trailing: 16
            ))
    }
}
```

### Status Indicators

```swift
// Success badge
HStack(spacing: 6) {
    Image(systemName: "checkmark.circle.fill")
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.green)
    Text("Completed")
        .appleBody()
}
.glassOverlay()
```

---

## Interactive Elements

### Context Menus

Long-press actions for all interactive elements:

```swift
HStack {
    VStack(alignment: .leading) {
        Text(item.title).appleHeadline()
        Text(item.subtitle).appleCaption()
    }
    Spacer()
}
.standardPadding()
.liquidGlassCard()
.contextMenu {
    Button {
        editItem(item)
    } label: {
        Label("Edit", systemImage: "pencil")
    }

    Button {
        shareItem(item)
    } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    Divider()

    Button(role: .destructive) {
        deleteItem(item)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

### Sheet Presentations

Sheets use modern detents and materials:

```swift
.sheet(isPresented: $showForm) {
    FormContent()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.thinMaterial)
        .presentationCornerRadius(20)
}
```

---

## Forms & Lists

### Inset Grouped Lists

Forms use `.listStyle(.insetGrouped)` for iOS 17+:

```swift
List {
    Section("Personal Information") {
        TextField("Given Name", text: $givenName)
        TextField("Surname", text: $surname)
        TextField("Email", text: $email)
    }
    .headerProminence(.increased)

    Section("Contact") {
        TextField("Phone", text: $phone)
        TextField("Address", text: $address)
    }
    .headerProminence(.increased)

    Section("Status") {
        Picker("Status", selection: $status) {
            ForEach(StudentStatus.allCases, id: \.self) { status in
                Text(status.rawValue).tag(status)
            }
        }
    }
    .headerProminence(.increased)
}
.listStyle(.insetGrouped)
.scrollContentBackground(.hidden)
.background(.ultraThinMaterial)
```

### Section Headers with Icons

```swift
Section {
    // Content
} header: {
    Label("Personal Info", systemImage: "person.fill")
        .symbolRenderingMode(.hierarchical)
}
```

### Form Controls

```swift
// Text field with icon
HStack(spacing: 8) {
    Image(systemName: "envelope.fill")
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.accentColor)

    TextField("Email", text: $email)
}
.standardPadding()
.liquidGlassCard()
```

---

## Navigation

### TabView Navigation

Main app uses native `TabView` for iOS-native navigation:

```swift
TabView(selection: $selectedTab) {
    DashboardContent()
        .tabItem {
            Label("Dashboard", systemImage: "house.fill")
        }
        .tag(AppTab.dashboard)

    StudentsContent()
        .tabItem {
            Label("Students", systemImage: "person.2.fill")
        }
        .tag(AppTab.students)

    MessagesContent()
        .tabItem {
            Label("Messages", systemImage: "bubble.left.fill")
        }
        .tag(AppTab.messages)
}
.tint(.blue)
```

### NavigationStack

Feature-level navigation uses `NavigationStack`:

```swift
NavigationStack {
    VStack {
        // Content
    }
    .navigationTitle("Title")
    .navigationDestination(for: Student.self) { student in
        StudentDetailView(student: student)
    }
}
```

---

## Accessibility

### Accessibility Labels

All interactive elements include accessibility labels:

```swift
Button {
    addStudent()
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Add Student")
.accessibilityHint("Creates a new student record")
```

### Semantic Grouping

```swift
HStack {
    VStack(alignment: .leading) {
        Text(title).appleHeadline()
        Text(subtitle).appleCaption()
    }
    Spacer()
    Image(systemName: "chevron.right")
}
.accessibilityElement(children: .combine)
```

### Color Independence

Never rely on color alone for meaning:

```swift
// ❌ WRONG - Relies on red color
Text("Error")
    .foregroundStyle(.red)

// ✅ CORRECT - Color + symbol
HStack(spacing: 6) {
    Image(systemName: "exclamationmark.circle.fill")
        .symbolRenderingMode(.hierarchical)
    Text("Error")
}
.foregroundStyle(.red)
```

---

## Code Examples

### Complete Feature View

```swift
struct StudentsContent: View {
    @State private var viewModel = StudentsViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search toolbar
                SearchBar(text: $searchText)
                    .padding(.horizontal, AppleSpacing.standard)
                    .padding(.vertical, AppleSpacing.compact)

                // Content
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.students.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(viewModel.students) { student in
                            StudentRow(student: student)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.thinMaterial)
                                        .padding(.vertical, 4)
                                )
                                .contextMenu {
                                    Button { editStudent(student) } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) { deleteStudent(student) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateForm()
                    } label: {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .task {
                await viewModel.loadStudents()
            }
        }
    }
}
```

### Form with Sheets

```swift
.sheet(isPresented: $viewModel.showForm) {
    NavigationStack {
        List {
            Section("Personal Information") {
                TextField("Given Name", text: $viewModel.givenName)
                TextField("Surname", text: $viewModel.surname)
                TextField("Email", text: $viewModel.email)
            }
            .headerProminence(.increased)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("New Student")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    viewModel.showForm = false
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await viewModel.saveStudent() }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationBackground(.thinMaterial)
    .presentationCornerRadius(20)
}
```

---

## References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/symbols/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [iOS 26 Design Updates](https://developer.apple.com/design/)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 2025 | Initial Apple Design System documentation |

