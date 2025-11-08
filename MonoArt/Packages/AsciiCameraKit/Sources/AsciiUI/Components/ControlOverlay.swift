#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 15.0, *)
public struct ControlOverlay: View {
    public let selectedEffect: EffectType
    public let availableEffects: [EffectType]
    public let isCaptureInFlight: Bool
    public let onImport: () -> Void
    public let onCapture: () -> Void
    public let onFlip: () -> Void
    public let onSelectEffect: (EffectType) -> Void
    public let onShowColors: () -> Void

    public init(
        selectedEffect: EffectType,
        availableEffects: [EffectType] = EffectType.allCases,
        isCaptureInFlight: Bool,
        onImport: @escaping () -> Void,
        onCapture: @escaping () -> Void,
        onFlip: @escaping () -> Void,
        onSelectEffect: @escaping (EffectType) -> Void,
        onShowColors: @escaping () -> Void
    ) {
        self.selectedEffect = selectedEffect
        self.availableEffects = availableEffects
        self.isCaptureInFlight = isCaptureInFlight
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSelectEffect = onSelectEffect
        self.onShowColors = onShowColors
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableEffects, id: \.self) { effect in
                        Button(action: { onSelectEffect(effect) }) {
                            Text(effect.displayTitle)
                                .font(.callout.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(effectBackground(for: effect))
                                .foregroundStyle(effectForeground(for: effect))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(effect == selectedEffect ? Color.accentColor : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select \(effect.displayTitle) effect")
                        .accessibilityAddTraits(effect == selectedEffect ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 16) {
                Button(action: onImport) {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .labelStyle(.titleAndIcon)
                        .padding()
                        .frame(minWidth: 88)
                }
                .buttonStyle(ControlButtonStyle())
                .accessibilityHint("Import an existing photo to convert into ASCII art")

                Button(action: onCapture) {
                    Label(isCaptureInFlight ? "Saving" : "Capture", systemImage: "camera.shutter.button")
                        .labelStyle(.titleAndIcon)
                        .padding()
                        .frame(minWidth: 120)
                }
                .buttonStyle(ControlButtonStyle(primary: true))
                .disabled(isCaptureInFlight)
                .accessibilityHint(isCaptureInFlight ? "Saving capture to Photos" : "Capture current frame and save to Photos")

                Button(action: onFlip) {
                    Label("Flip", systemImage: "camera.rotate")
                        .labelStyle(.titleAndIcon)
                        .padding()
                        .frame(minWidth: 88)
                }
                .buttonStyle(ControlButtonStyle())
                .accessibilityHint("Switch between front and back cameras")

                Spacer(minLength: 16)

                Button(action: onShowColors) {
                    Label("Colors", systemImage: "paintpalette")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .accessibilityLabel("Open color picker")
                .accessibilityHint("Adjust background or symbol colors")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func effectBackground(for effect: EffectType) -> some ShapeStyle {
        effect == selectedEffect ? AnyShapeStyle(Color.accentColor.opacity(0.15)) : AnyShapeStyle(Color.black.opacity(0.35))
    }

    private func effectForeground(for effect: EffectType) -> some ShapeStyle {
        effect == selectedEffect ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.white)
    }
}

private struct ControlButtonStyle: ButtonStyle {
    var primary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: 56)
            .frame(minWidth: 88)
            .background(primary ? Color.accentColor : Color.white.opacity(0.1))
            .foregroundColor(primary ? Color.white : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.6 : 0.25), lineWidth: primary ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

private extension EffectType {
    var displayTitle: String {
        rawValue.capitalized
    }
}
#endif

