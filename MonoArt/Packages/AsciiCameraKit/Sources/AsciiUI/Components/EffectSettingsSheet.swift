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
            Form {
                Section("Effect") {
                    Picker("Effect", selection: Binding(
                        get: { viewModel.selectedEffect },
                        set: { effect in viewModel.selectEffect(effect) }
                    )) {
                        ForEach(EffectType.allCases, id: \.self) { effect in
                            Text(effect.displayTitle).tag(effect)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Parameters") {
                    ForEach(EffectParameter.allCases, id: \.self) { parameter in
                        parameterRow(for: parameter)
                            .disabled(!viewModel.selectedEffect.supportedParameters.contains(parameter))
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        viewModel.resetParametersToDefaults()
                    }
                }
            }
            .navigationTitle("Effect Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.dismissSettingsSheet() }
                }
            }
        }
    }

    private func parameterRow(for parameter: EffectParameter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(parameter.displayName)
                    .font(.headline)
                Spacer()
                Text(valueLabel(for: parameter))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Current value: \(valueLabel(for: parameter))")
            }

            Slider(
                value: Binding(
                    get: { value(for: parameter) },
                    set: { newValue in viewModel.updateParameter(parameter, value: newValue) }
                ),
                in: EffectParameterValue.range
            ) {
                Text(parameter.displayName)
            }
            .accessibilityValue(valueLabel(for: parameter))
        }
        .padding(.vertical, 4)
    }

    private func value(for parameter: EffectParameter) -> Double {
        switch parameter {
        case .cell: return viewModel.parameters.cell.rawValue
        case .jitter: return viewModel.parameters.jitter.rawValue
        case .softy: return viewModel.parameters.softy.rawValue
        }
    }

    private func valueLabel(for parameter: EffectParameter) -> String {
        String(Int(round(value(for: parameter))))
    }
}

private extension EffectType {
    var displayTitle: String {
        rawValue.capitalized
    }
}
#endif

