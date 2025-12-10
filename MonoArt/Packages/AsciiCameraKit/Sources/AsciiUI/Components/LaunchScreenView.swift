import SwiftUI
import UIKit

public struct LaunchScreenView: View {
    public init() {}

    public var body: some View {
        ZStack {
            // Gradient background
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    EllipticalGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.06, green: 0.06, blue: 0.06), location: 0.00),
                            Gradient.Stop(color: .black, location: 1.00),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.51)
                    )
                )
                .ignoresSafeArea()

            // Centered ASCII pattern
            if let patternImage = UIImage.loadLaunchAsset(named: "Ascii pattern", extension: "png") {
                Image(uiImage: patternImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.4)
            }

            // Centered logo
            if let logoImage = UIImage.loadLaunchAsset(named: "Logo", extension: "png") {
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .accessibilityLabel("MonoArt Logo")
            }
        }
    }
}

// MARK: - UIImage Extension

private extension UIImage {
    static func loadLaunchAsset(named: String, extension ext: String) -> UIImage? {
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = .module
        #else
        bundle = Bundle.main
        #endif

        guard let url = bundle.url(forResource: named, withExtension: ext) else {
            print("⚠️ LaunchScreen: Missing \(named).\(ext) in bundle")
            print("📦 Bundle URL: \(bundle.bundleURL)")
            print("📁 Attempting to load from resource: '\(named)' with extension: '\(ext)'")

            // Try to list available resources
            if let resourcePath = bundle.resourcePath {
                print("📂 Bundle resources:")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                    contents.filter { $0.hasSuffix(ext) }.forEach { print("  - \($0)") }
                }
            }

            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ LaunchScreen: Failed to load data from \(url)")
            return nil
        }

        return UIImage(data: data)
    }
}

#Preview {
    LaunchScreenView()
}
