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
        // Target dimensions for portrait 9:16 aspect ratio
        static let targetWidth: CGFloat = 1080  // Standard portrait width
        static let targetHeight: CGFloat = 1920 // Standard portrait height (9:16)
        static let baseCharWidthFactor: CGFloat = 0.65
        static let lineHeightFactor: CGFloat = 1.2
    }

    public init() {}

    public func makeImage(from frame: AsciiFrame, palette: PaletteState) -> UIImage? {
        guard let glyphs = frame.glyphText, frame.columns > 0, frame.rows > 0 else {
            return nil
        }

        let lines = glyphs.split(separator: "\n", omittingEmptySubsequences: false)
        let columns = max(frame.columns, 1)
        let rows = max(frame.rows, 1)

        // Always use fixed target dimensions (1080×1920) for consistent output
        let canvasSize = CGSize(width: RenderingConstants.targetWidth, height: RenderingConstants.targetHeight)
        
        // Determine width factor dynamically to prevent overflow at high densities
        let widthFactor: CGFloat
        if columns > 150 {
            widthFactor = 0.75
        } else if columns > 100 {
            widthFactor = 0.70
        } else {
            widthFactor = RenderingConstants.baseCharWidthFactor
        }

        // Calculate font size to FILL the canvas (use max to ensure full coverage)
        let fontSizeForWidth = RenderingConstants.targetWidth / CGFloat(columns) / widthFactor
        let fontSizeForHeight = RenderingConstants.targetHeight / CGFloat(rows) / RenderingConstants.lineHeightFactor
        let fontSize = max(fontSizeForWidth, fontSizeForHeight) // Use LARGER to fill the entire canvas
        
        let lineHeight = fontSize * RenderingConstants.lineHeightFactor
        let contentWidth = fontSize * widthFactor * CGFloat(columns)
        let contentHeight = lineHeight * CGFloat(rows)
        
        // Center content (may overflow canvas slightly, but that's okay - it fills the screen)
        let offsetX = (RenderingConstants.targetWidth - contentWidth) / 2
        let offsetY = (RenderingConstants.targetHeight - contentHeight) / 2

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(palette.background.uiColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Clip to canvas bounds to prevent overflow
            cgContext.clip(to: CGRect(origin: .zero, size: canvasSize))

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
                // Apply offset to center content in canvas
                let point = CGPoint(x: offsetX, y: offsetY + CGFloat(index) * lineHeight)
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
