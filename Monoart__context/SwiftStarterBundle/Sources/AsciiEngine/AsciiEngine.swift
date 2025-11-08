import CoreImage
import CoreVideo
import Foundation
@preconcurrency import Metal
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
    func renderCapture(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame
}

/// Production-ready ASCII engine built on Metal with a CPU fallback.
@available(macOS 10.15, iOS 15.0, tvOS 15.0, *)
public final class AsciiEngine: AsciiEngineProtocol {
    private let deviceProvider: () -> MTLDevice?
    private let processingQueue = DispatchQueue(label: "com.monoart.asciiengine.processing", qos: .userInitiated)

    private var configuration: EngineConfiguration = EngineConfiguration()
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLComputePipelineState?
    private var textureCache: CVMetalTextureCache?
    private var ciContext: CIContext?
    private var isPrepared = false

    public init(deviceProvider: @escaping () -> MTLDevice? = { MTLCreateSystemDefaultDevice() }) {
        self.deviceProvider = deviceProvider
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
        return try await render(pixelBuffer: pixelBuffer, effect: effect, parameters: parameters, palette: palette, maxCells: configuration.maxPreviewCells)
    }

    public func renderCapture(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try ensurePrepared()
        return try await render(pixelBuffer: pixelBuffer, effect: effect, parameters: parameters, palette: palette, maxCells: configuration.maxCaptureCells)
    }

    // MARK: - Private

    private func render(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState, maxCells: Int) async throws -> AsciiFrame {
        try processingQueue.sync {
            let grid = GridPlanner.makeGrid(for: pixelBuffer, parameters: parameters, maxCells: maxCells)
            let luminance: [Float]
            if let device = self.device, let commandQueue = self.commandQueue, let pipelineState = self.pipelineState {
                luminance = try self.renderWithMetal(pixelBuffer: pixelBuffer, grid: grid, device: device, commandQueue: commandQueue, pipelineState: pipelineState)
            } else {
                luminance = try self.renderWithCPU(pixelBuffer: pixelBuffer, grid: grid)
            }

            let softened = self.applySofty(luminance, grid: grid, softy: parameters.softy.rawValue)
            let asciiText = self.composeASCII(
                luminanceValues: softened,
                grid: grid,
                effect: effect,
                jitter: parameters.jitter.rawValue,
                edge: parameters.edge.rawValue,
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
        jitter: Double,
        edge: Double,
        palette: PaletteState
    ) -> String {
        let glyphs = GlyphAtlas.glyphs(for: effect)
        guard !glyphs.isEmpty else { return "" }

        let jitterAmplitude = Int((jitter / EffectParameterValue.range.upperBound) * Double(max(1, glyphs.count / 4))).clamped(to: 0 ... max(1, glyphs.count - 1))
        let edgeFactor = max(0, min(1, edge / EffectParameterValue.range.upperBound))
        let seed = UInt64(bitPattern: Int64(palette.hashValue ^ grid.columns ^ grid.rows)) ^ UInt64(jitterAmplitude)
        var rng = SeededRandomGenerator(seed: seed)

        var builder = String()
        builder.reserveCapacity(grid.totalCells + grid.rows)

        for row in 0 ..< grid.rows {
            for column in 0 ..< grid.columns {
                let index = row * grid.columns + column
                var value = luminanceValues[index]
                value = applyEdgeAdjustment(value, factor: edgeFactor)
                value = max(0, min(1, value))
                let inverted = 1 - value
                let scaledDouble = Double(glyphs.count - 1) * Double(inverted)
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

    private func applyEdgeAdjustment(_ value: Float, factor: Double) -> Float {
        guard factor > 0 else { return value }
        let contrast = Float(1 + factor * 0.8)
        let midpoint: Float = 0.5
        let adjusted = (value - midpoint) * contrast + midpoint
        return max(0, min(1, adjusted))
    }

    private func ensurePrepared() throws {
        guard isPrepared else {
            throw AsciiEngineError.configurationFailure("AsciiEngine.prepare(configuration:) was not called")
        }
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

/// Placeholder engine retained for previews/tests that don't require the full pipeline yet.
public final class StubAsciiEngine: AsciiEngineProtocol {
    public init() {}

    public func prepare(configuration: EngineConfiguration) throws {}

    public func renderPreview(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try await renderFallbackFrame()
    }

    public func renderCapture(pixelBuffer: CVPixelBuffer, effect: EffectType, parameters: EffectParameters, palette: PaletteState) async throws -> AsciiFrame {
        try await renderFallbackFrame()
    }

    private func renderFallbackFrame() async throws -> AsciiFrame {
        let text = "▒░▒░\n░▒░▒"
        return AsciiFrame(texture: nil, glyphText: text, columns: 4, rows: 2)
    }
}

