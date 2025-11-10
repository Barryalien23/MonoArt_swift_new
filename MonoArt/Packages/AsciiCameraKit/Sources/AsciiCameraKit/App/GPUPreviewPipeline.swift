import Foundation
import Combine
import Metal
import MetalKit
import AsciiDomain
import AsciiEngine
import AsciiCamera
#if canImport(CoreMedia)
import CoreMedia
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif

/// GPU-accelerated preview pipeline using Metal rendering
@available(iOS 15.0, *)
@MainActor
public final class GPUPreviewPipeline {
    private struct RenderContext {
        let effect: EffectType
        let parameters: EffectParameters
        let palette: PaletteState
    }

    private let viewModel: AppViewModel
    public let engine: AsciiEngine
    private let cameraService: CameraServiceProtocol
    private let configuration: EngineConfiguration
    private var latestFrame: FrameEnvelope?
    private var textureCache: CVMetalTextureCache?
#if canImport(UIKit)
    private var previewRenderTask: Task<Void, Never>?
#endif
    
#if canImport(UIKit)
    private let frameRenderer: AsciiFrameRendering
    private let mediaCoordinator: MediaCoordinatorProtocol
    private var captureTask: Task<Void, Never>?
    public var onCaptureSuccess: ((UIImage) -> Void)?
#endif

    private var frameCancellable: AnyCancellable?
    private var stateCancellable: AnyCancellable?
    private var isEnginePrepared = false
    private var isRunning = false
    
    // GPU preview state
    public private(set) var mtkView: MTKView?

#if canImport(UIKit)
    public init(
        viewModel: AppViewModel,
        engine: AsciiEngine,
        cameraService: CameraServiceProtocol,
        configuration: EngineConfiguration = EngineConfiguration(),
        frameRenderer: AsciiFrameRendering? = nil,
        mediaCoordinator: MediaCoordinatorProtocol? = nil
    ) {
        self.viewModel = viewModel
        self.engine = engine
        self.cameraService = cameraService
        self.configuration = configuration
        self.frameRenderer = frameRenderer ?? AsciiFrameRenderer()
        self.mediaCoordinator = mediaCoordinator ?? PhotosMediaCoordinator()
        
        // Initialize texture cache
        if let device = MTLCreateSystemDefaultDevice() {
            CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        }
    }
#else
    public init(
        viewModel: AppViewModel,
        engine: AsciiEngine,
        cameraService: CameraServiceProtocol,
        configuration: EngineConfiguration = EngineConfiguration()
    ) {
        self.viewModel = viewModel
        self.engine = engine
        self.cameraService = cameraService
        self.configuration = configuration
        
        // Initialize texture cache
        if let device = MTLCreateSystemDefaultDevice() {
            CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        }
    }
#endif

    deinit {
        // Stop synchronously on cleanup
        if isRunning {
            frameCancellable?.cancel()
            frameCancellable = nil
            stateCancellable?.cancel()
            stateCancellable = nil
            isRunning = false
        }
    }

    public func setupMTKView(_ view: MTKView) {
        self.mtkView = view
        do {
            try engine.setupPreview(on: view, effect: viewModel.selectedEffect)
            // Set initial camera position
            updateCameraPosition()
        } catch {
            print("GPU Preview setup failed: \(error)")
        }
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
        updateCameraPosition()

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
    
    private func updateCameraPosition() {
        let isFront = cameraService.currentCameraPosition == .front
        engine.updateCameraPosition(isFront: isFront)
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        frameCancellable?.cancel()
        frameCancellable = nil
        stateCancellable?.cancel()
        stateCancellable = nil
        latestFrame = nil
#if canImport(UIKit)
        captureTask?.cancel()
        captureTask = nil
        previewRenderTask?.cancel()
        previewRenderTask = nil
        viewModel.updatePreviewImage(nil)
#endif
        cameraService.stopSession()
    }

    public func switchCamera() {
        Task {
            try? await cameraService.switchCamera()
            await MainActor.run {
                self.updateCameraPosition()
            }
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
        guard let pixelBuffer = image.makePixelBuffer() else {
            viewModel.failPreview(message: "Unable to read image")
            return
        }

        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        processFrame(envelope)
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
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] envelope in
                self?.processFrame(envelope)
            }
    }

    private func observeViewModelChanges() {
#if canImport(Combine)
        let effectPublisher = viewModel.$selectedEffect.dropFirst()
        let parameterPublisher = viewModel.$parameters.dropFirst()
        let palettePublisher = viewModel.$palette.dropFirst()

        stateCancellable = Publishers.Merge3(
            effectPublisher.map { _ in () },
            parameterPublisher.map { _ in () },
            palettePublisher.map { _ in () }
        )
        .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self else { return }
            let context = self.snapshotContext()
            self.engine.updatePreviewParameters(
                context.parameters,
                palette: context.palette,
                effect: context.effect
            )
        }
#endif
    }

    private func makeTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let cache = textureCache else {
            return nil
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var textureRef: CVMetalTexture?

        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &textureRef
        )

        guard status == kCVReturnSuccess,
              let unwrappedTextureRef = textureRef else {
            return nil
        }

        return CVMetalTextureGetTexture(unwrappedTextureRef)
    }

    private func snapshotContext() -> RenderContext {
        return RenderContext(
            effect: viewModel.selectedEffect,
            parameters: viewModel.parameters,
            palette: viewModel.palette
        )
    }

#if canImport(UIKit)
    private func renderPreviewImage(context: RenderContext, pixelBuffer: CVPixelBuffer) async -> UIImage? {
        do {
            let asciiFrame = try await engine.renderCapture(
                pixelBuffer: pixelBuffer,
                effect: context.effect,
                parameters: context.parameters,
                palette: context.palette
            )
            return frameRenderer.makeImage(from: asciiFrame, palette: context.palette)
        } catch {
            return nil
        }
    }

    private func processFrame(_ envelope: FrameEnvelope) {
        guard isEnginePrepared else { return }
        latestFrame = envelope
        let context = snapshotContext()

        previewRenderTask?.cancel()
        previewRenderTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            if let image = await self.renderPreviewImage(context: context, pixelBuffer: envelope.pixelBuffer) {
                await MainActor.run {
                    self.viewModel.updatePreviewImage(image)
                }
            }
        }
    }
#else
    private func processFrame(_ envelope: FrameEnvelope) {
        latestFrame = envelope
    }
#endif
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

