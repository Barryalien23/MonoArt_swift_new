import Foundation

/// Mirrors the Android `EffectType` enum while remaining extensible for future Metal kernels.
/// - See: SwiftStarterBundle/Docs/Swift/EffectsAndColors.md for behavioral constraints.
public enum EffectType: String, CaseIterable, Codable, Sendable {
    case ascii
    case shapes
    case circles
    case squares
    case triangles
    case diamonds

    /// Parameters that are relevant to this effect.
    /// This allows the UI to selectively enable sliders while keeping the reducer generic.
    public var supportedParameters: Set<EffectParameter> {
        switch self {
        case .ascii:
            return [.cell, .jitter, .softy, .edge]
        case .shapes:
            return [.cell, .jitter, .softy]
        case .circles:
            return [.cell, .jitter, .softy]
        case .squares:
            return [.cell, .edge]
        case .triangles:
            return [.cell, .jitter]
        case .diamonds:
            return [.cell, .softy, .edge]
        }
    }
}

public enum EffectParameter: String, CaseIterable, Codable, Sendable {
    case cell
    case jitter
    case softy
    case edge

    public var displayName: String {
        switch self {
        case .cell: return "Cell"
        case .jitter: return "Jitter"
        case .softy: return "Contrast"
        case .edge: return "Edge"
        }
    }
}

public struct EffectParameterValue: Codable, Hashable, Sendable {
    public static let range: ClosedRange<Double> = 0 ... 100

    public var rawValue: Double {
        didSet {
            rawValue = rawValue.clamped(to: Self.range)
        }
    }

    public init(_ rawValue: Double) {
        self.rawValue = rawValue.clamped(to: Self.range)
    }
}

public struct EffectParameters: Codable, Hashable, Sendable {
    public var cell: EffectParameterValue
    public var jitter: EffectParameterValue
    public var softy: EffectParameterValue
    public var edge: EffectParameterValue

    public init(
        cell: EffectParameterValue = EffectParameterValue(40),
        jitter: EffectParameterValue = EffectParameterValue(20),
        softy: EffectParameterValue = EffectParameterValue(10),
        edge: EffectParameterValue = EffectParameterValue(30)
    ) {
        self.cell = cell
        self.jitter = jitter
        self.softy = softy
        self.edge = edge
    }

    public mutating func update(_ parameter: EffectParameter, value: Double) {
        let clamped = EffectParameterValue(value)
        switch parameter {
        case .cell: cell = clamped
        case .jitter: jitter = clamped
        case .softy: softy = clamped
        case .edge: edge = clamped
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

