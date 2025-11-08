import Dispatch
import XCTest
@testable import AsciiCameraKit

final class AppViewModelTests: XCTestCase {
    func testSelectEffectAppliesDefaultsForSupportedParameters() {
        let viewModel = AppViewModel()
        viewModel.updateParameter(.cell, value: 80)
        viewModel.updateParameter(.softy, value: 5)

        viewModel.selectEffect(.squares)

        XCTAssertEqual(viewModel.selectedEffect, .squares)
        XCTAssertEqual(viewModel.parameters.cell.rawValue, 40)
        XCTAssertEqual(viewModel.parameters.edge.rawValue, 30)
        // Unsupported parameters retain their previous values.
        XCTAssertEqual(viewModel.parameters.jitter.rawValue, 20)
    }

    func testGradientControlsAffectSymbolsOnly() {
        let viewModel = AppViewModel()
        viewModel.presentColorPicker(for: .symbols)
        viewModel.setSymbolGradientEnabled(true)
        XCTAssertTrue(viewModel.isSymbolGradientEnabled)

        viewModel.updateSymbolGradientColor(at: 0, color: .preset(.cyan))
        guard case let .gradient(stopsBeforeBackgroundChange) = viewModel.palette.symbols else {
            return XCTFail("Expected gradient after enabling it")
        }

        viewModel.presentColorPicker(for: .background)
        let originalBackground = viewModel.palette.background
        viewModel.setSymbolGradientEnabled(false) // Should be ignored for background target.
        XCTAssertEqual(viewModel.palette.background, originalBackground)

        viewModel.updateSymbolGradientColor(at: 0, color: .preset(.pink))
        guard case let .gradient(stopsAfterBackgroundChange) = viewModel.palette.symbols else {
            return XCTFail("Gradient should remain active when editing background")
        }

        XCTAssertEqual(stopsBeforeBackgroundChange, stopsAfterBackgroundChange)
    }

    func testSimulateCapturePublishesSuccessBanner() {
        let viewModel = AppViewModel()
        let expectation = expectation(description: "Capture completes")

        viewModel.simulateCapture()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if viewModel.captureStatus != nil && !viewModel.isCaptureInFlight {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.5)

        guard case let .success(payload)? = viewModel.captureStatus else {
            return XCTFail("Expected success payload after capture simulation")
        }

        XCTAssertEqual(payload.message, "Saved to Photos")
    }
}
