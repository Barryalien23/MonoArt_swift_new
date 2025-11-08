#if canImport(MetalKit) && canImport(AVFoundation) && os(iOS)
import Foundation
import MetalKit
import Metal
import CoreVideo
import AVFoundation
import AsciiEngine
import AsciiDomain

/// Coordinates GPU-based preview by converting camera frames to Metal textures
/// and updating the AsciiEngine's video texture.
@available(iOS 15.0, *)
public final class GPUPreviewCoordinator {
    private let engine: AsciiEngine
    private let device: MTLDevice
    private var textureCache: CVMetalTextureCache?
    
    public init(engine: AsciiEngine, device: MTLDevice) {
        self.engine = engine
        self.device = device
        
        var cache: CVMetalTextureCache?
        let status = CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        if status == kCVReturnSuccess {
            self.textureCache = cache
        }
    }
    
    /// Converts a CVPixelBuffer to MTLTexture and updates the engine
    @MainActor
    public func updateFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let texture = makeTexture(from: pixelBuffer) else { return }
        engine.updatePreviewVideoTexture(texture)
    }
    
    /// Updates render parameters on the engine
    @MainActor
    public func updateParameters(_ parameters: EffectParameters, palette: PaletteState, effect: EffectType) {
        engine.updatePreviewParameters(parameters, palette: palette, effect: effect)
    }
    
    private func makeTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let cache = textureCache else { return nil }
        
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Support BGRA/ARGB formats commonly used by camera
        let metalFormat: MTLPixelFormat
        if pixelFormat == kCVPixelFormatType_32BGRA {
            metalFormat = .bgra8Unorm
        } else if pixelFormat == kCVPixelFormatType_32ARGB {
            metalFormat = .rgba8Unorm
        } else {
            return nil
        }
        
        var textureRef: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            nil,
            cache,
            pixelBuffer,
            nil,
            metalFormat,
            width,
            height,
            0,
            &textureRef
        )
        
        guard status == kCVReturnSuccess,
              let ref = textureRef,
              let texture = CVMetalTextureGetTexture(ref) else {
            return nil
        }
        
        return texture
    }
}
#endif

