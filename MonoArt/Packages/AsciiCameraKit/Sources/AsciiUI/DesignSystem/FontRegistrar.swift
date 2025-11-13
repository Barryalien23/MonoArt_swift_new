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

        let fontURLs = Self.fontResourceURLs(in: bundle)

        guard !fontURLs.isEmpty else { return }

        for url in fontURLs {
            var registrationError: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError)

            if !success, let error = registrationError?.takeRetainedValue() {
                let errorCode = CFErrorGetCode(error)
                if errorCode != CTFontManagerError.alreadyRegistered.rawValue {
                    let errorDescription = CFErrorCopyDescription(error) as String? ?? "Unknown error"
                    assertionFailure("Failed to register font at \(url.lastPathComponent): \(errorDescription) [code: \(errorCode)]")
                }
            }
        }
    }

    private static func fontResourceURLs(in bundle: Bundle) -> [URL] {
        var results: [URL] = []
        let subdirectories: [String?] = ["Fonts", nil]
        let extensions = ["ttf", "otf"]

        for subdirectory in subdirectories {
            for fileExtension in extensions {
                if let urls = bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory) {
                    results.append(contentsOf: urls)
                }
            }
        }

        return Array(Set(results))
    }
}
