import Foundation
import Combine
import AsciiDomain
import AsciiEngine
import AsciiCamera
#if canImport(UIKit)
import UIKit
#endif

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
public final class PreviewPipeline {
    private struct RenderContext {
        let effect: EffectType
        let parameters: EffectParameters
        let palette: PaletteState
    }

    private let viewModel: AppViewModel
    private let engine: AsciiEngineProtocol
    private let cameraService: CameraServiceProtocol
    private let configuration: EngineConfiguration
    private let renderQueue = DispatchQueue(label: "com.monoart.preview.render", qos: .userInitiated)
    private var latestFrame: FrameEnvelope?
#if canImport(UIKit)
    private let frameRenderer: AsciiFrameRendering
    private let mediaCoordinator: MediaCoordinatorProtocol
    private var captureTask: Task<Void, Never>?
    public var onCaptureSuccess: ((UIImage) -> Void)?
#endif

    private var frameCancellable: AnyCancellable?
    private var stateCancellable: AnyCancellable?
    private var renderTask: Task<Void, Never>?
    private var isEnginePrepared = false
    private var isRunning = false

#if canImport(UIKit)
    public init(
        viewModel: AppViewModel,
        engine: AsciiEngineProtocol,
        cameraService: CameraServiceProtocol,
        configuration: EngineConfiguration = EngineConfiguration(),
        frameRenderer: AsciiFrameRendering = AsciiFrameRenderer(),
        mediaCoordinator: MediaCoordinatorProtocol = PhotosMediaCoordinator()
    ) {
        self.viewModel = viewModel
        self.engine = engine
        self.cameraService = cameraService
        self.configuration = configuration
        self.frameRenderer = frameRenderer
        self.mediaCoordinator = mediaCoordinator
    }
#else
    public init(
        viewModel: AppViewModel,
        engine: AsciiEngineProtocol,
        cameraService: CameraServiceProtocol,
        configuration: EngineConfiguration = EngineConfiguration()
    ) {
        self.viewModel = viewModel
        self.engine = engine
        self.cameraService = cameraService
        self.configuration = configuration
    }
#endif

    deinit {
        stop()
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        prepareEngineIfNeeded()
        guard isEnginePrepared else {
            isRunning = false
            return
        }

        viewModel.beginPreviewLoading()
        subscribeToCameraFrames()
        observeViewModelChanges()

        Task {
            do {
                try await cameraService.startSession()
            } catch {
                await MainActor.run {
                    self.viewModel.failPreview(message: error.localizedDescription)
                }
                stop()
            }
        }
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        frameCancellable?.cancel()
        frameCancellable = nil
        stateCancellable?.cancel()
        stateCancellable = nil
        renderTask?.cancel()
        renderTask = nil
        latestFrame = nil
#if canImport(UIKit)
        captureTask?.cancel()
        captureTask = nil
#endif
        cameraService.stopSession()
    }

    public func switchCamera() {
        Task {
            try? await cameraService.switchCamera()
        }
    }

#if canImport(UIKit)
    public func capture() {
        guard isEnginePrepared else {
            viewModel.resolveCapture(with: .failure(message: "Engine unavailable"))
            return
        }
        guard let frame = latestFrame else {
            viewModel.resolveCapture(with: .failure(message: "No frame available"))
            return
        }

        viewModel.beginCapture()
        captureTask?.cancel()
        captureTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let context = self.snapshotContext()
            do {
                let asciiFrame = try await self.engine.renderCapture(
                    pixelBuffer: frame.pixelBuffer,
                    effect: context.effect,
                    parameters: context.parameters,
                    palette: context.palette
                )
                guard let image = self.frameRenderer.makeImage(from: asciiFrame, palette: context.palette) else {
                    throw CaptureError.renderingFailed
                }
                try await self.mediaCoordinator.save(image: image)
                await MainActor.run {
                    self.viewModel.resolveCapture(with: .success(message: "Saved to Photos"))
                    self.onCaptureSuccess?(image)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.viewModel.resolveCapture(with: .failure(message: error.localizedDescription))
                }
            }
        }
    }

    public func processImportedImage(_ image: UIImage) {
        guard isEnginePrepared else { return }
        viewModel.beginPreviewLoading()

        renderTask?.cancel()
        renderTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let context = self.snapshotContext()
            guard let pixelBuffer = image.makePixelBuffer() else {
                await MainActor.run {
                    self.viewModel.failPreview(message: "Unable to read image")
                }
                return
            }

            let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
            self.latestFrame = envelope

            do {
                let asciiFrame = try await self.engine.renderPreview(
                    pixelBuffer: pixelBuffer,
                    effect: context.effect,
                    parameters: context.parameters,
                    palette: context.palette
                )
                guard let glyphs = asciiFrame.glyphText else { return }
                let preview = PreviewFrame(
                    id: UUID(),
                    glyphText: glyphs,
                    columns: asciiFrame.columns,
                    rows: asciiFrame.rows,
                    renderedEffect: context.effect
                )
                await MainActor.run {
                    self.viewModel.updatePreview(with: preview)
                }
            } catch {
                await MainActor.run {
                    self.viewModel.failPreview(message: error.localizedDescription)
                }
            }
        }
    }
#endif

    private func prepareEngineIfNeeded() {
        guard !isEnginePrepared else { return }
        do {
            try engine.prepare(configuration: configuration)
            isEnginePrepared = true
        } catch {
            viewModel.failPreview(message: error.localizedDescription)
        }
    }

    private func subscribeToCameraFrames() {
        frameCancellable = cameraService.framePublisher
            .receive(on: renderQueue)
            .sink { [weak self] envelope in
                self?.processFrame(envelope)
            }
    }

    private func observeViewModelChanges() {
#if canImport(Combine)
        let effectPublisher = viewModel.$selectedEffect.dropFirst().map { _ in () }
        let parameterPublisher = viewModel.$parameters.dropFirst().map { _ in () }
        let palettePublisher = viewModel.$palette.dropFirst().map { _ in () }

        stateCancellable = Publishers.Merge3(effectPublisher, parameterPublisher, palettePublisher)
            .debounce(for: .milliseconds(60), scheduler: DispatchQueue.main)
            .receive(on: renderQueue)
            .sink { [weak self] _ in
                self?.reprocessLatestFrame()
            }
#endif
    }

    private func reprocessLatestFrame() {
        guard let frame = latestFrame else { return }
        processFrame(frame)
    }

    private func processFrame(_ envelope: FrameEnvelope) {
        guard isEnginePrepared else { return }
        latestFrame = envelope
        let context = snapshotContext()
        renderTask?.cancel()
        renderTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let asciiFrame = try await self.engine.renderPreview(
                    pixelBuffer: envelope.pixelBuffer,
                    effect: context.effect,
                    parameters: context.parameters,
                    palette: context.palette
                )

                guard let glyphs = asciiFrame.glyphText else { return }
                let preview = PreviewFrame(
                    id: UUID(),
                    glyphText: glyphs,
                    columns: asciiFrame.columns,
                    rows: asciiFrame.rows,
                    renderedEffect: context.effect
                )

                await MainActor.run {
                    self.viewModel.updatePreview(with: preview)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.viewModel.failPreview(message: error.localizedDescription)
                }
            }
        }
    }

    private func snapshotContext() -> RenderContext {
        if Thread.isMainThread {
            return RenderContext(
                effect: viewModel.selectedEffect,
                parameters: viewModel.parameters,
                palette: viewModel.palette
            )
        }

        var context: RenderContext?
        DispatchQueue.main.sync {
            context = RenderContext(
                effect: viewModel.selectedEffect,
                parameters: viewModel.parameters,
                palette: viewModel.palette
            )
        }
        return context ?? RenderContext(effect: .ascii, parameters: EffectParameters(), palette: PaletteState())
    }
}

#if canImport(UIKit)
private enum CaptureError: Error {
    case renderingFailed
}

private extension UIImage {
    func makePixelBuffer() -> CVPixelBuffer? {
        guard let cgImage = cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
#endif
