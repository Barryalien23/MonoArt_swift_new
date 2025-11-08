import Foundation

public extension EffectType {
    /// Character sequence used both for GPU atlas generation and CPU text export.
    var characterSet: [Character] {
        switch self {
        case .ascii:
            return Array(" .'`\"^,:;Il!i><~+_-?][}{1)(|\\\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$")
        case .shapes:
            return [" ", "▁", "·", "▖", "▂", "∙", "▗", "▃", "•", "▘", "▅", "▙", "▛", "█"]
        case .circles:
            return [" ", "·", "∙", "•", "●", "⬤"]
        case .squares:
            return [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        case .triangles:
            return [" ", "˙", "·", "▵", "△", "▴", "▲"]
        case .diamonds:
            return [" ", "▖", "▗", "▘", "▝", "▚", "▞", "▙", "▛", "▜", "▟", "█"]
        }
    }

    var characterString: String {
        String(characterSet)
    }
}

