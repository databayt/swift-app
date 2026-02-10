import SwiftUI

/// Apple's 8pt grid spacing system
/// Consistent spacing values used throughout the app for alignment and layout
enum AppleSpacing {
    /// 4pt - Tight spacing between related elements
    static let tiny: CGFloat = 4

    /// 8pt - Compact spacing, used for tight layouts
    static let compact: CGFloat = 8

    /// 12pt - Small spacing for grouped elements
    static let small: CGFloat = 12

    /// 16pt - Standard spacing (default padding)
    static let standard: CGFloat = 16

    /// 20pt - iPad margins and comfortable spacing
    static let comfortable: CGFloat = 20

    /// 24pt - Large spacing for major sections
    static let large: CGFloat = 24

    /// 32pt - Extra large spacing for distinct sections
    static let extraLarge: CGFloat = 32

    /// 44pt - Minimum touch target height (accessibility)
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Edge Insets

extension EdgeInsets {
    /// Standard padding: 16pt on all sides
    static let standard = EdgeInsets(
        top: AppleSpacing.standard,
        leading: AppleSpacing.standard,
        bottom: AppleSpacing.standard,
        trailing: AppleSpacing.standard
    )

    /// Compact padding: 8pt on all sides
    static let compact = EdgeInsets(
        top: AppleSpacing.compact,
        leading: AppleSpacing.compact,
        bottom: AppleSpacing.compact,
        trailing: AppleSpacing.compact
    )

    /// Comfortable padding: 20pt on all sides
    static let comfortable = EdgeInsets(
        top: AppleSpacing.comfortable,
        leading: AppleSpacing.comfortable,
        bottom: AppleSpacing.comfortable,
        trailing: AppleSpacing.comfortable
    )

    /// Horizontal padding only: 16pt
    static let horizontalStandard = EdgeInsets(
        top: 0,
        leading: AppleSpacing.standard,
        bottom: 0,
        trailing: AppleSpacing.standard
    )

    /// Vertical padding only: 16pt
    static let verticalStandard = EdgeInsets(
        top: AppleSpacing.standard,
        leading: 0,
        bottom: AppleSpacing.standard,
        trailing: 0
    )
}

// MARK: - Convenience View Extensions

extension View {
    /// Apply standard padding (16pt)
    func standardPadding() -> some View {
        padding(AppleSpacing.standard)
    }

    /// Apply compact padding (8pt)
    func compactPadding() -> some View {
        padding(AppleSpacing.compact)
    }

    /// Apply comfortable padding (20pt)
    func comfortablePadding() -> some View {
        padding(AppleSpacing.comfortable)
    }

    /// Apply horizontal padding only
    func horizontalPadding(_ amount: CGFloat = AppleSpacing.standard) -> some View {
        padding(.horizontal, amount)
    }

    /// Apply vertical padding only
    func verticalPadding(_ amount: CGFloat = AppleSpacing.standard) -> some View {
        padding(.vertical, amount)
    }
}
