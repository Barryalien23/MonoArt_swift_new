#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 16.0, *)
public struct EffectSettingsSheet: View {
    @ObservedObject private var viewModel: AppViewModel

    public init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                    effectSelector
                    parameterSection
                    resetButton
                }
                .padding(DesignSpacing.xl)
                    }
            .background(DesignColor.mainGrey.ignoresSafeArea())
            .navigationTitle("Effect Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.dismissSettingsSheet() }
                        .font(DesignTypography.body2())
                }
            }
        }
    }

    private var effectSelector: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            DesignTokens.Typography.body2.text("EFFECT")
                .foregroundColor(DesignColor.white60)

            DesignSegmentedControl(
                options: EffectType.allCases,
                selection: Binding(
                    get: { viewModel.selectedEffect },
                    set: { newValue in viewModel.selectEffect(newValue) }
                ),
                spacing: DesignSpacing.sm,
                showsBackground: true,
                configuration: { effect in
                    DesignSegmentButton.Configuration(
                        title: effect.displayTitle,
                        icon: effectIcon(for: effect)
                    )
                }
            )
        }
    }

    private var parameterSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            DesignTokens.Typography.body2.text("PARAMETERS")
                .foregroundColor(DesignColor.white60)

            ForEach(EffectParameter.allCases, id: \.self) { parameter in
                DesignSliderView(
                    value: binding(for: parameter),
                    range: EffectParameterValue.range,
                    step: 1,
                    label: parameter.displayName.uppercased(),
                    minimumLabel: "MIN",
                    maximumLabel: "MAX",
                    valueFormatter: { value in "\(Int(value))" }
                )
                .disabled(!viewModel.selectedEffect.supportedParameters.contains(parameter))
            }
        }
    }

    private var resetButton: some View {
        Button {
            viewModel.resetParametersToDefaults()
        } label: {
            HStack {
                Spacer()
                Text("RESET TO DEFAULTS")
                    .font(DesignTypography.body2())
                    .foregroundColor(DesignColor.white)
                Spacer()
            }
            .padding(.vertical, DesignSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                    .stroke(DesignColor.white20, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func binding(for parameter: EffectParameter) -> Binding<Double> {
        Binding(
                    get: { value(for: parameter) },
                    set: { newValue in viewModel.updateParameter(parameter, value: newValue) }
        )
    }

    private func value(for parameter: EffectParameter) -> Double {
        switch parameter {
        case .cell: return viewModel.parameters.cell.rawValue
        case .jitter: return viewModel.parameters.jitter.rawValue
        case .softy: return viewModel.parameters.softy.rawValue
        }
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
