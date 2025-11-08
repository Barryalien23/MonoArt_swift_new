#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI
import UIKit

public struct CameraPreviewContainer: View {
    public let status: PreviewStatus
    public let frame: PreviewFrame?
    public let palette: PaletteState

    public init(status: PreviewStatus, frame: PreviewFrame?, palette: PaletteState) {
        self.status = status
        self.frame = frame
        self.palette = palette
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.background.swiftUIColor)
                .overlay(symbolOverlay)
                .animation(.easeInOut(duration: 0.25), value: palette.background)
                .accessibilityLabel("Camera preview")

            statusOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            if let effect = frame?.renderedEffect {
                Text(effect.displayTitle)
                    .font(.caption.bold())
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
                    .accessibilityLabel("Effect \(effect.displayTitle)")
            }
        }
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch status {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("Loading preview…")
                .progressViewStyle(.circular)
                .foregroundStyle(.white)
        case .running:
            EmptyView()
        case .failed(let failure):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text(failure.message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding()
        }
    }

    @ViewBuilder
    private var symbolOverlay: some View {
        if status == .running, let frame, !frame.glyphText.isEmpty {
            GeometryReader { proxy in
                let layout = AsciiPreviewLayout(frame: frame, size: proxy.size)
                VStack(spacing: layout.lineSpacing) {
                    ForEach(Array(layout.lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(layout.font)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(lineColor(for: index, total: layout.lines.count))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(layout.accessibilityText)
            }
            .padding(24)
            .transition(.opacity)
        } else {
            EmptyView()
        }
    }

    private func lineColor(for index: Int, total: Int) -> Color {
        switch palette.symbols {
        case .solid(let descriptor):
            return descriptor.swiftUIColor
        case .gradient(let stops):
            guard total > 1 else {
                return stops.first?.color.swiftUIColor ?? .white
            }
            let progress = Double(index) / Double(max(total - 1, 1))
            return gradientColor(at: progress, stops: stops)
        }
    }

    private func gradientColor(at position: Double, stops: [GradientStop]) -> Color {
        guard var lower = stops.first else { return .white }
        guard var upper = stops.last else { return lower.color.swiftUIColor }

        let clamped = max(0, min(1, position))

        for stop in stops {
            if stop.position <= clamped { lower = stop }
            if stop.position >= clamped { upper = stop; break }
        }

        if lower.position == upper.position {
            return lower.color.swiftUIColor
        }

        let fraction = (clamped - lower.position) / (upper.position - lower.position)
        return blendedColor(from: lower.color, to: upper.color, fraction: fraction)
    }

    private func blendedColor(from start: ColorDescriptor, to end: ColorDescriptor, fraction: Double) -> Color {
        let clamped = max(0, min(1, fraction))
        let red = start.red + (end.red - start.red) * clamped
        let green = start.green + (end.green - start.green) * clamped
        let blue = start.blue + (end.blue - start.blue) * clamped
        let alpha = start.alpha + (end.alpha - start.alpha) * clamped
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

private extension EffectType {
    var displayTitle: String {
        rawValue.capitalized
    }
}

private struct AsciiPreviewLayout {
    let lines: [String]
    let font: Font
    let lineSpacing: CGFloat
    let accessibilityText: String

    private static let charWidthFactor: CGFloat = 0.55
    private static let lineHeightFactor: CGFloat = 1.1
    private static let minimumFontSize: CGFloat = 8
    private static let maximumFontSize: CGFloat = 36

    init(frame: PreviewFrame, size: CGSize) {
        lines = frame.glyphText.components(separatedBy: "\n")
        accessibilityText = frame.glyphText

        let columns = max(frame.columns, 1)
        let rows = max(frame.rows, 1)
        let availableWidth = max(size.width - 48, 1)
        let availableHeight = max(size.height - 48, 1)

        let widthDerivedFont = availableWidth / (CGFloat(columns) * Self.charWidthFactor)
        let heightDerivedFont = availableHeight / (CGFloat(rows) * Self.lineHeightFactor)
        let unclampedFont = min(widthDerivedFont, heightDerivedFont)
        let baseFontSize = max(Self.minimumFontSize, min(Self.maximumFontSize, unclampedFont))

        let baseFont = UIFont.monospacedSystemFont(ofSize: baseFontSize, weight: .medium)
        let scaledFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
        font = Font(scaledFont)

        let lineHeight = scaledFont.pointSize * Self.lineHeightFactor
        lineSpacing = max(lineHeight - scaledFont.pointSize, 0)
    }
}
#endif

