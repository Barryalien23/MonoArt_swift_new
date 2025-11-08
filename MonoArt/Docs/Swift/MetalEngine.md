# Swift ASCII Camera — Metal Engine Blueprint

## Goals
- Recreate Android's `ASCIIEngineV2` behavior using Metal compute shaders while supporting both live previews and high-resolution captures.
- Maintain identical parameter semantics (Cell/Jitter/Softy/Edge) and gradient handling defined in `EffectsAndColors.md`.
- Provide clear integration points for `AsciiUI`, `AsciiDomain`, and `AsciiCamera` modules.

## Pipeline Overview
1. **Frame Intake**
   - Receive `FrameEnvelope` containing `CVPixelBuffer`, timestamp, orientation, and effect metadata.
   - Convert to `MTLTexture` via `CVMetalTextureCache`; if Metal is unavailable (e.g. CI), fall back to `CIContext` software rendering using the same entry point.
2. **Preprocessing**
   - `GridPlanner` maps the `cell` slider to preview/capture density while respecting configuration caps (18k / 64k cells by default).
   - Soft blur (`softy`) currently applies an iterative box blur on the luminance grid, matching Android behaviour without introducing an extra shader stage yet.
3. **Luminance Sampling**
   - Compute kernel `asciiLuminanceDownsample` averages each cell’s luminance and writes to a shared buffer.
   - CPU fallback path renders the frame to the grid resolution with `CIContext.render` and derives luminance per pixel, ensuring deterministic output when GPUs are missing.
4. **Glyph Mapping**
   - Swift-side mapper converts luminance to glyphs using `GlyphAtlas` character sets that mirror Android (ASCII / Shapes / Circles / Squares / Triangles / Diamonds).
   - Edge slider applies contrast stretching before lookup; jitter seeds a deterministic PRNG so preview/capture parity is preserved.
5. **Output Composition**
   - `AsciiFrame` currently exposes glyph text and grid dimensions while we validate performance; Metal texture overlays will arrive alongside the glyph atlas render path in Phase 3.

## Key Types
- `struct EngineConfiguration`: `maxPreviewCells`, `maxCaptureCells` (JSON-configurable via `AsciiSupport`).
- `final class AsciiEngine`: owns `MTLDevice`, `MTLCommandQueue`, compute pipeline state, `CIContext` fallback, and seeded RNG.
- `struct AsciiFrame`: exposes `glyphText`, optional `MTLTexture` placeholder, plus `columns` / `rows` for UI layout.
- `protocol AsciiEngineProtocol`: async `renderPreview` / `renderCapture` methods receiving `EffectType`, `EffectParameters`, and `PaletteState`.

## Parameter Mapping
| Parameter | Metal Usage |
| --- | --- |
| `cell` | Drives `GridPlanner` density while honouring preview/capture caps and device aspect ratio. |
| `jitter` | Seeds deterministic PRNG and offsets glyph indices up to ±(glyphCount/4) at slider max. |
| `softy` | Applies 1–3 iterations of box blur over the luminance grid (scaled by slider). |
| `edge` | Performs contrast stretching around 0.5 mid-point before glyph lookup. |

Gradients from `ColorPalette` supply two RGBA colors and interpolation weights; direction is fixed horizontal.

## Threadgroup & Performance Targets
- Preview dispatch uses adaptive threadgroup sizes based on pipeline execution width; test target remains ≤16 ms per frame on A14+.
- Capture path reuses the same kernel with larger grids; run on a serial queue to keep UI scheduling predictable.
- Shared `MTLBuffer` allocations persist between frames; CPU fallback keeps frame time under 25 ms for CI environments.

## Error Handling
- If Metal is unavailable, fall back to CPU-based glyph rendering using precomputed luminance (retain identical parameter behavior).
- On kernel failure, emit `AsciiEngineError` and surface fallback ASCII frame with default parameters.

## Testing Strategy
- Shader unit tests using `MTLCommandBuffer` capture to validate luminance averages vs. Android golden data.
- Integration tests comparing glyph output histograms with Android reference bitmaps.
- Performance benchmarks executed via `XCTestCase` measuring frame time under maximum grid density.

## Integration Checklist
- [ ] Initialize `AsciiEngine` during app launch and inject into `AppViewModel`.
- [ ] Supply `EngineConfiguration` from `AsciiSupport` (read from JSON/plist) to keep tuning central.
- [ ] Ensure `ColorPalette` updates propagate to Metal uniforms within one frame.
- [ ] Mirror Android’s capture post-processing (e.g., overlay camera metadata if applicable).

## Cross-References
- Android documentation: `ASCIIENGINE_V2_INTEGRATION.md`, `ASCII_Engine_Analysis.md`.
- Swift documentation: `Architecture.md` for module boundaries, `EffectsAndColors.md` for parameter semantics.
