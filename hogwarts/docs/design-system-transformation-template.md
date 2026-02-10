# Design System Transformation Template

This document provides copy-paste templates for quickly transforming all remaining views to use the Apple Design System.

---

## Table View Template

Use this pattern for all list/table views:

```swift
struct {Feature}Table: View {
    let rows: [{FeatureRow}]
    let onSelect: ({FeatureRow}) -> Void

    var body: some View {
        List {
            ForEach(rows) { row in
                {FeatureRowView}(row: row)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(row)
                    }
                    // ✅ ADD: Glass row background
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                            .padding(.vertical, 4)
                    )
                    // ✅ ADD: Context menu
                    .contextMenu {
                        Button {
                            onSelect(row)
                        } label: {
                            Label(String(localized: "common.edit"), systemImage: "pencil")
                        }

                        Button {
                            UIPasteboard.general.string = row.id
                        } label: {
                            Label(String(localized: "common.copy"), systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete([row])
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
            }
        }
        // ✅ CHANGE: From .listStyle(.plain) to .insetGrouped
        .listStyle(.insetGrouped)
        // ✅ ADD: Transparent background for better appearance
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }
}
```

---

## Row View Typography Template

Update typography in all row views:

```swift
struct {Feature}RowView: View {
    let row: {FeatureRow}

    var body: some View {
        HStack(spacing: AppleSpacing.small) {  // ✅ CHANGE: Use AppleSpacing
            // Avatar/Icon
            AsyncImage(url: ...) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    // ✅ ADD: Hierarchical rendering
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            // ✅ CHANGE: From .clipShape(Circle()) to .continuousCorners()
            .continuousCorners(12)

            VStack(alignment: .leading, spacing: 4) {
                // ✅ CHANGE: From .font(.headline) to .appleHeadline()
                Text(row.title)
                    .appleHeadline()

                // ✅ CHANGE: From .font(.caption) to .appleCaption()
                Text(row.subtitle)
                    .appleCaption()
            }

            Spacer()

            // Trailing icon
            Image(systemName: "chevron.right")
                // ✅ ADD: Hierarchical rendering
                .symbolRenderingMode(.hierarchical)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
```

---

## Container/Card Template

Use this for dashboard cards, feature containers:

```swift
struct {Feature}Card: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppleSpacing.small) {
            HStack {
                Image(systemName: systemImage)
                    // ✅ ADD: Hierarchical rendering
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accentColor)

                Text(title)
                    // ✅ CHANGE: From .font(.headline) to .appleHeadline()
                    .appleHeadline()

                Spacer()

                Image(systemName: "chevron.right")
                    // ✅ ADD: Hierarchical rendering
                    .symbolRenderingMode(.hierarchical)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            content()
        }
        // ✅ CHANGE: From .padding() to .standardPadding()
        .standardPadding()
        // ✅ CHANGE: From .background(.background) + .clipShape(...) to .liquidGlassCard()
        .liquidGlassCard(cornerRadius: 20, material: .thinMaterial)
        .accessibilityElement(children: .combine)
    }
}
```

---

## Form/Sheet Template

Update forms to use modern sheet presentations:

```swift
struct {Feature}Form: View {
    @State private var showForm = false

    var body: some View {
        // ...
        .sheet(isPresented: $showForm) {
            NavigationStack {
                List {
                    Section("Section Header") {
                        TextField("Field", text: $field)
                    }
                    // ✅ ADD: Header prominence
                    .headerProminence(.increased)
                }
                // ✅ ADD: Modern form styling
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Form Title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showForm = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { saveForm() }
                    }
                }
            }
            // ✅ ADD: Modern sheet presentation
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.thinMaterial)
            .presentationCornerRadius(20)
        }
    }
}
```

---

## SF Symbols Rendering Update

Find and replace patterns for SF Symbols:

### Pattern 1: Simple Image

```swift
// ❌ OLD
Image(systemName: "person.circle.fill")
    .foregroundColor(.blue)

// ✅ NEW
Image(systemName: "person.circle.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.blue)
```

### Pattern 2: With Color + Size

```swift
// ❌ OLD
Image(systemName: "checkmark.circle.fill")
    .foregroundColor(.green)
    .font(.title)

// ✅ NEW
Image(systemName: "checkmark.circle.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.green)
    .font(.title)
```

### Pattern 3: In Buttons/Labels

```swift
// ❌ OLD
Button {
    action()
} label: {
    Image(systemName: "plus")
}

// ✅ NEW
Button {
    action()
} label: {
    Image(systemName: "plus")
        .symbolRenderingMode(.hierarchical)
}
```

---

## Global Find & Replace Commands

Use these in your editor to automate updates:

### Replace All Font Headlines

```
Find:  \.font\(\.headline\)
Replace: .appleHeadline()
```

### Replace All Font Captions

```
Find:  \.font\(\.caption\)(?![2])
Replace: .appleCaption()
```

### Replace All Padding

```
Find:  \.padding\(\)
Replace: .standardPadding()
```

### Add SF Symbol Rendering

```
Find:  Image\(systemName: "([^"]+)"\)\n(\s+)\.foregroundStyle
Replace: Image(systemName: "$1")\n$2.symbolRenderingMode(.hierarchical)\n$2.foregroundStyle
```

---

## View-by-View Checklist

Use this checklist for each view you update:

### Step 1: Lists/Tables
- [ ] Change `.listStyle(.plain)` to `.listStyle(.insetGrouped)`
- [ ] Add `.listRowBackground(RoundedRectangle(...).fill(.thinMaterial))`
- [ ] Add `.contextMenu { ... }`
- [ ] Add `.scrollContentBackground(.hidden)`
- [ ] Add `.background(.ultraThinMaterial)` (optional, for full-screen effect)

### Step 2: Typography
- [ ] Replace `.font(.headline)` with `.appleHeadline()`
- [ ] Replace `.font(.caption)` with `.appleCaption()`
- [ ] Replace `.font(.body)` with `.appleBody()`
- [ ] Replace `.font(.title2)` with `.appleTitle()`
- [ ] Replace `.font(.largeTitle)` with `.appleLargeTitle()`

### Step 3: Spacing
- [ ] Replace `.padding()` with `.standardPadding()`
- [ ] Replace `spacing: 16` with `spacing: AppleSpacing.standard`
- [ ] Replace `spacing: 20` with `spacing: AppleSpacing.comfortable`
- [ ] Replace `spacing: 8` with `spacing: AppleSpacing.compact`

### Step 4: SF Symbols
- [ ] Add `.symbolRenderingMode(.hierarchical)` to all SF Symbols
- [ ] Remove redundant `.font(.caption)` on symbols (inherit from context)
- [ ] Use `AppleSymbols` factory for common icons

### Step 5: Containers/Cards
- [ ] Replace `.background(.background).clipShape(RoundedRectangle(...))` with `.liquidGlassCard()`
- [ ] Add `.elevation(.medium)` if using shadows
- [ ] Use `RoundedRectangle(..., style: .continuous)` for all corners
- [ ] Use `.glassOverlay()` for lightweight overlays

### Step 6: Forms/Sheets
- [ ] Add `.presentationDetents([.medium, .large])`
- [ ] Add `.presentationBackground(.thinMaterial)`
- [ ] Add `.presentationDragIndicator(.visible)`
- [ ] Change `Form { ... }` to `List { ... }.listStyle(.insetGrouped)`
- [ ] Add `.scrollContentBackground(.hidden)` to forms

### Step 7: Testing
- [ ] Build: `xcodebuild build -scheme Hogwarts`
- [ ] Run: Simulator test on iPhone 16 Pro
- [ ] Check: Light mode appearance
- [ ] Check: Dark mode appearance
- [ ] Test: Context menus (long-press)
- [ ] Test: Sheet presentations
- [ ] Verify: No console warnings

---

## Common Views to Update (Priority Order)

### High Priority (Used Frequently)
1. ✅ `dashboard-content.swift` - DONE
2. ✅ `students-table.swift` - DONE
3. ✅ `attendance-table.swift` - DONE
4. ⚠️ `grades-content.swift` - Similar to dashboard
5. ⚠️ `messages-content.swift` - Similar pattern
6. ⚠️ `profile-content.swift` - Similar pattern

### Medium Priority (Feature-Specific)
7. `timetable-week-view.swift` - Grid/calendar view
8. `attendance-form.swift` - Form view
9. `grades-form.swift` - Form view
10. `student-detail-view.swift` - Detail view

### Lower Priority (Supporting)
11. `notifications-content.swift`
12. `message-bubble.swift` - Custom shape
13. Supporting views

---

## Quick Copy-Paste Blocks

### Inset Grouped List Header

```swift
List {
    Section("Header Title") {
        content
    }
    .headerProminence(.increased)
}
.listStyle(.insetGrouped)
.scrollContentBackground(.hidden)
```

### Glass Card with Icon

```swift
VStack(alignment: .leading, spacing: 12) {
    HStack {
        Image(systemName: "icon.name")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.accentColor)
        Text("Title").appleHeadline()
        Spacer()
        Image(systemName: "chevron.right")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.tertiary)
    }
    content
}
.standardPadding()
.liquidGlassCard()
```

### Context Menu with Standard Actions

```swift
.contextMenu {
    Button { edit() } label: {
        Label("Edit", systemImage: "pencil")
    }
    Button { copy() } label: {
        Label("Copy", systemImage: "doc.on.doc")
    }
    Divider()
    Button(role: .destructive) { delete() } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

### Modern Sheet Presentation

```swift
.sheet(isPresented: $show) {
    NavigationStack {
        FormContent()
            .navigationTitle("Form Title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { show = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveForm() }
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

## Performance Tips

- Use `.insetGrouped` list style instead of custom backgrounds (more efficient)
- `AppleSpacing` constants reduce layout calculations
- Material effects are GPU-accelerated (minimal performance impact)
- `.symbolRenderingMode()` is cached by SwiftUI
- Avoid nesting materials (one material per container is optimal)

---

## Accessibility Checklist

For each updated view:
- [ ] All interactive elements have accessibility labels
- [ ] Color is not used alone for meaning
- [ ] Text has sufficient contrast (4.5:1 minimum)
- [ ] Touch targets are minimum 44pt
- [ ] Focus indicators visible in dark mode

---

## Rollout Strategy

### Batch 1 (Today): Core Views
- Dashboard
- Students Table ✅
- Attendance Table ✅

### Batch 2: Feature Tables
- Grades
- Messages
- Timetable
- Notifications

### Batch 3: Forms & Details
- All form views
- Detail views
- Settings views

### Batch 4: Polish
- Supporting components
- Edge cases
- Testing & QA

---

## Resources

- `docs/apple-design-guidelines.md` - Complete design system guide
- `shared/ui/design-system/` - Source files with all modifiers
- Example: `features/dashboard/views/dashboard-content.swift`
- Example: `features/students/views/students-table.swift`

---

## Need Help?

1. **Check existing implementations** - Look at completed views first
2. **Read the guidelines** - See `apple-design-guidelines.md`
3. **Copy templates above** - Use exact code blocks provided
4. **Test on simulator** - Always verify visual appearance
5. **Compare before/after** - Use git diff to review changes

---

**Last Updated**: February 2025
