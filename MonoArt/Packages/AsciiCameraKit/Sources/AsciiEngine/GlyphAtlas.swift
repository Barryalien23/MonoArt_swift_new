import Foundation
import AsciiDomain

struct GlyphAtlas {
    static func glyphs(for effect: EffectType) -> [Character] {
        switch effect {
        case .ascii:
            return asciiCharacters
        case .shapes:
            return shapesCharacters
        case .circles:
            return circlesCharacters
        case .squares:
            return squaresCharacters
        case .triangles:
            return triangleCharacters
        case .diamonds:
            return diamondCharacters
        }
    }

    // MARK: - Character Sets

    private static let asciiCharacters: [Character] = Array(" .'`\"^,:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$")

    private static let shapesCharacters: [Character] = [
        " ", "▁", "·", "▖", "▂", "∙", "▗", "▃", "•", "▘", "▅", "▙", "▛", "█"
    ]

    private static let circlesCharacters: [Character] = [
        " ", "·", "∙", "•", "●", "⬤"
    ]

    private static let squaresCharacters: [Character] = [
        " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"
    ]

    private static let triangleCharacters: [Character] = [
        " ", "˙", "·", "▵", "△", "▴", "▲"
    ]

    private static let diamondCharacters: [Character] = [
        " ", "▖", "▗", "▘", "▝", "▚", "▞", "▙", "▛", "▜", "▟", "█"
    ]
}

