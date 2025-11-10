import Foundation
import Combine
import Metal
import MetalKit
import QuartzCore
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
    private var lastPreviewRenderTime: CFTimeInterval = 0
    private let previewFrameInterval: CFTimeInterval = 1.0 / 10.0
    private let previewMaxCells: Int = 36_000
    private var importedFrame: FrameEnvelope?
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
#if canImport(UIKit)
        lastPreviewRenderTime = 0
#endif
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
        lastPreviewRenderTime = 0
        previewRenderTask?.cancel()
        previewRenderTask = nil
        importedFrame = nil
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
        if viewModel.isImportMode {
            captureImportedPhoto()
        } else {
            captureLivePhoto()
        }
    }

    public func saveImportedPhoto() {
        captureImportedPhoto()
    }

    public func cancelImport() {
        previewRenderTask?.cancel()
        importedFrame = nil
        latestFrame = nil
        lastPreviewRenderTime = 0
        viewModel.cancelImport()
        viewModel.beginPreviewLoading()
    }

    public func processImportedImage(_ image: UIImage) {
        print("🖼️ GPUPreviewPipeline: processImportedImage called, isEnginePrepared: \(isEnginePrepared)")
        if !isEnginePrepared {
            print("❌ GPUPreviewPipeline: Engine not prepared, preparing now...")
            prepareEngineIfNeeded()
            if !isEnginePrepared {
                print("❌ GPUPreviewPipeline: Failed to prepare engine")
                viewModel.failPreview(message: "Engine not ready")
                return
            }
        }
        // Don't call beginImport yet - wait for the image to render first
        lastPreviewRenderTime = 0

        guard let pixelBuffer = image.makePixelBuffer() else {
            print("❌ GPUPreviewPipeline: Failed to create pixel buffer")
            viewModel.failPreview(message: "Unable to read image")
            return
        }

        print("✅ GPUPreviewPipeline: Pixel buffer created, starting render task")
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: .zero, orientation: .portrait)
        latestFrame = envelope
        importedFrame = envelope
        previewRenderTask?.cancel()
        previewRenderTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            print("🎨 GPUPreviewPipeline: Starting renderImportPreview")
            await self.renderImportPreview()
        }
    }

    private func captureLivePhoto() {
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
                guard let image = self.frameRenderer.makeImage(
                    from: asciiFrame,
                    effect: context.effect,
                    palette: context.palette,
                    mirrored: self.cameraService.currentCameraPosition == .front
                ) else {
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

    private func captureImportedPhoto() {
        guard viewModel.isImportMode else {
            captureLivePhoto()
            return
        }
        guard isEnginePrepared else {
            viewModel.resolveCapture(with: .failure(message: "Engine unavailable"))
            return
        }
        guard let frame = importedFrame else {
            viewModel.resolveCapture(with: .failure(message: "No imported frame available"))
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
                guard let image = self.frameRenderer.makeImage(
                    from: asciiFrame,
                    effect: context.effect,
                    palette: context.palette,
                    mirrored: self.cameraService.currentCameraPosition == .front
                ) else {
                    throw CaptureError.renderingFailed
                }
                try await self.mediaCoordinator.save(image: image)
                await MainActor.run {
                    self.viewModel.resolveCapture(with: .success(message: "Saved to Photos"))
                    self.onCaptureSuccess?(image)
                    self.viewModel.completeImport()
                    self.viewModel.updatePreviewImage(nil)
                    self.importedFrame = nil
                    self.latestFrame = nil
                    self.lastPreviewRenderTime = 0
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

    private func renderImportPreview() async {
        print("🎨 GPUPreviewPipeline: renderImportPreview started")
        guard let frame = importedFrame else {
            print("❌ GPUPreviewPipeline: No imported frame found")
            return
        }
        let context = snapshotContext()
        print("📸 GPUPreviewPipeline: Rendering with effect: \(context.effect), cells: \(previewMaxCells)")
        do {
            let asciiFrame = try await engine.renderCapture(
                pixelBuffer: frame.pixelBuffer,
                effect: context.effect,
                parameters: context.parameters,
                palette: context.palette,
                maxCellsOverride: previewMaxCells
            )
            print("✅ GPUPreviewPipeline: ASCII frame rendered, cols: \(asciiFrame.columns), rows: \(asciiFrame.rows)")
            if let image = frameRenderer.makeImage(
                from: asciiFrame,
                effect: context.effect,
                palette: context.palette,
                mirrored: cameraService.currentCameraPosition == .front
            ) {
                print("✅ GPUPreviewPipeline: UIImage created, size: \(image.size)")
                await MainActor.run {
                    print("🔄 GPUPreviewPipeline: Updating ViewModel, isImportMode: \(self.viewModel.isImportMode)")
                    if !self.viewModel.isImportMode {
                        print("🆕 GPUPreviewPipeline: Calling beginImport with image")
                        self.viewModel.beginImport(previewImage: image)
                    } else {
                        print("🔄 GPUPreviewPipeline: Calling updatePreviewImage")
                        self.viewModel.updatePreviewImage(image)
                    }
                }
            } else {
                print("❌ GPUPreviewPipeline: Failed to create UIImage from ASCII frame")
            }
        } catch {
            print("❌ GPUPreviewPipeline: Render error: \(error.localizedDescription)")
            await MainActor.run {
                self.viewModel.failPreview(message: error.localizedDescription)
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
            self.lastPreviewRenderTime = 0
            let context = self.snapshotContext()
            self.engine.updatePreviewParameters(
                context.parameters,
                palette: context.palette,
                effect: context.effect
            )
            if self.viewModel.isImportMode {
                self.previewRenderTask?.cancel()
                self.previewRenderTask = Task(priority: .userInitiated) { [weak self] in
                    await self?.renderImportPreview()
                }
            }
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
                palette: context.palette,
                maxCellsOverride: previewMaxCells
            )
            return frameRenderer.makeImage(from: asciiFrame,
                                           effect: context.effect,
                                           palette: context.palette,
                                           mirrored: cameraService.currentCameraPosition == .front)
        } catch {
            return nil
        }
    }

    private func processFrame(_ envelope: FrameEnvelope) {
        guard isEnginePrepared else { return }
        if viewModel.isImportMode {
            return
        }
        latestFrame = envelope
        let context = snapshotContext()

        let now = CACurrentMediaTime()
        let needsImmediateRender = viewModel.previewImage == nil
        if !needsImmediateRender && now - lastPreviewRenderTime < previewFrameInterval {
            return
        }
        lastPreviewRenderTime = now

        previewRenderTask?.cancel()
        previewRenderTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            if let image = await self.renderPreviewImage(context: context, pixelBuffer: envelope.pixelBuffer) {
                await MainActor.run {
                    self.viewModel.updatePreviewImage(image)
                    self.lastPreviewRenderTime = CACurrentMediaTime()
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
    func mirrorHorizontally() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext(),
              let cgImage = self.cgImage else { return nil }
        context.translateBy(x: size.width, y: size.height)
        context.scaleBy(x: -1.0, y: -1.0)
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

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

