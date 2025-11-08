#if canImport(AVFoundation) && canImport(XCTest) && !os(iOS)
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import XCTest
@testable import AsciiCameraKit
import AsciiDomain
import AsciiEngine
import AsciiCamera

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
final class PreviewPipelineTests: XCTestCase {
    func testPipelineUpdatesViewModelWhenFrameArrives() async throws {
        let viewModel = AppViewModel()
        let engine = MockEngine()
        let camera = MockCameraService()
        let pipeline = PreviewPipeline(viewModel: viewModel, engine: engine, cameraService: camera)

        let expectation = expectation(description: "Preview updates")
        let cancellable = viewModel.$previewFrame
            .dropFirst()
            .sink { frame in
                if frame != nil {
                    expectation.fulfill()
                }
            }

        pipeline.start()

        let pixelBuffer = try makeGradientPixelBuffer(width: 80, height: 60)
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        camera.emit(envelope)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(engine.renderPreviewCallCount, 1)
        cancellable.cancel()
        pipeline.stop()
    }

    func testPipelineStopsCameraOnStop() async throws {
        let viewModel = AppViewModel()
        let engine = MockEngine()
        let camera = MockCameraService()
        let pipeline = PreviewPipeline(viewModel: viewModel, engine: engine, cameraService: camera)

        pipeline.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        pipeline.stop()

        XCTAssertTrue(camera.didStop)
    }

    func testParameterChangeTriggersReRender() async throws {
        let viewModel = AppViewModel()
        let engine = MockEngine()
        let camera = MockCameraService()
        let pipeline = PreviewPipeline(viewModel: viewModel, engine: engine, cameraService: camera)

        pipeline.start()
        let pixelBuffer = try makeGradientPixelBuffer(width: 80, height: 60)
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        camera.emit(envelope)

        try await Task.sleep(nanoseconds: 50_000_000)
        let initialRenderCount = engine.renderPreviewCallCount

        viewModel.updateParameter(.cell, value: 60)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertGreaterThan(engine.renderPreviewCallCount, initialRenderCount)
        pipeline.stop()
    }
}

// MARK: - Mocks

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
private final class MockEngine: AsciiEngineProtocol {
    private(set) var prepareCalled = false
    private(set) var renderPreviewCallCount = 0
    private(set) var renderCaptureCallCount = 0

    func prepare(configuration: EngineConfiguration) throws {
        prepareCalled = true
    }

    func renderPreview(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        renderPreviewCallCount += 1
        return AsciiFrame(texture: nil, glyphText: "AB\nCD", columns: 2, rows: 2)
    }

    func renderCapture(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        renderCaptureCallCount += 1
        return AsciiFrame(texture: nil, glyphText: "EF\nGH", columns: 2, rows: 2)
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
private final class MockCameraService: CameraServiceProtocol {
    private let subject = PassthroughSubject<FrameEnvelope, Never>()
    private(set) var didStart = false
    private(set) var didStop = false
    private(set) var switchCount = 0

    var framePublisher: AnyPublisher<FrameEnvelope, Never> {
        subject.eraseToAnyPublisher()
    }

    var authorizationStatus: AVAuthorizationStatus {
        .authorized
    }

    func startSession() async throws {
        didStart = true
    }

    func stopSession() {
        didStop = true
    }

    func switchCamera() async throws {
        switchCount += 1
    }

    func emit(_ envelope: FrameEnvelope) {
        subject.send(envelope)
    }
}

#if canImport(UIKit)
@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
private final class MockRenderer: AsciiFrameRendering {
    func makeImage(from frame: AsciiFrame, palette: PaletteState) -> UIImage? {
        UIImage()
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
private final class MockMediaCoordinator: MediaCoordinatorProtocol {
    private(set) var savedImages: [UIImage] = []

    func save(image: UIImage) async throws {
        savedImages.append(image)
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
extension PreviewPipelineTests {
    func testCaptureUsesEngineAndMediaCoordinator() async throws {
        let viewModel = AppViewModel()
        let engine = MockEngine()
        let camera = MockCameraService()
        let renderer = MockRenderer()
        let media = MockMediaCoordinator()
        let pipeline = PreviewPipeline(
            viewModel: viewModel,
            engine: engine,
            cameraService: camera,
            configuration: EngineConfiguration(maxPreviewCells: 4_000, maxCaptureCells: 8_000),
            frameRenderer: renderer,
            mediaCoordinator: media
        )

        pipeline.start()
        let pixelBuffer = try makeGradientPixelBuffer(width: 80, height: 60)
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        camera.emit(envelope)

        try await Task.sleep(nanoseconds: 50_000_000)
        pipeline.capture()

        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(engine.renderCaptureCallCount, 1)
        XCTAssertEqual(media.savedImages.count, 1)
        XCTAssertEqual(viewModel.captureStatus, .success(message: "Saved to Photos"))
        pipeline.stop()
    }

    func testCaptureInvokesOnCaptureSuccessCallback() async throws {
        let viewModel = AppViewModel()
        let engine = MockEngine()
        let camera = MockCameraService()
        let renderer = MockRenderer()
        let media = MockMediaCoordinator()
        let pipeline = PreviewPipeline(
            viewModel: viewModel,
            engine: engine,
            cameraService: camera,
            configuration: EngineConfiguration(maxPreviewCells: 4_000, maxCaptureCells: 8_000),
            frameRenderer: renderer,
            mediaCoordinator: media
        )

        let expectation = expectation(description: "Capture success callback")
        pipeline.onCaptureSuccess = { _ in
            expectation.fulfill()
        }

        pipeline.start()
        let pixelBuffer = try makeGradientPixelBuffer(width: 80, height: 60)
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        camera.emit(envelope)

        try await Task.sleep(nanoseconds: 50_000_000)
        pipeline.capture()

        await fulfillment(of: [expectation], timeout: 1.0)
        pipeline.stop()
    }
}
#endif

#endif
