import Foundation
import CoreText

enum FontRegistrar {
    private final class BundleToken {}

    static func registerFonts() {
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = .module
        #else
        bundle = Bundle(for: BundleToken.self)
        #endif

        guard let urls = bundle.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else {
            return
        }

        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
