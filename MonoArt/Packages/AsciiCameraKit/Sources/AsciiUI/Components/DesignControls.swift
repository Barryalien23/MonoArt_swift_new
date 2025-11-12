import SwiftUI
import AsciiDomain

public struct DesignSegmentButton: View {
    public struct Configuration: Hashable {
        public let title: String
        public let icon: DesignIcon?

        public init(title: String, icon: DesignIcon? = nil) {
            self.title = title
            self.icon = icon
        }
    }

    private let configuration: Configuration
    private let isSelected: Bool
    private let action: () -> Void

    public init(configuration: Configuration, isSelected: Bool, action: @escaping () -> Void) {
        self.configuration = configuration
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.sm) {
                if let icon = configuration.icon {
                    DesignIconView(icon,
                                   color: isSelected ? DesignColor.white : DesignColor.white40,
                                   size: 16)
                }

                DesignTokens.Typography.body2.text(configuration.title)
                    .foregroundColor(isSelected ? DesignColor.white : DesignColor.white40)
            }
            .padding(.vertical, DesignSpacing.sm)
            .padding(.horizontal, DesignSpacing.lg)
            .background(background)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(configuration.title)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
            .fill(isSelected ? DesignColor.greyActive : DesignColor.greyDisable)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                    .stroke(isSelected ? DesignColor.white20 : Color.clear, lineWidth: 1)
            )
    }
}


public struct DesignSegmentedControl<Option: Hashable>: View {
    private let options: [Option]
    @Binding private var selection: Option
    private let configuration: (Option) -> DesignSegmentButton.Configuration
    private let spacing: CGFloat
    private let showsBackground: Bool

    public init(
        options: [Option],
        selection: Binding<Option>,
        spacing: CGFloat = DesignSpacing.sm,
        showsBackground: Bool = true,
        configuration: @escaping (Option) -> DesignSegmentButton.Configuration
    ) {
        self.options = options
        self._selection = selection
        self.configuration = configuration
        self.spacing = spacing
        self.showsBackground = showsBackground
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(options, id: \.self) { option in
                    let config = configuration(option)
                    DesignSegmentButton(
                        configuration: config,
                        isSelected: option == selection
                    ) {
                        withAnimation(.spring(duration: 0.25)) {
                            selection = option
                        }
                    }
                }
            }
            .padding(.vertical, DesignSpacing.sm)
            .padding(.horizontal, showsBackground ? DesignSpacing.sm : 0)
        }
        .background(backgroundView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if showsBackground {
            RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                .fill(DesignColor.greyDisable.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

public struct DesignEffectCard: View {
    private let title: String
    private let preview: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, preview: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.preview = preview
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.sm) {
                DesignTokens.Typography.body1.text(preview)
                    .foregroundColor(DesignColor.white60)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                DesignTokens.Typography.head1.text(title)
                    .foregroundColor(DesignColor.white)
            }
            .padding(DesignSpacing.lg)
            .frame(width: 64, height: 120)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
            .fill(isSelected ? DesignColor.greyActive : DesignColor.greyDisable)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                    .stroke(isSelected ? DesignColor.white20 : Color.clear, lineWidth: 1)
            )
    }
}

public struct DesignSliderView: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let label: String
    private let minimumLabel: String?
    private let maximumLabel: String?
    private let valueFormatter: (Double) -> String
    private let onEditingChanged: (Bool) -> Void

    @State private var isDragging = false

    private let knobSize: CGFloat = 40

    public init(
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...100,
        step: Double = 1,
        label: String,
        minimumLabel: String? = nil,
        maximumLabel: String? = nil,
        valueFormatter: @escaping (Double) -> String = { Int($0).description },
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.minimumLabel = minimumLabel
        self.maximumLabel = maximumLabel
        self.valueFormatter = valueFormatter
        self.onEditingChanged = onEditingChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            header

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    trackBackground

                    progressFill(width: fillWidth(totalWidth: proxy.size.width))

                    knob
                        .offset(x: knobOffset(totalWidth: proxy.size.width))
                        .gesture(dragGesture(totalWidth: proxy.size.width))
                }
            }
            .frame(height: knobSize)

            if minimumLabel != nil || maximumLabel != nil {
                HStack {
                    DesignTokens.Typography.body2.text(minimumLabel ?? "")
                        .foregroundColor(DesignColor.white40)
                    Spacer()
                    DesignTokens.Typography.body2.text(maximumLabel ?? "")
                        .foregroundColor(DesignColor.white40)
                }
            }
        }
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                .fill(DesignColor.greyActive)
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
        )
    }

    private var header: some View {
        HStack {
            DesignTokens.Typography.body2.text(label)
                .foregroundColor(DesignColor.white60)
            Spacer()
            DesignTokens.Typography.body2.text(valueFormatter(value))
                .foregroundColor(DesignColor.white)
        }
    }

    private var trackBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
            .fill(DesignColor.greyDisable)
    }

    private func progressFill(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
            .fill(isDragging ? DesignColor.white60 : DesignColor.white40)
            .frame(width: width)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    private func fillWidth(totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let clamped = min(max(progress, 0), 1)
        return max(DesignSpacing.base, totalWidth * clamped)
    }

    private func knobOffset(totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let clamped = min(max(progress, 0), 1)
        return (totalWidth - knobSize) * clamped
    }

    private var knob: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .stroke(DesignColor.white, lineWidth: isDragging ? 4 : 3)
            .frame(width: knobSize, height: knobSize)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(Color.clear)
            )
            .shadow(color: DesignColor.black.opacity(0.2), radius: isDragging ? 12 : 0, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    private func dragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    isDragging = true
                    onEditingChanged(true)
                }
                let clampedX = min(max(gesture.location.x, 0), totalWidth)
                let progress = Double(clampedX / totalWidth)
                let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * progress
                let stepped = (rawValue / step).rounded() * step
                value = min(max(range.lowerBound, stepped), range.upperBound)
            }
            .onEnded { _ in
                isDragging = false
                onEditingChanged(false)
            }
    }
}

public struct DesignColorTab: View {
    public enum Indicator {
        case solid(Color)
        case gradient(Gradient)
    }

    private let title: String
    private let indicator: Indicator
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, indicator: Indicator, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.indicator = indicator
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.sm) {
                indicatorView
                DesignTokens.Typography.body2.text(title)
                    .foregroundColor(isSelected ? DesignColor.white : DesignColor.white40)
            }
            .padding(.vertical, DesignSpacing.sm)
            .padding(.horizontal, DesignSpacing.lg)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: DesignRadius.sm, style: .continuous)
            .fill(isSelected ? DesignColor.greyActive : DesignColor.greyDisable)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.sm, style: .continuous)
                    .stroke(isSelected ? DesignColor.white : Color.clear, lineWidth: isSelected ? 1 : 0)
            )
    }

    private var indicatorView: some View {
        Circle()
            .strokeBorder(DesignColor.white, lineWidth: 1)
            .background(indicatorFill)
            .frame(width: 16, height: 16)
            .opacity(isSelected ? 1 : 0.4)
    }

    @ViewBuilder
    private var indicatorFill: some View {
        switch indicator {
        case .solid(let color):
            Circle().fill(color)
        case .gradient(let gradient):
            Circle().fill(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
        }
    }
}

public struct DesignColorChip: View {
    public enum Preview {
        case solid(Color)
        case gradient(Gradient)
    }

    private let title: String
    private let subtitle: String?
    private let preview: Preview
    private let isSelected: Bool
    private let width: CGFloat
    private let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        preview: Preview,
        isSelected: Bool,
        width: CGFloat = 148,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.preview = preview
        self.isSelected = isSelected
        self.width = width
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                previewView
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                            .stroke(isSelected ? DesignColor.white : Color.clear, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                    DesignTokens.Typography.body2.text(title)
                        .foregroundColor(DesignColor.white)
                    if let subtitle {
                        DesignTokens.Typography.body1.text(subtitle)
                            .foregroundColor(DesignColor.white40)
                    }
                }
            }
            .padding(DesignSpacing.md)
            .frame(width: width, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                    .fill(isSelected ? DesignColor.greyActive : DesignColor.greyDisable)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                            .stroke(isSelected ? DesignColor.white20 : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
    }

    @ViewBuilder
    private var previewView: some View {
        switch preview {
        case .solid(let color):
            RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                .fill(color)
        case .gradient(let gradient):
            RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                .fill(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
        }
    }
}

#if DEBUG
private struct DesignControlsPreviewBootstrapper {
    static func prepare() {
        DesignSystem.bootstrap()
    }
}

private struct SegmentedControlPreview: View {
    @State private var selection: Int = 1

    init() {
        DesignControlsPreviewBootstrapper.prepare()
    }

    var body: some View {
        DesignSegmentedControl(
            options: Array(0..<4),
            selection: $selection,
            configuration: { index in
                DesignSegmentButton.Configuration(
                    title: ["ASCII", "Squares", "Shapes", "Circles"][index],
                    icon: [.effectASCII, .effectSquare, .effectShapes, .effectCircle][index]
                )
            }
        )
        .padding()
        .background(DesignColor.mainGrey.ignoresSafeArea())
    }
}

private struct SliderPreview: View {
    @State private var value: Double = 36

    init() {
        DesignControlsPreviewBootstrapper.prepare()
    }

    var body: some View {
        DesignSliderView(
            value: $value,
            range: 0...100,
            step: 1,
            label: "CELL SIZE",
            minimumLabel: "SMALL",
            maximumLabel: "LARGE"
        )
        .padding()
        .background(DesignColor.mainGrey.ignoresSafeArea())
    }
}

private struct ColorChipPreview: View {
    init() {
        DesignControlsPreviewBootstrapper.prepare()
    }

    var body: some View {
        HStack(spacing: DesignSpacing.lg) {
            DesignColorChip(
                title: "Background",
                preview: .solid(Color.black),
                isSelected: true,
                action: {}
            )
            DesignColorChip(
                title: "Symbols",
                subtitle: "Gradient",
                preview: .gradient(
                    Gradient(stops: [
                        .init(color: .purple, location: 0),
                        .init(color: .pink, location: 0.5),
                        .init(color: .orange, location: 1)
                    ])
                ),
                isSelected: false,
                action: {}
            )
        }
        .padding()
        .background(DesignColor.mainGrey.ignoresSafeArea())
    }
}

#Preview("Segmented Control") {
    SegmentedControlPreview()
}

#Preview("Slider View") {
    SliderPreview()
}

#Preview("Color Chip") {
    ColorChipPreview()
}
#endif
