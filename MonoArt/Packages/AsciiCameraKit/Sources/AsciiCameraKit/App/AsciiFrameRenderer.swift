#if canImport(UIKit)
import UIKit
import AsciiDomain
import AsciiEngine

public protocol AsciiFrameRendering {
    func makeImage(from frame: AsciiFrame, palette: PaletteState) -> UIImage?
}

@available(iOS 15.0, tvOS 15.0, *)
public struct AsciiFrameRenderer: AsciiFrameRendering {
    private struct RenderingConstants {
        static let targetWidth: CGFloat = 2048
        static let charWidthFactor: CGFloat = 0.6
        static let lineHeightFactor: CGFloat = 1.1
    }

    public init() {}

    public func makeImage(from frame: AsciiFrame, palette: PaletteState) -> UIImage? {
        guard let glyphs = frame.glyphText, frame.columns > 0, frame.rows > 0 else {
            return nil
        }

        let lines = glyphs.split(separator: "\n", omittingEmptySubsequences: false)
        let columns = max(frame.columns, 1)
        let rows = max(frame.rows, 1)

        let fontSize = RenderingConstants.targetWidth / CGFloat(columns) / RenderingConstants.charWidthFactor
        let lineHeight = fontSize * RenderingConstants.lineHeightFactor
        let canvasSize = CGSize(width: RenderingConstants.targetWidth, height: lineHeight * CGFloat(rows))

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(palette.background.uiColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            paragraph.lineBreakMode = .byClipping

            for (index, line) in lines.enumerated() {
                let color = color(forLine: index, total: rows, palette: palette)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                    .paragraphStyle: paragraph,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: String(line), attributes: attributes)
                let point = CGPoint(x: 0, y: CGFloat(index) * lineHeight)
                attributed.draw(at: point)
            }
        }
    }

    private func color(forLine index: Int, total: Int, palette: PaletteState) -> UIColor {
        switch palette.symbols {
        case .solid(let descriptor):
            return descriptor.uiColor
        case .gradient(let stops):
            guard total > 1 else { return stops.first?.color.uiColor ?? UIColor.white }
            let position = CGFloat(index) / CGFloat(total - 1)
            let start = stops.first?.color.uiColor ?? UIColor.white
            let end = stops.last?.color.uiColor ?? UIColor.white
            return start.interpolate(to: end, progress: position)
        }
    }
}

private extension ColorDescriptor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private extension UIColor {
    func interpolate(to color: UIColor, progress: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let r = r1 + (r2 - r1) * progress
        let g = g1 + (g2 - g1) * progress
        let b = b1 + (b2 - b1) * progress
        let a = a1 + (a2 - a1) * progress
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
#endif
