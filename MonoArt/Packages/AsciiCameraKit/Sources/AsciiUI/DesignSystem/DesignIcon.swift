import SwiftUI
import UIKit
import PocketSVG

public enum DesignIcon: String, CaseIterable, Sendable {
    // 16pt icons
    case effectASCII = "Effect_ASCII"
    case effectCircle = "Effect_Circle"
    case effectDiamond = "Effect_Diamond"
    case effectShapes = "Effect_Shapes"
    case effectSquare = "Effect_Square"
    case effectTriangle = "Effect_Triangle"
    case settingCell = "Setting_Cell"
    case settingContrast = "Setting_Contrast"
    case settingJitter = "Setting_Jitter"
    case save = "Save"

    // 24pt icons
    case arrowBack = "Arrow_back"
    case delete = "Delete"
    case question = "Question"
    case rotateCamera = "Rotate camera"
    case upload = "Upload"

    var folder: String {
        switch self {
        case .effectASCII,
             .effectCircle,
             .effectDiamond,
             .effectShapes,
             .effectSquare,
             .effectTriangle,
             .settingCell,
             .settingContrast,
             .settingJitter,
             .save:
            return "16"
        case .arrowBack,
             .delete,
             .question,
             .rotateCamera,
             .upload:
            return "24"
        }
    }

    var suggestedPointSize: CGFloat {
        folder == "16" ? 16 : 24
    }

    var resourcePath: String {
        "Icons/\(folder)/\(rawValue).svg"
    }

    public var defaultSize: CGFloat {
        folder == "16" ? 16 : 24
        }
    }

// MARK: - SwiftUI View

public struct DesignIconView: View {
    private let icon: DesignIcon
    private let color: Color
    private let size: CGFloat?

    public init(_ icon: DesignIcon, color: Color = DesignColor.white, size: CGFloat? = nil) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    public var body: some View {
        SVGShape(icon: icon)
            .fill(color)
            .frame(width: size ?? icon.defaultSize, height: size ?? icon.defaultSize)
            .accessibilityHidden(true)
    }
}

// MARK: - Internal Helpers

private struct SVGShape: Shape {
    let icon: DesignIcon

    func path(in rect: CGRect) -> Path {
        let svgData = SVGCache.shared.paths(for: icon)
        guard let combined = svgData?.combinedPath else {
            return Path()
        }

        let bounds = combined.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            return Path(combined.cgPath)
        }

        let scale = min(rect.width / bounds.width, rect.height / bounds.height)

        var transform = CGAffineTransform.identity
        transform = transform
            .translatedBy(x: -bounds.minX, y: -bounds.minY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(
                x: rect.midX - (bounds.width * scale) / 2,
                y: rect.midY - (bounds.height * scale) / 2
            )

        guard let cgPath = combined.cgPath.copy(using: &transform) else {
            return Path(combined.cgPath)
        }

        return Path(cgPath)
    }
}

private final class SVGCache {
    static let shared = SVGCache()

    struct SVGData {
        let paths: [SVGBezierPath]
        let combinedPath: UIBezierPath
    }

    private var cache: [DesignIcon: SVGData] = [:]
    private let queue = DispatchQueue(label: "DesignIcon.SVGCache", qos: .userInitiated)

    private final class BundleToken {}

    func paths(for icon: DesignIcon) -> SVGData? {
        if let cached = cache[icon] {
            return cached
        }

        return queue.sync { () -> SVGData? in
            if let cached = cache[icon] {
                return cached
            }

            let bundle: Bundle
            #if SWIFT_PACKAGE
            bundle = .module
            #else
            bundle = Bundle(for: BundleToken.self)
            #endif

            let subdirectory = "Icons/\(icon.folder)"
            let resourceURL = bundle.url(forResource: icon.rawValue, withExtension: "svg", subdirectory: subdirectory)
                ?? bundle.url(forResource: icon.rawValue, withExtension: "svg")

            guard let url = resourceURL else {
                assertionFailure("Missing icon resource: \(icon.resourcePath)")
                return nil
            }

            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            guard !svgPaths.isEmpty else {
                assertionFailure("Icon \(icon.rawValue) produced an empty SVG path set")
                return nil
            }

            let combined = UIBezierPath()
            svgPaths.forEach { path in
                combined.append(path)
            }
            let data = SVGData(paths: svgPaths, combinedPath: combined)
            cache[icon] = data
            return data
        }
    }
}
