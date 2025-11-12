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
                                    onDismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, DesignSpacing.xl)
                }
                .padding(.vertical, DesignSpacing.xl)
                .background(DesignColor.black.opacity(0.92))
            }

            // Back button with gradient shadow overlay on the right
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    backButtonWithShadow
                        .padding(.trailing, DesignSpacing.xl)
                        .padding(.bottom, DesignSpacing.xl)
                }
            }
        }
        .frame(height: 152)
    }

    private var backButtonWithShadow: some View {
        ZStack(alignment: .trailing) {
            // Gradient shadow overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: DesignColor.black.opacity(0), location: 0),
                    .init(color: DesignColor.black.opacity(0.87), location: 0.13)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 87)

            // Back button
            Button(action: onDismiss) {
                VStack(spacing: DesignSpacing.s) {
                    DesignIconView(.arrowBack, color: DesignColor.white, size: 24)
                }
                .frame(width: 64, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                        .fill(DesignColor.mainGrey)
                        .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(DesignPressFeedbackStyle())
            .padding(.leading, DesignSpacing.base)
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
            .fill(DesignColor.mainGrey)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .stroke(isSelected ? DesignColor.white : Color.clear, lineWidth: 1)
            )
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
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
#endif

