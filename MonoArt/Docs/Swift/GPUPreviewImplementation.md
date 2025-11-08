# GPU-Based ASCII Preview Implementation

## Overview

This document describes the GPU-accelerated ASCII preview pipeline implemented for MonoArt. The implementation uses Metal shaders and MTKView to render real-time ASCII effects without CPU text assembly or readback operations.

## Architecture

### Components

1. **GlyphAtlas** (`Sources/AsciiEngine/GlyphAtlas.swift`)
   - Runtime generation of r8Unorm texture from UIFont
   - Monochrome glyph atlas (white symbols on black background)
   - Configurable tile size and grid layout
   - Generated per-effect using `EffectType.characterSet`

2. **Metal Shaders** (`AsciiEngine.swift` - inlined source)
   - `previewVS`: Fullscreen triangle vertex shader
   - `previewFS`: Fragment shader with aspect-fill video sampling and atlas lookup
   - Supports luminance-based glyph selection, jitter, edge adjustment, and color mixing

3. **AsciiEngine** (`Sources/AsciiEngine/AsciiEngine.swift`)
   - Conforms to `MTKViewDelegate`
   - Public API:
     - `setupPreview(on:effect:)` - initializes GPU pipeline and generates atlas
     - `updatePreviewVideoTexture(_:)` - accepts camera frame as MTLTexture
     - `updatePreviewParameters(_:palette:effect:)` - updates render parameters
     - `draw(in:)` - renders frame via Metal (no CPU readback)
   - Maintains separate compute/CPU path for text export (`renderCapture`)

4. **MetalPreviewView** (`Sources/AsciiUI/Components/MetalPreviewView.swift`)
   - SwiftUI UIViewRepresentable wrapper for MTKView
   - Connects engine's MTKViewDelegate to SwiftUI view hierarchy

## Integration Points

### Current State (Build Successful, Integration Pending)

✅ **Completed:**
- GlyphAtlas runtime generation
- Metal shader compilation (inlined to avoid Metal Toolchain dependency)
- AsciiEngine GPU preview API and MTKViewDelegate implementation
- MetalPreviewView SwiftUI wrapper
- Text export path preserved (CPU/compute for `renderCapture`)
- iOS 14/15/16 availability fixes for UI components

❌ **Remaining Integration:**
- Replace `CameraPreviewContainer` text rendering with `MetalPreviewView`
- Connect `CameraService` → `PreviewPipeline` → `engine.updatePreviewVideoTexture`
- Wire up parameter/palette updates to `engine.updatePreviewParameters`

### Planned Integration Flow

```
CameraService (CVPixelBuffer)
    ↓
Convert to MTLTexture (via CVMetalTextureCache)
    ↓
engine.updatePreviewVideoTexture(texture)
    ↓
MTKView.draw(in:) triggered
    ↓
GPU renders fullscreen triangle with atlas sampling
```

## Performance Benefits

- **No CPU text assembly**: Eliminates large string allocations per frame
- **No GPU readback**: Preview rendering stays entirely on GPU
- **Aspect-fill in shader**: Video frame scaling happens in fragment shader
- **Dynamic grid**: Cell size computed in shader based on drawable size

## API Usage

### Setup (One-time)

```swift
let engine = AsciiEngine()
try engine.prepare(configuration: EngineConfiguration())
try engine.setupPreview(on: mtkView, effect: .ascii)
```

### Per-Frame Update

```swift
// From camera callback
let metalTexture = convertPixelBufferToTexture(pixelBuffer)
engine.updatePreviewVideoTexture(metalTexture)
// MTKView.draw(in:) automatically called
```

### Parameter Updates

```swift
engine.updatePreviewParameters(
    parameters,
    palette: palette,
    effect: selectedEffect
)
```

### Export (On Demand)

```swift
let frame = try await engine.renderCapture(
    pixelBuffer: pixelBuffer,
    effect: effect,
    parameters: parameters,
    palette: palette
)
// frame.glyphText contains ASCII string for saving
```

## Technical Details

### Shader Uniforms

```metal
struct PreviewUniforms {
    float2 targetSize;   // drawable dimensions
    float2 videoSize;    // camera frame dimensions
    uint2  cellSize;     // pixels per ASCII cell
    uint2  atlasGrid;    // atlas columns/rows
    float4 colorA;       // background color
    float4 colorB;       // foreground color
    float  edge;         // edge threshold (0..1)
    float  soft;         // smoothstep softness
    float  jitter;       // random variation (0..1)
    float  invert;       // invert luminance (0/1)
    float  time;         // animation seed
};
```

### Atlas Format

- Pixel format: `.r8Unorm`
- Layout: Grid of monochrome glyphs
- Sampling: Nearest-neighbor (for crisp edges)
- Generation: UIFont → CoreGraphics → Data → MTLTexture

### Fallback Strategy

Metal shaders are inlined as Swift string literals to avoid requiring the Metal Toolchain component. The engine attempts to load compiled `.metal` files first, then falls back to runtime compilation from source.

## Future Enhancements

1. **YUV Optimization**: Accept Y-plane directly (`.r8Unorm`) instead of BGRA for luminance calculation
2. **Gradient Support**: Per-line color interpolation in fragment shader (currently uses first gradient stop)
3. **Compute Pre-pass**: Optional compute shader for advanced effects before rasterization
4. **Multi-effect Compositing**: Blend multiple atlas layers in a single pass

## Testing

- Build succeeds on iOS 14+ (with availability guards)
- GPU preview infrastructure complete and tested via `setupPreview` API
- Text export path verified via existing `renderCapture` tests
- Integration tests pending camera texture connection

## References

- `AsciiEngine.swift` (lines 383-530): GPU preview setup and rendering
- `GlyphAtlas.swift`: Runtime atlas generation
- `MetalPreviewView.swift`: SwiftUI integration
- `previewShaderSource` (AsciiEngine.swift, lines 620-708): Metal shader source

