import XCTest
@testable import AsciiCameraKit

final class EffectParametersTests: XCTestCase {
    func testClampKeepsValuesWithinRange() {
        var params = EffectParameters()
        params.update(.cell, value: 250)
        params.update(.jitter, value: -10)

        XCTAssertEqual(params.cell.rawValue, EffectParameterValue.range.upperBound)
        XCTAssertEqual(params.jitter.rawValue, EffectParameterValue.range.lowerBound)
    }

    func testSupportedParametersDifferPerEffect() {
        XCTAssertTrue(EffectType.ascii.supportedParameters.contains(.edge))
        XCTAssertFalse(EffectType.circles.supportedParameters.contains(.edge))
        XCTAssertFalse(EffectType.squares.supportedParameters.contains(.jitter))
        XCTAssertTrue(EffectType.triangles.supportedParameters.contains(.jitter))
    }

    func testDefaultValuesMatchDocumentation() {
        let params = EffectParameters()
        XCTAssertEqual(params.cell.rawValue, 40)
        XCTAssertEqual(params.jitter.rawValue, 20)
        XCTAssertEqual(params.softy.rawValue, 10)
        XCTAssertEqual(params.edge.rawValue, 30)
    }
}
