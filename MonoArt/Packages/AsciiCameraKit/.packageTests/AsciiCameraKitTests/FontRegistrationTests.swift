import CoreText
import XCTest
@testable import AsciiCameraKit

final class FontRegistrationTests: XCTestCase {
    func testDesignTypographyRegistersCustomFonts() {
        DesignSystem.bootstrap()

        let expectedFontNames: Set<String> = [
            DesignTokens.FontWeight.regular.rawValue,
            DesignTokens.FontWeight.medium.rawValue,
            DesignTokens.FontWeight.semibold.rawValue,
            DesignTokens.FontWeight.bold.rawValue
        ]

        let collection = CTFontCollectionCreateFromAvailableFonts(nil)
        let descriptors = CTFontCollectionCreateMatchingFontDescriptors(collection, nil) as? [CTFontDescriptor] ?? []

        let availableNames = descriptors.reduce(into: Set<String>()) { result, descriptor in
            if let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String {
                result.insert(name)
            }
        }

        for fontName in expectedFontNames {
            XCTAssertTrue(
                availableNames.contains(fontName),
                "Expected registered font named \(fontName)"
            )
        }
    }
}

