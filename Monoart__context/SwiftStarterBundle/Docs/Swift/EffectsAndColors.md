# Swift ASCII Camera — Effects & Color Rules

## Purpose
Document the canonical parameters, constraints, and validation logic for porting the Android ASCII effects and color workflows to Swift. This file serves as the source of truth for the `AsciiDomain` models and any UI that manipulates effect values or color selection.

## Effect Catalog & Parameters
| Effect | Swift Identifier | Android Reference | Parameters | Notes |
| --- | --- | --- | --- | --- |
| ASCII | `.ascii` | `EffectType.ASCII` | `cell`, `jitter`, `edge`, `softy` | Default on launch; triggers reveal animation. |
| Shapes | `.shapes` | `EffectType.SHAPES` | `cell`, `jitter`, `softy` | Uses custom glyph atlas; edge slider hidden/disabled. |
| Circles | `.circles` | `EffectType.CIRCLES` | `cell`, `softy` | Renders filled circles; jitter kept but clamped to multiples of 5. |
| Squares | `.squares` | `EffectType.SQUARES` | `cell`, `edge` | Edge behaves as outline thickness. |
| Triangles | `.triangles` | `EffectType.TRIANGLES` | `cell`, `jitter` | Deterministic jitter seed per frame. |
| Diamonds | `.diamonds` | `EffectType.DIAMONDS` | `cell`, `softy`, `edge` | Edge drives diamond stroke weight. |

### Parameter Ranges
- All sliders expose the inclusive range **0–100** with integer precision.
- UI must show the numeric value beside the slider thumb and announce changes through VoiceOver/haptics.
- Clamp logic resides in `EffectParamsReducer` to guarantee consistent behavior between UI bindings and automated tests.

### Default Values
- `cell = 40`, `jitter = 20`, `softy = 10`, `edge = 30` when the effect supports the parameter.
- When switching effects, unsupported parameters retain their last values in state but sliders must hide/disable accordingly.
- A reset action restores default values for the currently selected effect while preserving color selections.

### Derived Behaviors
- Increasing `cell` reduces grid density; `AsciiEngine` must recompute grid planner outputs whenever this value changes.
- `jitter` introduces deterministic noise: use a shared `JitterNoise` utility seeded from `AppViewModel.jitterSeed` so previews and captures match.
- `softy` applies Gaussian blur before luminance sampling; non-supported effects treat the parameter as locked at 0.
- `edge` controls Sobel-like edge enhancement; UI disables it where not applicable, but the reducer stores last value for parity with Android state restoration.

## Color System Rules
### Layers
- **Background Layer:** Always a solid color (`Color`), persisted as RGBA in sRGB space.
- **Symbol Layer:** Supports either a solid color or a two-stop linear gradient (`GradientColorPair`). Direction is fixed (left-to-right) to mirror Android.

### Gradient Constraints
1. Gradients apply **only** to symbol glyphs—never to the background texture.
2. When the background layer is selected, gradient controls are hidden and the toggle is disabled.
3. Switching from gradient to solid reuses the first stop’s color for both stops.
4. Gradient colors are clamped to valid sRGB values and serialized as hex strings for parity with Android exports.

### Color Selection Workflow
- `ColorTarget` enum: `.background` or `.symbols`.
- UI indicates active target via focus ring and ensures background selection greys out gradient options.
- Color pickers must surface recently used colors and include accessible labels (WCAG contrast 4.5:1 for UI chrome).
- Persist selections across app relaunches via `UserDefaults` until a dedicated storage layer exists.

## Validation & Error States
- Attempts to apply a gradient to background should be rejected with a non-blocking toast/banner.
- Slider inputs outside 0–100 should log a warning and clamp silently.
- Engine failures due to invalid params should surface a fallback ASCII preset while logging diagnostics.

## Testing Guidance
- Unit tests mirror Android specs in `FILES/EFFECTS.md` ensuring parameter clamping and gradient restrictions.
- Snapshot tests cover: default ASCII preset, gradient-enabled symbols, and background-only solid mode.
- Integration tests replay scenarios from `FILES/INTERACTIONS.md`, verifying capture output retains chosen colors and parameters.

## Cross-References
- Android: `FILES/EFFECTS.md`, `FILES/COMPONENTS/ColorPickers.md`, `FILES/INTERACTIONS.md`.
- Swift docs: `UIComponents.md` for presentation requirements, `MetalEngine.md` for how parameters map to shaders.
