import AsciiDomain
import CoreGraphics
import CoreText
import Metal
import UIKit

/// Runtime-generated glyph atlas backed by an r8Unorm Metal texture.
struct GlyphAtlas {
    let texture: MTLTexture
    let gridColumns: Int
    let gridRows: Int
    let tileSize: CGSize
    let charset: [Character]

    static func make(
        device: MTLDevice,
        effect: EffectType,
        font: UIFont = .monospacedSystemFont(ofSize: 28, weight: .regular),
        tileSize: CGSize = CGSize(width: 32, height: 32),
        columns: Int = 12
    ) -> GlyphAtlas {
        let characters = effect.characterSet
        let columnCount = max(columns, 1)
        let rowCount = Int(ceil(Double(characters.count) / Double(columnCount)))

        let width = Int(tileSize.width) * columnCount
        let height = Int(tileSize.height) * rowCount

        let data = GlyphAtlas.drawAtlas(
            characters: characters,
            font: font,
            tileSize: tileSize,
            columns: columnCount,
            atlasSize: CGSize(width: CGFloat(width), height: CGFloat(height))
        )

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Unable to allocate glyph atlas texture")
        }

        data.withUnsafeBytes { buffer in
            let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                   size: MTLSize(width: width, height: height, depth: 1))
            texture.replace(region: region,
                            mipmapLevel: 0,
                            withBytes: buffer.baseAddress!,
                            bytesPerRow: width)
        }

        return GlyphAtlas(
            texture: texture,
            gridColumns: columnCount,
            gridRows: rowCount,
            tileSize: tileSize,
            charset: characters
        )
    }

    // MARK: - Drawing

    private static func drawAtlas(
        characters: [Character],
        font: UIFont,
        tileSize: CGSize,
        columns: Int,
        atlasSize: CGSize
    ) -> Data {
        let renderer = {
            () -> CGContext in
            let colorSpace = CGColorSpaceCreateDeviceGray()
            guard let context = CGContext(
                data: nil,
                width: Int(atlasSize.width),
                height: Int(atlasSize.height),
                bitsPerComponent: 8,
                bytesPerRow: Int(atlasSize.width),
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                fatalError("Unable to create glyph atlas CGContext")
            }
            return context
        }()

        let drawBlock = {
            renderer.setFillColor(CGColor(gray: 0, alpha: 1))
            renderer.fill(CGRect(origin: .zero, size: atlasSize))

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]

            UIGraphicsPushContext(renderer)
            defer { UIGraphicsPopContext() }

            for (index, character) in characters.enumerated() {
                let column = index % columns
                let row = index / columns

                var rect = CGRect(
                    x: CGFloat(column) * tileSize.width,
                    y: CGFloat(row) * tileSize.height,
                    width: tileSize.width,
                    height: tileSize.height
                )
                rect = rect.insetBy(dx: tileSize.width * 0.15, dy: tileSize.height * 0.15)

                (String(character) as NSString).draw(in: rect, withAttributes: attributes)
            }
        }

        if Thread.isMainThread {
            drawBlock()
        } else {
            DispatchQueue.main.sync(execute: drawBlock)
        }

        guard let dataPointer = renderer.data else {
            fatalError("Glyph atlas rendering had no pixel data")
        }

        let length = Int(atlasSize.width * atlasSize.height)
        let buffer = Data(bytes: dataPointer, count: length)
        return buffer
    }
}
