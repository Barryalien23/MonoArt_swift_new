#if canImport(UIKit)
import UIKit
import AsciiDomain
import AsciiEngine

public protocol AsciiFrameRendering {
    func makeImage(
        from frame: AsciiFrame,
        effect: EffectType,
        palette: PaletteState,
        mirrored: Bool
    ) -> UIImage?
}

public extension AsciiFrameRendering {
    func makeImage(
        from frame: AsciiFrame,
        effect: EffectType,
        palette: PaletteState
    ) -> UIImage? {
        makeImage(from: frame, effect: effect, palette: palette, mirrored: false)
    }
}

@available(iOS 15.0, tvOS 15.0, *)
public struct AsciiFrameRenderer: AsciiFrameRendering {
    private struct RenderingConstants {
        // Target dimensions for common aspect ratios
        static let portraitSize = CGSize(width: 1080, height: 1920)   // 9:16
        static let landscapeSize = CGSize(width: 1920, height: 1080)  // 16:9
        static let baseCharWidthFactor: CGFloat = 0.6
        static let lineHeightFactor: CGFloat = 1.12
        static let minimumFontSize: CGFloat = 8
        static let maximumFontSize: CGFloat = 120
    }

    public init() {}

    public func makeImage(
        from frame: AsciiFrame,
        effect: EffectType,
        palette: PaletteState,
        mirrored: Bool = false
    ) -> UIImage? {
        guard let glyphs = frame.glyphText, frame.columns > 0, frame.rows > 0 else {
            return nil
        }

        let lines = glyphs.split(separator: "\n", omittingEmptySubsequences: false)
        let columns = max(frame.columns, 1)
        let rows = max(frame.rows, 1)

        let isLandscape = columns >= rows
        let canvasSize = isLandscape ? RenderingConstants.landscapeSize : RenderingConstants.portraitSize
        
        // Determine width factor dynamically to prevent overflow at high densities
        var widthFactor = RenderingConstants.baseCharWidthFactor - (CGFloat(columns) / 200.0) * 0.08
        widthFactor = max(0.52, widthFactor)
        if effect == .circles {
            widthFactor *= 0.92 // circles need slightly wider cells to stay round
        }

        // Calculate font size to FILL the canvas
        // Base font size derived from width (ensures horizontal fill)
        var fontSize = canvasSize.width / (CGFloat(columns) * widthFactor)
        fontSize = min(max(fontSize, RenderingConstants.minimumFontSize), RenderingConstants.maximumFontSize)

        // Derived metrics
        let lineHeight = fontSize * RenderingConstants.lineHeightFactor
        var contentWidth = fontSize * widthFactor * CGFloat(columns)
        var contentHeight = lineHeight * CGFloat(rows)

        // If height does not fill canvas, scale uniformly to cover height (may overflow width; clipping handles)
        if contentHeight < canvasSize.height {
            let scale = canvasSize.height / max(contentHeight, 1)
            fontSize *= scale
            contentHeight *= scale
            contentWidth *= scale
        }

        let offsetX = (canvasSize.width - contentWidth) / 2
        let offsetY = (canvasSize.height - contentHeight) / 2
        let cellWidth = contentWidth / CGFloat(columns)
        let cellHeight = contentHeight / CGFloat(rows)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let circleLookup: [Character: Int] = {
            guard effect == .circles else { return [:] }
            var map: [Character: Int] = [:]
            let characters = effect.characterSet
            for (index, character) in characters.enumerated() {
                map[character] = index
            }
            return map
        }()

        var image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(palette.background.uiColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Clip to canvas bounds to prevent overflow
            cgContext.clip(to: CGRect(origin: .zero, size: canvasSize))

            if effect == .circles {
                drawCircleGrid(
                    lines: lines,
                    columns: columns,
                    rows: rows,
                    offset: CGPoint(x: offsetX, y: offsetY),
                    cellSize: CGSize(width: cellWidth, height: cellHeight),
                    palette: palette,
                    lookup: circleLookup,
                    context: cgContext
                )
            } else {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .left
                paragraph.lineBreakMode = .byClipping

                for (rowIndex, line) in lines.enumerated() {
                    let color = color(forLine: rowIndex, total: rows, palette: palette)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                        .paragraphStyle: paragraph,
                        .foregroundColor: color
                    ]
                    let attributed = NSAttributedString(string: String(line), attributes: attributes)
                    let verticalInset = max((cellHeight - fontSize) / 2, 0)
                    let point = CGPoint(
                        x: offsetX,
                        y: offsetY + CGFloat(rowIndex) * cellHeight + verticalInset
                    )
                    attributed.draw(at: point)
                }
            }
        }

        if mirrored, let cgImage = image.cgImage {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
        }

        return image
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

    private func drawCircleGrid(
        lines: [Substring],
        columns: Int,
        rows: Int,
        offset: CGPoint,
        cellSize: CGSize,
        palette: PaletteState,
        lookup: [Character: Int],
        context: CGContext
    ) {
        guard !lookup.isEmpty else { return }
        let maxLevel = max(lookup.values.max() ?? 0, 1)
        let minDimension = min(cellSize.width, cellSize.height)

        context.setShouldAntialias(true)

        for (rowIndex, line) in lines.enumerated() {
            let color = color(forLine: rowIndex, total: rows, palette: palette)
            context.setFillColor(color.cgColor)

            let lineCharacters = Array(line)
            for columnIndex in 0..<columns {
                guard columnIndex < lineCharacters.count else { continue }
                let character = lineCharacters[columnIndex]
                guard let level = lookup[character], level > 0 else { continue }

                let fraction = CGFloat(level) / CGFloat(maxLevel)
                let radius = fraction * 0.5 * minDimension
                guard radius > 0 else { continue }

                let originX = offset.x + CGFloat(columnIndex) * cellSize.width
                let originY = offset.y + CGFloat(rowIndex) * cellSize.height
                let center = CGPoint(
                    x: originX + cellSize.width / 2,
                    y: originY + cellSize.height / 2
                )
                let circleRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fillEllipse(in: circleRect)
            }
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
