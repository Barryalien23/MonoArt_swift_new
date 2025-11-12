#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 16.0, *)
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
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                    layerSelector
                    presetsGrid
                    gradientEditor
                }
                .padding(DesignSpacing.xl)
            }
            .background(DesignColor.mainGrey.ignoresSafeArea())
            .navigationTitle("Colors")
            .toolbar { doneToolbarItem }
        }
        .onChange(of: viewModel.selectedColorTarget) { newValue in
            if newValue == .background {
                selectedGradientIndex = 0
            }
        }
    }

    private var layerSelector: some View {
        DesignSegmentedControl(
            options: ColorTarget.allCases,
            selection: Binding(
                get: { viewModel.selectedColorTarget },
                set: { target in viewModel.selectColorTarget(target) }
            ),
            spacing: DesignSpacing.md,
            showsBackground: true,
            configuration: { target in
                DesignSegmentButton.Configuration(
                    title: target == .background ? "BG COLOR" : "SYMBOLS"
                )
            }
        )
    }

    private var presetsGrid: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            DesignTokens.Typography.body2.text("PRESETS")
                .foregroundColor(DesignColor.white60)

            LazyVGrid(columns: presetColumns, spacing: DesignSpacing.lg) {
                ForEach(ColorDescriptor.Preset.allCases, id: \.self, content: presetButton(preset:))
            }

            ColorPicker("Custom Color", selection: activeColorBinding, supportsOpacity: false)
                .labelsHidden()
                .scaleEffect(x: 1, y: 1, anchor: .leading)
        }
    }

    private var gradientEditor: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            Toggle(isOn: gradientEnabledBinding) {
                DesignTokens.Typography.body2.text("SYMBOL GRADIENT")
                    .foregroundColor(DesignColor.white)
            }
            .toggleStyle(.switch)
            .disabled(!viewModel.isGradientEditingEnabled)
            .tint(.orange)

            if viewModel.isSymbolGradientEnabled {
                gradientStopSelector
                selectedGradientControls
                gradientActions
            }
        }
        .padding(DesignSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                .fill(DesignColor.greyActive)
        )
    }

    private var gradientStopSelector: some View {
        Picker("Editing Stop", selection: $selectedGradientIndex) {
            ForEach(Array(viewModel.symbolGradientStops.enumerated()), id: \.offset) { index, stop in
                Text("Stop \(index + 1) – \(formattedPercentage(stop.position))")
                    .tag(index)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.symbolGradientStops.count) { count in
            selectedGradientIndex = min(selectedGradientIndex, max(count - 1, 0))
        }
    }

    private var selectedGradientControls: some View {
        ForEach(Array(viewModel.symbolGradientStops.enumerated()), id: \.offset) { index, stop in
            if index == selectedGradientIndex {
                VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                    DesignTokens.Typography.body2.text("Gradient Stop \(index + 1)")
                        .foregroundColor(DesignColor.white)

                    DesignSliderView(
                        value: Binding(
                            get: { viewModel.symbolGradientStops[index].position },
                            set: { newValue in viewModel.updateSymbolGradientPosition(at: index, position: newValue) }
                        ),
                        range: 0...1,
                        step: 0.01,
                        label: "POSITION",
                        minimumLabel: "START",
                        maximumLabel: "END",
                        valueFormatter: { formattedPercentage($0) }
                    )
                }
            }
        }
    }

    private var gradientActions: some View {
        HStack(spacing: DesignSpacing.lg) {
            Button("Add Stop", action: viewModel.addSymbolGradientStop)
                .disabled(viewModel.symbolGradientStops.count >= 4)
            Button("Remove Stop") {
                viewModel.removeSymbolGradientStop(at: selectedGradientIndex)
                selectedGradientIndex = max(0, selectedGradientIndex - 1)
            }
            .disabled(viewModel.symbolGradientStops.count <= 2)
        }
        .font(DesignTokens.Typography.body1.font())
        .foregroundColor(DesignColor.white)
    }

    private var doneToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { viewModel.dismissColorPicker() }
                .font(DesignTokens.Typography.body2.font())
        }
    }

    private var gradientEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isSymbolGradientEnabled },
            set: { newValue in viewModel.setSymbolGradientEnabled(newValue) }
        )
    }

    private var presetColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DesignSpacing.lg), count: 4)
    }

    private func presetButton(preset: ColorDescriptor.Preset) -> some View {
        let descriptor = ColorDescriptor.preset(preset)

        return Button(action: { handlePresetTap(descriptor) }) {
            Circle()
                .fill(descriptor.swiftUIColor)
                .frame(width: 48, height: 48)
                .overlay(selectionRing(for: descriptor))
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
                .accessibilityLabel("Select \(preset.rawValue.capitalized) color")
        }
        .buttonStyle(.plain)
    }

    private func selectionRing(for descriptor: ColorDescriptor) -> some View {
        Circle()
            .stroke(currentSelectionEquals(descriptor) ? Color.white : Color.white.opacity(0.2), lineWidth: 3)
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
        updateActiveColor(descriptor)
    }

    private func formattedPercentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    private var activeColorBinding: Binding<Color> {
        Binding(
            get: { activeColorDescriptor.swiftUIColor },
            set: { newValue in updateActiveColor(descriptor(from: newValue)) }
        )
    }

    private var activeColorDescriptor: ColorDescriptor {
        if viewModel.isGradientEditingEnabled && viewModel.isSymbolGradientEnabled {
            let stops = viewModel.symbolGradientStops
            guard stops.indices.contains(selectedGradientIndex) else {
                return ColorDescriptor.preset(.white)
            }
            return stops[selectedGradientIndex].color
        } else {
            switch viewModel.selectedColorTarget {
            case .background:
                return viewModel.palette.background
            case .symbols:
                if case let .solid(color) = viewModel.palette.symbols {
                    return color
                }
                if case let .gradient(stops) = viewModel.palette.symbols, let first = stops.first {
                    return first.color
                }
                return ColorDescriptor.preset(.white)
            }
        }
    }

    private func updateActiveColor(_ descriptor: ColorDescriptor) {
        if viewModel.isGradientEditingEnabled && viewModel.isSymbolGradientEnabled {
            viewModel.updateSymbolGradientColor(at: selectedGradientIndex, color: descriptor)
        } else {
            viewModel.setSolidColor(descriptor)
        }
    }

    private func descriptor(from color: Color) -> ColorDescriptor {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorDescriptor(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
        #else
        return ColorDescriptor.preset(.white)
        #endif
    }
}
#endif
