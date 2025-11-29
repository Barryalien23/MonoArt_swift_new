#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 15.0, *)
public struct EffectSelectionView: View {
    let selectedEffect: EffectType
    let availableEffects: [EffectType]
    let isCaptureInFlight: Bool
    let isImportMode: Bool
    let onSelectEffect: (EffectType) -> Void
    let onDismiss: () -> Void
    let onImport: () -> Void
    let onCapture: () -> Void
    let onFlip: () -> Void
    let onSaveImport: () -> Void
    let onCancelImport: () -> Void

    public init(
        selectedEffect: EffectType,
        availableEffects: [EffectType],
        isCaptureInFlight: Bool = false,
        isImportMode: Bool = false,
        onSelectEffect: @escaping (EffectType) -> Void,
        onDismiss: @escaping () -> Void,
        onImport: @escaping () -> Void,
        onCapture: @escaping () -> Void,
        onFlip: @escaping () -> Void,
        onSaveImport: @escaping () -> Void,
        onCancelImport: @escaping () -> Void
    ) {
        self.selectedEffect = selectedEffect
        self.availableEffects = availableEffects
        self.isCaptureInFlight = isCaptureInFlight
        self.isImportMode = isImportMode
        self.onSelectEffect = onSelectEffect
        self.onDismiss = onDismiss
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSaveImport = onSaveImport
        self.onCancelImport = onCancelImport
    }

    public var body: some View {
        VStack(spacing: DesignSpacing.s) {
            // Action bar for import/capture/flip
            DesignActionBar(
                mode: isImportMode ? .import : .camera,
                primaryState: isCaptureInFlight ? .processing : .idle,
                isLocked: isCaptureInFlight,
                onLeft: onImport,
                onPrimary: isImportMode ? onSaveImport : onCapture,
                onRight: isImportMode ? onCancelImport : onFlip
            )
            
            // Effects selection container
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
            .shadow(color: DesignColor.black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
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

