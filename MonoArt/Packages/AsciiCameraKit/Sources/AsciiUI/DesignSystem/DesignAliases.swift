import SwiftUI

public enum DesignColor {
    public static let mainGrey = DesignTokens.Colors.mainGrey
    public static let black = DesignTokens.Colors.black
    public static let white = DesignTokens.Colors.white
    public static let white60 = DesignTokens.Colors.white60
    public static let white40 = DesignTokens.Colors.white40
    public static let white20 = DesignTokens.Colors.white20
    public static let white12 = DesignTokens.Colors.white12
    public static let white08 = DesignTokens.Colors.white08
    public static let white04 = DesignTokens.Colors.white04
    public static let greyActive = DesignTokens.Colors.greyActive
    public static let greyDisable = DesignTokens.Colors.greyDisable
}

public enum DesignSpacing {
    public static let zero = DesignTokens.Spacing.zero
    public static let xxs = DesignTokens.Spacing.xxs   // 2
    public static let xs = DesignTokens.Spacing.xs     // 3
    public static let s = DesignTokens.Spacing.s       // 4
    public static let sm = DesignTokens.Spacing.sm     // 6
    public static let md = DesignTokens.Spacing.md     // 8
    public static let lg = DesignTokens.Spacing.lg     // 10
    public static let base = DesignTokens.Spacing.base // 12
    public static let xl = DesignTokens.Spacing.xl     // 16
    public static let xxl = DesignTokens.Spacing.xxl   // 20
}

public enum DesignRadius {
    public static let sm = DesignTokens.CornerRadius.sm
    public static let md = DesignTokens.CornerRadius.md
    public static let lg = DesignTokens.CornerRadius.lg
    public static let xl = DesignTokens.CornerRadius.xl
}

public enum DesignTypography {
    public static func body1() -> Font {
        DesignTokens.Typography.body1.font()
    }

    public static func body2() -> Font {
        DesignTokens.Typography.body2.font()
    }

    public static func head1() -> Font {
        DesignTokens.Typography.head1.font()
    }
}
