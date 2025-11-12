#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 15.0, *)
public struct ControlOverlay: View {
    public let selectedEffect: EffectType
    public let availableEffects: [EffectType]
    public let isCaptureInFlight: Bool
    public let isImportMode: Bool
    public let palette: PaletteState
    public let selectedColorTarget: ColorTarget
    public let onImport: () -> Void
    public let onCapture: () -> Void
    public let onFlip: () -> Void
    public let onSaveImport: (() -> Void)?
    public let onCancelImport: (() -> Void)?
    public let onSelectEffect: (EffectType) -> Void
    public let onSelectColorTarget: (ColorTarget) -> Void
    public let onShowEffects: () -> Void
    public let onShowSettings: () -> Void
    public let onShowColors: () -> Void

    public init(
        selectedEffect: EffectType,
        availableEffects: [EffectType] = EffectType.allCases,
        isCaptureInFlight: Bool,
        isImportMode: Bool,
        palette: PaletteState,
        selectedColorTarget: ColorTarget,
        onImport: @escaping () -> Void,
        onCapture: @escaping () -> Void,
        onFlip: @escaping () -> Void,
        onSaveImport: (() -> Void)? = nil,
        onCancelImport: (() -> Void)? = nil,
        onSelectEffect: @escaping (EffectType) -> Void,
        onSelectColorTarget: @escaping (ColorTarget) -> Void,
        onShowEffects: @escaping () -> Void,
        onShowSettings: @escaping () -> Void,
        onShowColors: @escaping () -> Void
    ) {
        self.selectedEffect = selectedEffect
        self.availableEffects = availableEffects
        self.isCaptureInFlight = isCaptureInFlight
        self.isImportMode = isImportMode
        self.palette = palette
        self.selectedColorTarget = selectedColorTarget
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSaveImport = onSaveImport
        self.onCancelImport = onCancelImport
        self.onSelectEffect = onSelectEffect
        self.onSelectColorTarget = onSelectColorTarget
        self.onShowEffects = onShowEffects
        self.onShowSettings = onShowSettings
        self.onShowColors = onShowColors
    }

    public var body: some View {
        VStack(spacing: DesignSpacing.base) {
            DesignActionBar(
                mode: isImportMode ? .import : .camera,
                primaryState: isCaptureInFlight ? .processing : .idle,
                isLocked: false,
                onLeft: onImport,
                onPrimary: isImportMode ? (onSaveImport ?? onCapture) : onCapture,
                onRight: isImportMode ? (onCancelImport ?? onFlip) : onFlip
            )

            VStack(alignment: .leading, spacing: DesignSpacing.base) {
                HStack(alignment: .top, spacing: DesignSpacing.base) {
                    effectTile

                    VStack(alignment: .leading, spacing: DesignSpacing.base) {
                        settingsRow
                        colorRow
                    }
                }
            }
            .padding(.horizontal, DesignSpacing.xl)
            .padding(.vertical, DesignSpacing.base)
            .background(controllerBackground)
            .shadow(color: DesignColor.black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }

    private var controllerBackground: Color {
        DesignColor.black.opacity(0.92)
    }

    private var effectTile: some View {
        DesignEffectTile(
            icon: effectIcon(for: selectedEffect),
            title: selectedEffect.displayTitle,
            action: onShowEffects
        )
    }

    private var settingsRow: some View {
        HStack(spacing: DesignSpacing.base) {
            DesignParameterTile(icon: .settingCell, title: "CELL", action: onShowSettings)
            DesignParameterTile(icon: .settingJitter, title: "JITTER", action: onShowSettings)
            DesignParameterTile(icon: .settingContrast, title: "CONTRAST", action: onShowSettings)
        }
    }

    private var colorRow: some View {
        HStack(spacing: DesignSpacing.base) {
            DesignColorTile(
                title: "BG COLOR",
                indicator: .solid(palette.background.swiftUIColor),
                isActive: selectedColorTarget == .background,
                action: {
                    onSelectColorTarget(.background)
                    onShowColors()
                }
            )

            DesignColorTile(
                title: "COLOR #2",
                indicator: symbolIndicator,
                isActive: selectedColorTarget == .symbols && !isGradientActive,
                action: {
                    onSelectColorTarget(.symbols)
                    onShowColors()
                }
            )

            DesignColorTile(
                title: "GRADIENT",
                indicator: gradientIndicator,
                isActive: isGradientActive,
                action: {
                    onSelectColorTarget(.symbols)
                    onShowColors()
                }
            )
        }
    }

    private var symbolIndicator: DesignColorIndicator.Kind {
        switch palette.symbols {
        case .solid(let descriptor):
            return .solid(descriptor.swiftUIColor)
        case .gradient(let stops):
            return .gradient(gradient(from: stops))
        }
    }

    private var gradientIndicator: DesignColorIndicator.Kind {
        switch palette.symbols {
        case .gradient(let stops):
            return .gradient(gradient(from: stops))
        case .solid:
            return .solid(DesignColor.white20)
        }
    }

    private var isGradientActive: Bool {
        if case .gradient = palette.symbols { return true }
        return false
    }

    private func gradient(from stops: [GradientStop]) -> Gradient {
        if stops.isEmpty {
            return Gradient(colors: [DesignColor.white, DesignColor.white60])
        }
        let gradientStops = stops.map {
            Gradient.Stop(color: $0.color.swiftUIColor, location: $0.position)
        }
        return Gradient(stops: gradientStops)
    }

    private func effectIcon(for effect: EffectType) -> DesignIcon {
        switch effect {
        case .ascii: return .effectASCII
        case .shapes: return .effectShapes
        case .circles: return .effectCircle
        case .squares: return .effectSquare
        case .triangles: return .effectTriangle
        case .diamonds: return .effectDiamond
        }
    }
}

@available(iOS 15.0, *)
private struct DesignEffectTile: View {
    let icon: DesignIcon
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.s) {
                DesignIconView(icon, color: DesignColor.white, size: 18)
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 64, height: 120)
            .background(tileBackground)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

@available(iOS 15.0, *)
private struct DesignParameterTile: View {
    let icon: DesignIcon
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.s) {
                DesignIconView(icon, color: DesignColor.white, size: 16)
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
            }
            .frame(width: 100, height: 56)
            .background(tileBackground)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

@available(iOS 15.0, *)
private struct DesignColorTile: View {
    let title: String
    let indicator: DesignColorIndicator.Kind
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.s) {
                DesignColorIndicator(kind: indicator)
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
            }
            .frame(width: 100, height: 56)
            .background(tileBackground)
            .opacity(isActive ? 1 : 0.9)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

@available(iOS 15.0, *)
private struct DesignColorIndicator: View {
    enum Kind {
        case solid(Color)
        case gradient(Gradient)
    }

    let kind: Kind

    var body: some View {
        ZStack {
            fillLayer
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(DesignColor.white, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var fillLayer: some View {
        switch kind {
        case .solid(let color):
            Circle().fill(color)
        case .gradient(let gradient):
            Circle().fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
}

#endif

