#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

public struct ColorPickerSheet: View {
    @ObservedObject private var viewModel: AppViewModel
    @State private var selectedGradientIndex: Int = 0

    public init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        if case .gradient(let stops) = viewModel.palette.symbols {
            _selectedGradientIndex = State(initialValue: min(1, stops.count - 1))
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Layer") {
                    Picker("Layer", selection: Binding(
                        get: { viewModel.selectedColorTarget },
                        set: { target in viewModel.selectColorTarget(target) }
                    )) {
                        Text("Background").tag(ColorTarget.background)
                        Text("Symbols").tag(ColorTarget.symbols)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Presets") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(ColorDescriptor.Preset.allCases, id: \.self) { preset in
                            let descriptor = ColorDescriptor.preset(preset)
                            Button(action: { handlePresetTap(descriptor) }) {
                                Circle()
                                    .fill(descriptor.swiftUIColor)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(currentSelectionEquals(descriptor) ? Color.white : Color.white.opacity(0.2), lineWidth: 3)
                                    )
                                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Select \(preset.rawValue.capitalized) color")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Gradient") {
                    Toggle(isOn: Binding(
                        get: { viewModel.isSymbolGradientEnabled },
                        set: { newValue in viewModel.setSymbolGradientEnabled(newValue) }
                    )) {
                        Text("Enable Symbol Gradient")
                    }
                    .disabled(!viewModel.isGradientEditingEnabled)
                    .accessibilityHint("Gradients apply only to symbol glyphs as documented in Android specs")

                    if viewModel.isSymbolGradientEnabled {
                        Picker("Editing Stop", selection: $selectedGradientIndex) {
                            ForEach(Array(viewModel.symbolGradientStops.enumerated()), id: \.offset) { index, stop in
                                Text("Stop \(index + 1) – \(formattedPercentage(stop.position))")
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.symbolGradientStops.count) { _, count in
                            selectedGradientIndex = min(selectedGradientIndex, max(count - 1, 0))
                        }

                        ForEach(Array(viewModel.symbolGradientStops.enumerated()), id: \.offset) { index, stop in
                            if index == selectedGradientIndex {
                                gradientStopEditor(index: index, stop: stop)
                            }
                        }

                        HStack {
                            Button("Add Stop") {
                                viewModel.addSymbolGradientStop()
                            }
                            .disabled(viewModel.symbolGradientStops.count >= 4)

                            Button("Remove Stop") {
                                viewModel.removeSymbolGradientStop(at: selectedGradientIndex)
                                selectedGradientIndex = max(0, selectedGradientIndex - 1)
                            }
                            .disabled(viewModel.symbolGradientStops.count <= 2)
                        }
                    }
                }
            }
            .navigationTitle("Colors")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.dismissColorPicker() }
                }
            }
        }
        .onChange(of: viewModel.selectedColorTarget) { _, newValue in
            if newValue == .background {
                selectedGradientIndex = 0
            }
        }
    }

    private func currentSelectionEquals(_ descriptor: ColorDescriptor) -> Bool {
        switch viewModel.selectedColorTarget {
        case .background:
            return viewModel.palette.background == descriptor
        case .symbols:
            if case let .solid(color) = viewModel.palette.symbols {
                return color == descriptor
            }
            return false
        }
    }

    private func handlePresetTap(_ descriptor: ColorDescriptor) {
        if viewModel.isGradientEditingEnabled && viewModel.isSymbolGradientEnabled {
            viewModel.updateSymbolGradientColor(at: selectedGradientIndex, color: descriptor)
        } else {
            viewModel.setSolidColor(descriptor)
        }
    }

    private func gradientStopEditor(index: Int, stop: GradientStop) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gradient Stop \(index + 1)")
                .font(.headline)
            Slider(value: Binding(
                get: { stop.position },
                set: { newValue in viewModel.updateSymbolGradientPosition(at: index, position: newValue) }
            ), in: 0 ... 1) {
                Text("Position")
            }
            Text("Position: \(formattedPercentage(stop.position))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedPercentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}
#endif

