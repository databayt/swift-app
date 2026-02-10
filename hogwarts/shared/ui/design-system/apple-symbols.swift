import SwiftUI

/// Standardized SF Symbol wrapper for consistent rendering across the app
struct AppleSymbol: View {
    let name: String
    let renderingMode: SymbolRenderingMode
    let color: Color
    let size: Font?

    init(
        _ name: String,
        renderingMode: SymbolRenderingMode = .hierarchical,
        color: Color = .primary,
        size: Font? = nil
    ) {
        self.name = name
        self.renderingMode = renderingMode
        self.color = color
        self.size = size
    }

    var body: some View {
        Image(systemName: name)
            .symbolRenderingMode(renderingMode)
            .foregroundStyle(color)
            .if(size != nil) { view in
                view.font(size)
            }
    }
}

// MARK: - Symbol Variants

extension AppleSymbol {
    /// Create hierarchical symbol (recommended for most cases)
    static func hierarchical(
        _ name: String,
        color: Color = .primary,
        size: Font? = nil
    ) -> AppleSymbol {
        AppleSymbol(name, renderingMode: .hierarchical, color: color, size: size)
    }

    /// Create monochrome symbol (single color)
    static func monochrome(
        _ name: String,
        color: Color = .primary,
        size: Font? = nil
    ) -> AppleSymbol {
        AppleSymbol(name, renderingMode: .monochrome, color: color, size: size)
    }

    /// Create palette symbol (multi-color)
    static func palette(
        _ name: String,
        primaryColor: Color = .primary,
        secondaryColor: Color = .secondary,
        size: Font? = nil
    ) -> AppleSymbol {
        AppleSymbol(
            name,
            renderingMode: .palette,
            color: primaryColor,
            size: size
        )
    }

    /// Create multicolor symbol (Apple's predefined colors)
    static func multicolor(
        _ name: String,
        size: Font? = nil
    ) -> AppleSymbol {
        AppleSymbol(name, renderingMode: .multicolor, color: .primary, size: size)
    }
}

// MARK: - Common Symbol Factory

enum AppleSymbols {
    // Navigation
    static let home = AppleSymbol("house.fill")
    static let settings = AppleSymbol("gear")
    static let profile = AppleSymbol("person.fill")
    static let back = AppleSymbol("chevron.left")
    static let forward = AppleSymbol("chevron.right")
    static let menu = AppleSymbol("line.3.horizontal")

    // Actions
    static let add = AppleSymbol("plus")
    static let close = AppleSymbol("xmark")
    static let search = AppleSymbol("magnifyingglass")
    static let filter = AppleSymbol("funnel")
    static let sort = AppleSymbol("arrow.up.arrow.down")
    static let share = AppleSymbol("square.and.arrow.up")
    static let delete = AppleSymbol("trash")
    static let edit = AppleSymbol("pencil")

    // Status
    static let checkmark = AppleSymbol("checkmark.circle.fill")
    static let error = AppleSymbol("exclamationmark.circle.fill")
    static let warning = AppleSymbol("exclamationmark.triangle.fill")
    static let info = AppleSymbol("info.circle.fill")
    static let loading = AppleSymbol("hourglass")

    // School
    static let attendance = AppleSymbol("checkmark.circle.fill")
    static let grades = AppleSymbol("chart.bar.fill")
    static let schedule = AppleSymbol("calendar")
    static let classes = AppleSymbol("book.fill")
    static let students = AppleSymbol("person.2.fill")
    static let messages = AppleSymbol("bubble.left.fill")
    static let notifications = AppleSymbol("bell.fill")

    // Common
    static let empty = AppleSymbol("square.dashed")
    static let download = AppleSymbol("arrow.down.circle")
    static let upload = AppleSymbol("arrow.up.circle")
}

// MARK: - View Extension for Conditional Logic

extension View {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - SF Symbol Extensions

extension Image {
    /// Create symbol with hierarchical rendering
    init(hierarchical name: String) {
        self.init(systemName: name)
    }

    /// Apply Apple's standard symbol formatting
    func appleSymbolFormatting(
        renderingMode: SymbolRenderingMode = .hierarchical,
        foregroundColor: Color = .primary,
        size: Font = .body
    ) -> some View {
        self
            .symbolRenderingMode(renderingMode)
            .foregroundStyle(foregroundColor)
            .font(size)
    }
}
