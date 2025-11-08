import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

public struct GradientStop: Codable, Hashable, Sendable {
    public var position: Double {
        didSet { position = position.clamped(to: 0 ... 1) }
    }
    public var color: ColorDescriptor

    public init(position: Double, color: ColorDescriptor) {
        self.position = position.clamped(to: 0 ... 1)
        self.color = color
    }
}

public enum SymbolColor: Codable, Hashable, Sendable {
    case solid(ColorDescriptor)
    case gradient([GradientStop])
}

public struct PaletteState: Codable, Hashable, Sendable {
    public var background: ColorDescriptor
    public var symbols: SymbolColor

    public init(
        background: ColorDescriptor = .preset(.black),
        symbols: SymbolColor = .solid(.preset(.white))
    ) {
        self.background = background
        self.symbols = symbols
    }
}

public struct ColorDescriptor: Codable, Hashable, Sendable {
    public enum Preset: String, Codable, CaseIterable, Sendable {
        case black, white, cyan, magenta, yellow, orange, pink, teal
    }

    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    public var preset: Preset?

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0, preset: Preset? = nil) {
        self.red = red.clamped(to: 0 ... 1)
        self.green = green.clamped(to: 0 ... 1)
        self.blue = blue.clamped(to: 0 ... 1)
        self.alpha = alpha.clamped(to: 0 ... 1)
        self.preset = preset
    }

    public static func preset(_ preset: Preset) -> ColorDescriptor {
        switch preset {
        case .black: return ColorDescriptor(red: 0, green: 0, blue: 0, preset: preset)
        case .white: return ColorDescriptor(red: 1, green: 1, blue: 1, preset: preset)
        case .cyan: return ColorDescriptor(red: 0, green: 0.68, blue: 0.94, preset: preset)
        case .magenta: return ColorDescriptor(red: 0.8, green: 0.13, blue: 0.75, preset: preset)
        case .yellow: return ColorDescriptor(red: 1, green: 0.89, blue: 0.01, preset: preset)
        case .orange: return ColorDescriptor(red: 0.99, green: 0.55, blue: 0, preset: preset)
        case .pink: return ColorDescriptor(red: 1, green: 0.53, blue: 0.77, preset: preset)
        case .teal: return ColorDescriptor(red: 0, green: 0.76, blue: 0.75, preset: preset)
        }
    }
}

#if canImport(SwiftUI)
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension ColorDescriptor {
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
#endif

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

