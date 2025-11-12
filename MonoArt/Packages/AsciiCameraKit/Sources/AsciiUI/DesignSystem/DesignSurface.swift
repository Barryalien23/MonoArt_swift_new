import SwiftUI

public enum DesignSurfaceStyle {
    case glassButton
    case glassTile
    case glassCard

    fileprivate var cornerRadius: CGFloat {
        switch self {
        case .glassButton:
            return DesignRadius.lg
        case .glassTile:
            return DesignRadius.md
        case .glassCard:
            return DesignRadius.xl
        }
    }

    fileprivate var borderWidth: CGFloat {
        switch self {
        case .glassButton:
            return 1.5
        case .glassTile:
            return 1
        case .glassCard:
            return 1
        }
    }

    fileprivate var shadow: DesignTokens.ShadowStyle {
        switch self {
        case .glassButton:
            return DesignTokens.Shadow.glass
        case .glassTile:
            return DesignTokens.Shadow.blur
        case .glassCard:
            return DesignTokens.Shadow.block
        }
    }
}

public struct DesignSurface: View {
    private let style: DesignSurfaceStyle
    private let cornerRadiusOverride: CGFloat?

    public init(_ style: DesignSurfaceStyle, cornerRadius: CGFloat? = nil) {
        self.style = style
        self.cornerRadiusOverride = cornerRadius
    }

    public var body: some View {
        let cornerRadius = cornerRadiusOverride ?? style.cornerRadius
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return shapeFill(shape)
            .overlay(border(shape))
            .shadow(style.shadow)
    }

    @ViewBuilder
    private func shapeFill(_ shape: RoundedRectangle) -> some View {
        switch style {
        case .glassButton:
            ZStack {
                if #available(iOS 15.0, *) {
                    shape.fill(.ultraThinMaterial)
                }
                shape.fill(DesignColor.white08)
            }
        case .glassTile:
            shape
                .fill(DesignColor.mainGrey)
                .overlay(shape.fill(DesignColor.white04))
        case .glassCard:
            ZStack {
                if #available(iOS 15.0, *) {
                    shape.fill(.ultraThinMaterial)
                }
                shape.fill(DesignColor.white08)
            }
        }
    }

    @ViewBuilder
    private func border(_ shape: RoundedRectangle) -> some View {
        switch style {
        case .glassButton:
            shape.stroke(DesignColor.white20, lineWidth: style.borderWidth)
        case .glassTile:
            shape.stroke(DesignColor.white08, lineWidth: style.borderWidth)
        case .glassCard:
            shape.stroke(DesignColor.white12, lineWidth: style.borderWidth)
        }
    }
}

private extension View {
    func shadow(_ style: DesignTokens.ShadowStyle) -> some View {
        shadow(color: DesignColor.black.opacity(style.opacity), radius: style.radius, x: style.x, y: style.y)
    }
}
