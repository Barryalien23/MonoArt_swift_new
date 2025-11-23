#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 15.0, *)
public struct EffectSelectionView: View {
    let selectedEffect: EffectType
    let availableEffects: [EffectType]
    let onSelectEffect: (EffectType) -> Void
    let onDismiss: () -> Void

    public init(
        selectedEffect: EffectType,
        availableEffects: [EffectType],
        onSelectEffect: @escaping (EffectType) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.selectedEffect = selectedEffect
        self.availableEffects = availableEffects
        self.onSelectEffect = onSelectEffect
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Black background container
            VStack(spacing: 0) {
                Spacer()
                
                // Horizontal scrollable effects list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSpacing.s) {
                        ForEach(availableEffects, id: \.self) { effect in
                            EffectTile(
                                effect: effect,
                                isSelected: effect == selectedEffect,
                                action: {
                                    onSelectEffect(effect)
                                }
                            )
                        }
                    }
                    .padding(.leading, DesignSpacing.xl)
                    .padding(.trailing, 100)
                }
                .padding(.vertical, DesignSpacing.xl)
                .background(DesignColor.black)
            }

            // Back button with gradient shadow overlay on the right
            HStack(spacing: 0) {
                Spacer()
                backButtonWithShadow
            }
            .padding(.bottom, DesignSpacing.xl)
        }
        .frame(height: 152)
    }

    private var backButtonWithShadow: some View {
        ZStack(alignment: .trailing) {
            // Gradient shadow overlay extending to the right edge
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: DesignColor.black.opacity(0), location: 0),
                    .init(color: DesignColor.black, location: 0.5)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 100, height: 120)
            .frame(maxWidth: .infinity, alignment: .trailing)

            // Back button overlaid on top
            Button(action: onDismiss) {
                DesignIconView(.arrowBack, color: DesignColor.white, size: 16)
                    .offset(x: -4)
                    .frame(width: 64, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                            .fill(DesignColor.mainGrey)
                            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
                    )
            }
            .buttonStyle(DesignPressFeedbackStyle())
            .padding(.trailing, DesignSpacing.xl)
        }
    }
}

@available(iOS 15.0, *)
private struct EffectTile: View {
    let effect: EffectType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.s) {
                DesignIconView(effectIcon(for: effect), color: DesignColor.white, size: 16)
                DesignTokens.Typography.body1.text(effect.displayTitle)
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
            .fill(isSelected ? DesignColor.greyActive : DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private func effectIcon(for effect: EffectType) -> DesignIcon {
        switch effect {
        case .ascii: return .effectASCII
        case .shapes: return .effectShapes
        case .circle: return .effectCircle
        case .square: return .effectSquare
        case .triangle: return .effectTriangle
        case .diamond: return .effectDiamond
        }
    }
}
#endif

