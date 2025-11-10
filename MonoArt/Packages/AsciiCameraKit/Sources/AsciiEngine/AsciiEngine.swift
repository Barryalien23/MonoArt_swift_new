import CoreImage
import CoreVideo
import Foundation
import AVFoundation
@preconcurrency import Metal
import MetalKit
import AsciiDomain

/// Shared configuration object controlling how the ASCII engine allocates GPU resources.
public struct EngineConfiguration: Sendable {
    public var maxPreviewCells: Int
    public var maxCaptureCells: Int

    public init(maxPreviewCells: Int = 18_000, maxCaptureCells: Int = 64_000) {
        self.maxPreviewCells = maxPreviewCells
        self.maxCaptureCells = maxCaptureCells
    }
}

/// Result returned by the engine after processing a frame.
public struct AsciiFrame {
    public let texture: MTLTexture?
    public let glyphText: String?
    public let columns: Int
    public let rows: Int

    public init(texture: MTLTexture?, glyphText: String?, columns: Int, rows: Int) {
        self.texture = texture
        self.glyphText = glyphText
        self.columns = columns
        self.rows = rows
    }
}

struct PreviewUniforms {
    var targetSize: SIMD2<Float>
    var videoSize: SIMD2<Float>
    var cellSize: SIMD2<UInt32>
    var atlasGrid: SIMD2<UInt32>
    var colorA: SIMD4<Float>
    var colorB: SIMD4<Float>
    var contrast: Float  // Controls image contrast (0..1)
    var jitter: Float
    var time: Float
    var mirrorHorizontal: Float  // 1.0 for front camera (mirror), 0.0 for back camera
}

public enum AsciiEngineError: Error {
    case metalUnavailable
    case unsupportedPixelFormat
    case configurationFailure(String)
    case internalError(_ reason: String)
}

/// Protocol describing the surface area required by the SwiftUI layer.
public protocol AsciiEngineProtocol: AnyObject {
    func prepare(configuration: EngineConfiguration) throws
    func renderPreview(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame
    func renderCapture(pixelBuffer: CVPixelBuffer, orientation: AVCaptureVideoOrientation, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame
}

/// Production-ready ASCII engine built on Metal with a CPU fallback.
@available(macOS 10.15, iOS 15.0, tvOS 15.0, *)
@MainActor
private struct PreviewState {
    var view: MTKView?
    var grid: GridDescriptor?
    var videoTexture: MTLTexture?
    var effect: EffectType = .ascii
    var parameters: EffectParameters = EffectParameters()
    var palette: PaletteState = PaletteState()
    var time: Float = 0
    var isFrontCamera: Bool = false
}

@available(macOS 10.15, iOS 15.0, tvOS 15.0, *)
public final class AsciiEngine: NSObject, AsciiEngineProtocol, MTKViewDelegate {
    private let deviceProvider: () -> MTLDevice?
    private let processingQueue = DispatchQueue(label: "com.monoart.asciiengine.processing", qos: .userInitiated)

    private var configuration: EngineConfiguration = EngineConfiguration()
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLComputePipelineState?
    private var textureCache: CVMetalTextureCache?
    private var ciContext: CIContext?
    private var isPrepared = false
    private var library: MTLLibrary?

    // GPU preview resources
    private var previewPipelineState: MTLRenderPipelineState?
    private var previewSamplerVideo: MTLSamplerState?
    private var previewSamplerAtlas: MTLSamplerState?
    private var atlasCache: [EffectType: GlyphAtlas] = [:]
    @MainActor private var previewState = PreviewState()

    public init(deviceProvider: @escaping () -> MTLDevice? = { MTLCreateSystemDefaultDevice() }) {
        self.deviceProvider = deviceProvider
        super.init()
    }

    public func prepare(configuration: EngineConfiguration) throws {
        self.configuration = configuration

        if let device = deviceProvider() {
            self.device = device
            guard let commandQueue = device.makeCommandQueue() else {
                throw AsciiEngineError.configurationFailure("Unable to create command queue")
            }
            let library = try device.makeLibrary(source: luminanceKernelSource, options: nil)
            guard let function = library.makeFunction(name: "asciiLuminanceDownsample") else {
                throw AsciiEngineError.configurationFailure("Missing asciiLuminanceDownsample shader")
            }
            do {
                pipelineState = try device.makeComputePipelineState(function: function)
            } catch {
                throw AsciiEngineError.configurationFailure("Unable to compile compute pipeline: \(error)")
            }

            var cache: CVMetalTextureCache?
            let status = CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
            if status != kCVReturnSuccess {
                throw AsciiEngineError.configurationFailure("Unable to create texture cache (status: \(status))")
            }
            textureCache = cache
            commandQueue.label = "AsciiEngineCommandQueue"
            self.commandQueue = commandQueue
            self.ciContext = CIContext(mtlDevice: device)
        } else {
            // Metal unavailable — fall back to CPU-based CIContext renderer.
            device = nil
            commandQueue = nil
            pipelineState = nil
            textureCache = nil
            ciContext = CIContext(options: [.useSoftwareRenderer: true])
        }

        isPrepared = true
    }

    public func renderPreview(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try ensurePrepared()
        // Fallback to portrait aspect for legacy preview usage
        return try await render(pixelBuffer: pixelBuffer, orientation: .portrait, effect: effect, parameters: parameters, palette: palette, maxCells: configuration.maxPreviewCells)
    }

    public func renderCapture(pixelBuffer: CVPixelBuffer, orientation: AVCaptureVideoOrientation, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try await renderCapture(
            pixelBuffer: pixelBuffer,
            orientation: orientation,
            effect: effect,
            parameters: parameters,
            palette: palette,
            maxCellsOverride: nil
        )
    }

    public func renderCapture(
        pixelBuffer: CVPixelBuffer,
        orientation: AVCaptureVideoOrientation,
        effect: EffectType,
        parameters: EffectParameters,
        palette: PaletteState,
        maxCellsOverride: Int? = nil
    ) async throws -> AsciiFrame {
        try ensurePrepared()
        let maxCells = maxCellsOverride ?? configuration.maxCaptureCells
        return try await render(pixelBuffer: pixelBuffer, orientation: orientation, effect: effect, parameters: parameters, palette: palette, maxCells: maxCells)
    }

    // MARK: - Private

    private func render(pixelBuffer: CVPixelBuffer, orientation: AVCaptureVideoOrientation, effect: EffectType, parameters: EffectParameters, palette: PaletteState, maxCells: Int) async throws -> AsciiFrame {
        try processingQueue.sync {
            let grid = GridPlanner.makeGrid(for: pixelBuffer, orientation: orientation, parameters: parameters, maxCells: maxCells)
            let luminance: [Float]
            if let device = self.device, let commandQueue = self.commandQueue, let pipelineState = self.pipelineState {
                luminance = try self.renderWithMetal(pixelBuffer: pixelBuffer, grid: grid, device: device, commandQueue: commandQueue, pipelineState: pipelineState)
            } else {
                luminance = try self.renderWithCPU(pixelBuffer: pixelBuffer, grid: grid)
            }

            // Remove applySofty - no blur, use raw luminance
            // Contrast is now applied inside composeASCII to match GPU shader
            let asciiText = self.composeASCII(
                luminanceValues: luminance,
                grid: grid,
                effect: effect,
                parameters: parameters,
                palette: palette
            )

            return AsciiFrame(texture: nil, glyphText: asciiText, columns: grid.columns, rows: grid.rows)
        }
    }

    private func renderWithMetal(pixelBuffer: CVPixelBuffer, grid: GridDescriptor, device: MTLDevice, commandQueue: MTLCommandQueue, pipelineState: MTLComputePipelineState) throws -> [Float] {
        guard let texture = try makeTexture(from: pixelBuffer, device: device) else {
            throw AsciiEngineError.unsupportedPixelFormat
        }

        guard let buffer = device.makeBuffer(length: grid.totalCells * MemoryLayout<Float>.stride, options: [.storageModeShared]) else {
            throw AsciiEngineError.internalError("Unable to create luminance buffer")
        }

        var gridSize = SIMD2<UInt32>(UInt32(grid.columns), UInt32(grid.rows))
        guard let gridBuffer = device.makeBuffer(bytes: &gridSize, length: MemoryLayout<SIMD2<UInt32>>.stride, options: []) else {
            throw AsciiEngineError.internalError("Unable to create grid buffer")
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw AsciiEngineError.internalError("Unable to create command buffer")
        }
        commandBuffer.label = "AsciiEngineCommandBuffer"

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw AsciiEngineError.internalError("Unable to create compute encoder")
        }
        encoder.label = "AsciiEngineLuminanceEncoder"
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        encoder.setBuffer(gridBuffer, offset: 0, index: 1)

        let threadsPerGrid = MTLSize(width: grid.columns, height: grid.rows, depth: 1)
        let threadWidth = pipelineState.threadExecutionWidth
        let maxTotalThreads = pipelineState.maxTotalThreadsPerThreadgroup
        let threadHeight = max(1, maxTotalThreads / threadWidth)
        let threadgroupSize = MTLSize(width: min(threadWidth, grid.columns), height: min(threadHeight, grid.rows), depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let pointer = buffer.contents().bindMemory(to: Float.self, capacity: grid.totalCells)
        return Array(UnsafeBufferPointer(start: pointer, count: grid.totalCells))
    }

    private func renderWithCPU(pixelBuffer: CVPixelBuffer, grid: GridDescriptor) throws -> [Float] {
        guard let context = ciContext else {
            throw AsciiEngineError.internalError("CIContext unavailable for CPU fallback")
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmap = [UInt8](repeating: 0, count: grid.totalCells * 4)
        context.render(
            ciImage,
            toBitmap: &bitmap,
            rowBytes: grid.columns * 4,
            bounds: extent,
            format: .RGBA8,
            colorSpace: colorSpace
        )

        var luminance = [Float](repeating: 0, count: grid.totalCells)
        for row in 0 ..< grid.rows {
            for column in 0 ..< grid.columns {
                let index = (row * grid.columns + column) * 4
                let r = Float(bitmap[index]) / 255.0
                let g = Float(bitmap[index + 1]) / 255.0
                let b = Float(bitmap[index + 2]) / 255.0
                luminance[row * grid.columns + column] = max(0, min(1, 0.2126 * r + 0.7152 * g + 0.0722 * b))
            }
        }
        return luminance
    }

    private func makeTexture(from pixelBuffer: CVPixelBuffer, device: MTLDevice) throws -> MTLTexture? {
        guard let cache = textureCache else {
            throw AsciiEngineError.internalError("Texture cache unavailable")
        }
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        if pixelFormat == kCVPixelFormatType_32BGRA || pixelFormat == kCVPixelFormatType_32ARGB {
            var textureRef: CVMetalTexture?
            let status = CVMetalTextureCacheCreateTextureFromImage(nil, cache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &textureRef)
            guard status == kCVReturnSuccess, let ref = textureRef, let texture = CVMetalTextureGetTexture(ref) else {
                throw AsciiEngineError.unsupportedPixelFormat
            }
            return texture
        } else {
            guard let context = ciContext else {
                throw AsciiEngineError.unsupportedPixelFormat
            }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var data = [UInt8](repeating: 0, count: width * height * 4)
            context.render(
                ciImage,
                toBitmap: &data,
                rowBytes: width * 4,
                bounds: ciImage.extent,
                format: .RGBA8,
                colorSpace: colorSpace
            )

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            guard let texture = device.makeTexture(descriptor: descriptor) else {
                throw AsciiEngineError.internalError("Unable to allocate texture for converted pixel buffer")
            }

            let region = MTLRegionMake2D(0, 0, width, height)
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: width * 4)
            return texture
        }
    }

    private func applySofty(_ luminance: [Float], grid: GridDescriptor, softy: Double) -> [Float] {
        guard softy > 0 else { return luminance }
        let iterations = min(3, max(1, Int((softy / EffectParameterValue.range.upperBound) * 3)))
        var result = luminance
        for _ in 0 ..< iterations {
            result = boxBlur(result, grid: grid)
        }
        return result
    }

    private func boxBlur(_ input: [Float], grid: GridDescriptor) -> [Float] {
        var output = input
        for row in 0 ..< grid.rows {
            for column in 0 ..< grid.columns {
                var sum: Float = 0
                var count: Float = 0
                for dy in -1 ... 1 {
                    for dx in -1 ... 1 {
                        let ny = row + dy
                        let nx = column + dx
                        guard ny >= 0, ny < grid.rows, nx >= 0, nx < grid.columns else { continue }
                        sum += input[ny * grid.columns + nx]
                        count += 1
                    }
                }
                output[row * grid.columns + column] = sum / max(count, 1)
            }
        }
        return output
    }

    private func composeASCII(
        luminanceValues: [Float],
        grid: GridDescriptor,
        effect: EffectType,
        parameters: EffectParameters,
        palette: PaletteState
    ) -> String {
        let glyphs = effect.characterSet
        guard !glyphs.isEmpty else { return "" }

        let jitterAmplitude = Int((parameters.jitter.rawValue / EffectParameterValue.range.upperBound) * Double(max(1, glyphs.count / 4))).clamped(to: 0 ... max(1, glyphs.count - 1))
        let seed = UInt64(bitPattern: Int64(palette.hashValue ^ grid.columns ^ grid.rows)) ^ UInt64(jitterAmplitude)
        var rng = SeededRandomGenerator(seed: seed)

        var builder = String()
        builder.reserveCapacity(grid.totalCells + grid.rows)

        for row in 0 ..< grid.rows {
            for column in 0 ..< grid.columns {
                let index = row * grid.columns + column
                var value = luminanceValues[index]
                value = max(0, min(1, value))
                
                // Apply contrast adjustment (matches GPU shader)
                let contrastFactor = Float(parameters.softy.rawValue / EffectParameterValue.range.upperBound)
                let contrastMultiplier = 0.2 + contrastFactor * 2.8
                value = max(0, min(1, (value - 0.5) * contrastMultiplier + 0.5))
                
                // 🌑 Darken shadows: apply power curve to push dark areas toward zero
                // This makes dark areas use minimal/no symbols (space, dot)
                // Power 1.5 = moderate darkening (matches GPU shader)
                value = pow(value, 1.5)
                
                // 🌌 Pure darkness threshold: cut off very dark areas completely
                // Below this threshold → force to index 0 (space/empty) for absolute void
                let darknessThreshold: Float = 0.15  // 0.0-0.15 becomes pure black (no symbols)
                if value < darknessThreshold {
                    value = 0.0  // Force to space character (index 0)
                }
                
                // Direct mapping: 
                // - Very dark areas (< 0.15) → NOTHING (absolute void) 🌌
                // - Dark areas → minimal symbols (dot) ✨
                // - Light areas → dense symbols (letters, @, $)
                let scaledDouble = Double(glyphs.count - 1) * Double(value)
                let scaled = Int(scaledDouble).clamped(to: 0 ... glyphs.count - 1)
                var finalIndex = scaled
                if jitterAmplitude > 0 {
                    let offset = rng.nextInt(in: -jitterAmplitude ... jitterAmplitude)
                    finalIndex = (scaled + offset).clamped(to: 0 ... glyphs.count - 1)
                }
                builder.append(glyphs[finalIndex])
            }
            if row < grid.rows - 1 {
                builder.append("\n")
            }
        }

        return builder
    }


    private func ensurePrepared() throws {
        guard isPrepared else {
            throw AsciiEngineError.configurationFailure("AsciiEngine.prepare(configuration:) was not called")
        }
    }

    // MARK: - GPU Preview Setup & Rendering

    @MainActor
    public func setupPreview(on mtkView: MTKView, effect: EffectType) throws {
        guard let device = self.device else {
            throw AsciiEngineError.metalUnavailable
        }

        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.delegate = self
        mtkView.preferredFramesPerSecond = 60

        // Load Metal library from source (fallback if .metal compilation unavailable)
        let previewLibrary: MTLLibrary
        if let defaultLibrary = device.makeDefaultLibrary(),
           defaultLibrary.functionNames.contains("previewVS") {
            previewLibrary = defaultLibrary
        } else {
            // Compile from source if .metal file isn't available
            do {
                previewLibrary = try device.makeLibrary(source: previewShaderSource, options: nil)
            } catch {
                throw AsciiEngineError.configurationFailure("Unable to compile preview shaders: \(error)")
            }
        }
        self.library = previewLibrary

        guard let vertexFunction = previewLibrary.makeFunction(name: "previewVS"),
              let fragmentFunction = previewLibrary.makeFunction(name: "previewFS") else {
            throw AsciiEngineError.configurationFailure("Unable to load preview shader functions")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
            previewPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            throw AsciiEngineError.configurationFailure("Unable to create preview render pipeline: \(error)")
        }

        // Create samplers
        let videoSamplerDescriptor = MTLSamplerDescriptor()
        videoSamplerDescriptor.minFilter = .linear
        videoSamplerDescriptor.magFilter = .linear
        videoSamplerDescriptor.sAddressMode = .clampToEdge
        videoSamplerDescriptor.tAddressMode = .clampToEdge
        previewSamplerVideo = device.makeSamplerState(descriptor: videoSamplerDescriptor)

        let atlasSamplerDescriptor = MTLSamplerDescriptor()
        atlasSamplerDescriptor.minFilter = .nearest
        atlasSamplerDescriptor.magFilter = .nearest
        atlasSamplerDescriptor.sAddressMode = .clampToEdge
        atlasSamplerDescriptor.tAddressMode = .clampToEdge
        previewSamplerAtlas = device.makeSamplerState(descriptor: atlasSamplerDescriptor)

        // Generate atlas for the current effect
        let atlas = GlyphAtlas.make(device: device, effect: effect)
        atlasCache[effect] = atlas
        previewState.view = mtkView
        previewState.effect = effect
    }

    @MainActor
    public func updatePreviewVideoTexture(_ texture: MTLTexture) {
        previewState.videoTexture = texture
    }
    
    @MainActor
    public func updateCameraPosition(isFront: Bool) {
        previewState.isFrontCamera = isFront
    }

    @MainActor
    public func updatePreviewParameters(_ parameters: EffectParameters, palette: PaletteState, effect: EffectType) {
        previewState.parameters = parameters
        previewState.palette = palette

        // Regenerate atlas if effect changed
        if previewState.effect != effect, let device = self.device {
            previewState.effect = effect
            if atlasCache[effect] == nil {
                atlasCache[effect] = GlyphAtlas.make(device: device, effect: effect)
            }
        }
    }

    // MARK: - MTKViewDelegate

    @MainActor
    public func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandQueue = self.commandQueue,
              let pipelineState = self.previewPipelineState,
              let videoTexture = previewState.videoTexture,
              let atlas = atlasCache[previewState.effect] else {
            return
        }

        previewState.time += 0.016

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setFragmentTexture(videoTexture, index: 0)
        renderEncoder.setFragmentTexture(atlas.texture, index: 1)

        if let videoSampler = previewSamplerVideo {
            renderEncoder.setFragmentSamplerState(videoSampler, index: 0)
        }
        if let atlasSampler = previewSamplerAtlas {
            renderEncoder.setFragmentSamplerState(atlasSampler, index: 1)
        }

        // Compute uniforms from current state
        let cellPercent = previewState.parameters.cell.rawValue / EffectParameterValue.range.upperBound
        // Invert cell logic: higher cell value = smaller cell size = more symbols
        // Reduced range for finer preview (4..12px instead of 48..16px)
        let cellPixels = Int(12 - cellPercent * 8) // 12..4 pixels per cell (much finer for better preview quality)
        let jitterFactor = Float(previewState.parameters.jitter.rawValue / EffectParameterValue.range.upperBound)
        let contrastFactor = Float(previewState.parameters.softy.rawValue / EffectParameterValue.range.upperBound)

        let bgColor = previewState.palette.background
        let fgColor: ColorDescriptor
        switch previewState.palette.symbols {
        case .solid(let color):
            fgColor = color
        case .gradient(let stops):
            fgColor = stops.first?.color ?? .preset(.white)
        }

        var uniforms = PreviewUniforms(
            targetSize: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            videoSize: SIMD2<Float>(Float(videoTexture.width), Float(videoTexture.height)),
            cellSize: SIMD2<UInt32>(UInt32(max(cellPixels, 1)), UInt32(max(cellPixels, 1))),
            atlasGrid: SIMD2<UInt32>(UInt32(atlas.gridColumns), UInt32(atlas.gridRows)),
            colorA: SIMD4<Float>(Float(bgColor.red), Float(bgColor.green), Float(bgColor.blue), Float(bgColor.alpha)),
            colorB: SIMD4<Float>(Float(fgColor.red), Float(fgColor.green), Float(fgColor.blue), Float(fgColor.alpha)),
            contrast: contrastFactor, // Controls image contrast (0..1)
            jitter: jitterFactor,
            time: previewState.time,
            mirrorHorizontal: previewState.isFrontCamera ? 1.0 : 0.0
        )

        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<PreviewUniforms>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    @MainActor
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No-op: uniforms recalculated on each draw
    }
}

// MARK: - Helper Types

private struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x00DADBADC0FFEE : seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let value = next() % span
        return range.lowerBound + Int(value)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

private let luminanceKernelSource = """
#include <metal_stdlib>
using namespace metal;

struct GridSize {
    uint columns;
    uint rows;
};

kernel void asciiLuminanceDownsample(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    device float *luminanceBuffer [[buffer(0)]],
    constant GridSize &grid [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= grid.columns || gid.y >= grid.rows) {
        return;
    }

    uint width = sourceTexture.get_width();
    uint height = sourceTexture.get_height();

    uint cellWidth = max(width / grid.columns, 1u);
    uint cellHeight = max(height / grid.rows, 1u);

    uint startX = gid.x * cellWidth;
    uint startY = gid.y * cellHeight;
    uint endX = min(startX + cellWidth, width);
    uint endY = min(startY + cellHeight, height);

    float luminance = 0.0f;
    uint count = 0u;

    for (uint y = startY; y < endY; ++y) {
        for (uint x = startX; x < endX; ++x) {
            float4 color = sourceTexture.read(uint2(x, y));
            float value = dot(color.rgb, float3(0.2126f, 0.7152f, 0.0722f));
            luminance += value;
            count += 1u;
        }
    }

    uint index = gid.y * grid.columns + gid.x;
    if (count == 0u) {
        luminanceBuffer[index] = 0.0f;
    } else {
        luminanceBuffer[index] = luminance / float(count);
    }
}
"""

private let previewShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct PreviewUniforms {
    float2 targetSize;
    float2 videoSize;
    uint2  cellSize;
    uint2  atlasGrid;
    float4 colorA;
    float4 colorB;
    float  contrast;  // Controls image contrast (0..1)
    float  jitter;
    float  time;
    float  mirrorHorizontal;  // 1.0 for front camera (mirror), 0.0 for back camera
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut previewVS(uint vertexID [[vertex_id]]) {
    float2 pos = float2((vertexID == 2) ? 3.0 : -1.0,
                        (vertexID == 1) ? 3.0 : -1.0);
    VSOut out;
    out.position = float4(pos, 0.0, 1.0);
    // Flip Y coordinate to fix upside-down camera
    out.uv = float2((pos.x * 0.5) + 0.5, 1.0 - ((pos.y * 0.5) + 0.5));
    return out;
}

inline float2 aspectFill(float2 uv, float2 targetSize, float2 sourceSize) {
    float targetAR = targetSize.x / targetSize.y;
    float sourceAR = sourceSize.x / sourceSize.y;
    if (sourceAR > targetAR) {
        float scale = sourceAR / targetAR;
        uv.x = (uv.x - 0.5) * scale + 0.5;
    } else {
        float scale = targetAR / sourceAR;
        uv.y = (uv.y - 0.5) * scale + 0.5;
    }
    return uv;
}

inline float rand21(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

fragment float4 previewFS(
    VSOut in [[stage_in]],
    texture2d<float> videoTexture [[texture(0)]],
    texture2d<float> atlasTexture [[texture(1)]],
    constant PreviewUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler videoSampler(filter::linear, address::clamp_to_edge);
    constexpr sampler atlasSampler(filter::nearest, address::clamp_to_edge);

    float2 fragmentPixel = in.uv * uniforms.targetSize;
    float2 cell = floor(fragmentPixel / float2(uniforms.cellSize));
    float2 local = fract(fragmentPixel / float2(uniforms.cellSize));

    // Apply horizontal mirror for front camera
    float2 adjustedUV = in.uv;
    if (uniforms.mirrorHorizontal > 0.5) {
        adjustedUV.x = 1.0 - adjustedUV.x;
    }
    
    float2 videoUV = aspectFill(adjustedUV, uniforms.targetSize, uniforms.videoSize);
    float3 rgb = videoTexture.sample(videoSampler, videoUV).rgb;
    float luminance = dot(rgb, float3(0.2126, 0.7152, 0.0722));
    
    // Apply contrast adjustment
    // Contrast range: 0..1 maps to multiplier 0.2..3.0
    // At 0.0: very low contrast (0.2x) - extremely soft, muted
    // At 0.5: neutral (1.6x) - balanced
    // At 1.0: very high contrast (3.0x) - extremely sharp, pronounced
    float contrastMultiplier = 0.2 + uniforms.contrast * 2.8;
    luminance = clamp((luminance - 0.5) * contrastMultiplier + 0.5, 0.0, 1.0);
    
    // 🌑 Darken shadows: apply power curve to push dark areas toward zero
    // This makes dark areas use minimal/no symbols (space, dot)
    // Power 1.5 = moderate darkening, 2.0 = strong darkening
    luminance = pow(luminance, 1.5);
    
    // 🌌 Pure darkness threshold: cut off very dark areas completely
    // Below this threshold → force to index 0 (space/empty) for absolute void
    const float darknessThreshold = 0.15;  // 0.0-0.15 becomes pure black (no symbols)
    if (luminance < darknessThreshold) {
        luminance = 0.0;  // Force to space character (index 0)
    }

    uint glyphCount = uniforms.atlasGrid.x * uniforms.atlasGrid.y;
    // Natural mapping:
    // - Very dark areas (< 0.15) → NOTHING (absolute void) 🌌
    // - Dark areas → minimal symbols (dot) ✨
    // - Light areas → dense symbols (letters, @, $)
    float glyphIndex = luminance * float(glyphCount - 1);

    float noise = rand21(cell + uniforms.time);
    if (uniforms.jitter > 0.0) {
        float delta = (noise < uniforms.jitter) ? (noise * 2.0 - 1.0) : 0.0;
        glyphIndex = clamp(glyphIndex + delta, 0.0, float(glyphCount - 1));
    }

    uint idx = static_cast<uint>(glyphIndex);
    uint atlasX = idx % uniforms.atlasGrid.x;
    uint atlasY = idx / uniforms.atlasGrid.x;
    float2 atlasUV = (float2(atlasX, atlasY) + local) / float2(uniforms.atlasGrid);

    float glyphSample = atlasTexture.sample(atlasSampler, atlasUV).r;
    // Fixed threshold for glyph rendering with smooth anti-aliasing
    float threshold = 0.5;
    float softness = 0.15;
    float alpha = smoothstep(threshold - softness, threshold + softness, glyphSample);

    return mix(uniforms.colorA, uniforms.colorB, alpha);
}
"""

/// Placeholder engine retained for previews/tests that don't require the full pipeline yet.
public final class StubAsciiEngine: AsciiEngineProtocol {
    public init() {}

    public func prepare(configuration: EngineConfiguration) throws {}

    public func renderPreview(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try await renderFallbackFrame()
    }

    public func renderCapture(pixelBuffer: CVPixelBuffer, orientation: AVCaptureVideoOrientation, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try await renderFallbackFrame()
    }

    private func renderFallbackFrame() async throws -> AsciiFrame {
        let text = "▒░▒░\n░▒░▒"
        return AsciiFrame(texture: nil, glyphText: text, columns: 4, rows: 2)
    }
}

