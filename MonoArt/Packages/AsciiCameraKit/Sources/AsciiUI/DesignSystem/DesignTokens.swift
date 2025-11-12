import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import CoreText

public enum DesignTokens {
    public enum Colors {
        private static func color(red: Double, green: Double, blue: Double, opacity: Double = 1) -> Color {
            Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
        }

        /// #1A1A1A – Primary background
        public static let mainGrey = color(red: 0.10196078, green: 0.10196078, blue: 0.10196078)
        /// #000000 – Pure black
        public static let black = color(red: 0, green: 0, blue: 0)
        /// #FFFFFF – Fully opaque white
        public static let white = color(red: 1, green: 1, blue: 1)
        /// White with 60% opacity
        public static let white60 = color(red: 1, green: 1, blue: 1, opacity: 0.6)
        /// White with 40% opacity
        public static let white40 = color(red: 1, green: 1, blue: 1, opacity: 0.4)
        /// White with 20% opacity
        public static let white20 = color(red: 1, green: 1, blue: 1, opacity: 0.2)
        /// White with 12% opacity
        public static let white12 = color(red: 1, green: 1, blue: 1, opacity: 0.12)
        /// White with 8% opacity
        public static let white08 = color(red: 1, green: 1, blue: 1, opacity: 0.08)
        /// White with 4% opacity
        public static let white04 = color(red: 1, green: 1, blue: 1, opacity: 0.04)
        /// #151515 – Active grey surface
        public static let greyActive = color(red: 0.14509805, green: 0.14509805, blue: 0.14509805)
        /// #141414 – Disabled grey surface
        public static let greyDisable = color(red: 0.08, green: 0.08, blue: 0.08)
    }

    public enum Spacing {
        public static let zero: CGFloat = 0
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 3
        public static let s: CGFloat = 4
        public static let sm: CGFloat = 6
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 10
        public static let base: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let xxl: CGFloat = 20
    }

    public enum CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
    }

    public enum Shadow {
        public static let block = ShadowStyle(radius: 16, y: -30, opacity: 0.3)
        public static let knob = ShadowStyle(radius: 3, y: 0, opacity: 0.1)
        public static let blur = ShadowStyle(radius: 8, y: 0, opacity: 0.1)
        public static let glass = ShadowStyle(radius: 12, y: 0, opacity: 0.18)
    }

    public struct ShadowStyle {
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
        public let opacity: Double

        public init(radius: CGFloat, x: CGFloat = 0, y: CGFloat, opacity: Double) {
            self.radius = radius
            self.x = x
            self.y = y
            self.opacity = opacity
        }
    }

    public enum Typography {
        public static let body1 = FontStyle(size: 12, weight: .medium, lineHeight: 16, uppercase: true)
        public static let body2 = FontStyle(size: 12, weight: .semibold, lineHeight: 16, uppercase: true)
        public static let head1 = FontStyle(size: 14, weight: .semibold, lineHeight: 18, uppercase: true)
    }

    public struct FontStyle {
        public let size: CGFloat
        public let weight: FontWeight
        public let lineHeight: CGFloat
        public let uppercase: Bool

        public init(size: CGFloat, weight: FontWeight, lineHeight: CGFloat, uppercase: Bool) {
            self.size = size
            self.weight = weight
            self.lineHeight = lineHeight
            self.uppercase = uppercase
        }

        public func font() -> Font {
            DesignTokens.Fonts.font(weight: weight, size: size)
        }

        public func text(_ string: String) -> Text {
            let value = uppercase ? string.uppercased() : string
            return Text(value).font(font())
        }

        public func apply<T: View>(to view: T) -> some View {
            view.modifier(FontStyleModifier(style: self))
        }

        #if canImport(UIKit)
        public func uiFont() -> UIFont {
            DesignTokens.Fonts.uiFont(weight: weight, size: size)
        }
        #endif
    }

    private struct FontStyleModifier: ViewModifier {
        let style: FontStyle

        func body(content: Content) -> some View {
            content
                .font(style.font())
                .lineSpacing(lineSpacing)
        }

        private var lineSpacing: CGFloat {
            max(style.lineHeight - style.size, 0)
        }
    }

    public enum FontWeight: String {
        case regular = "IBMPlexMono-Regular"
        case medium = "IBMPlexMono-Medium"
        case semibold = "IBMPlexMono-SemiBold"
        case bold = "IBMPlexMono-Bold"
    }

    public enum Fonts {
        private static let fontNames: [FontWeight: String] = [
            .regular: "IBMPlexMono-Regular",
            .medium: "IBMPlexMono-Medium",
            .semibold: "IBMPlexMono-SemiBold",
            .bold: "IBMPlexMono-Bold"
        ]

        private static let registration: Void = {
            FontRegistrar.registerFonts()
        }()

        public static func ensureRegistered() {
            _ = registration
        }

        public static func font(weight: FontWeight, size: CGFloat) -> Font {
            ensureRegistered()
            return Font.custom(fontNames[weight] ?? weight.rawValue, size: size)
        }

        #if canImport(UIKit)
        public static func uiFont(weight: FontWeight, size: CGFloat) -> UIFont {
            ensureRegistered()
            return UIFont(name: fontNames[weight] ?? weight.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
        }
        #endif
    }
}
