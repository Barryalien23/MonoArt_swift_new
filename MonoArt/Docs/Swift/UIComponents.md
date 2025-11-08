# Swift ASCII Camera — UI Component Catalog

## Overview
The UI layer mirrors the Android Compose structure while embracing SwiftUI idioms. All components consume data from `AppViewModel` (`ObservableObject`) and must preserve the same interaction rules: gradients apply only to foreground glyphs, slider ranges are 0–100, and camera controls remain always accessible.

## Screen Composition
- **RootView** — Hosts `CameraPreviewContainer`, `ControlOverlay`, and modals for effect settings and color management. Lives under `SwiftStarterBundle/Sources/AsciiUI/RootView.swift` and binds to `AppViewModel` via `@StateObject`.
- **AsciiCameraExperience** — High-level container in `SwiftStarterBundle/Sources/AsciiCameraKit/UI/AsciiCameraExperience.swift` that instantiates `RootView`, configures `PreviewPipeline`, and boots the live camera/engine stack when available.
- **CameraPreviewContainer** — Preview surface that renders the engine output as a glyph grid with per-line gradient coloring and accessibility labels. Accepts an `AsciiFrame` model, handles loading/permission states, and applies the introductory reveal animation on first frame.
  - Metal textures remain a Phase 3 task; the current SwiftUI implementation auto-sizes IBM Plex glyphs via geometry and provides a text fallback (`SwiftStarterBundle/Sources/AsciiUI/Components/CameraPreviewContainer.swift`).
- **ControlOverlay** — Horizontal cluster with three primary buttons (`Import`, `Capture`, `FlipCamera`) and quick effect shortcuts. Uses large tap targets (≥48pt) and spring animations to match Android behavior.
  - Buttons now announce VoiceOver hints, drive the live pipeline (import/capture/flip), and expose a share affordance once a capture succeeds.
- **EffectSettingsSheet** — Bottom sheet (via `sheet`) exposing parameter sliders with inline numeric labels. Includes segmented toggle for effects and real-time binding to `EffectParams`.
  - Implemented in `SwiftStarterBundle/Sources/AsciiCameraKit/UI/Components/EffectSettingsSheet.swift`; the sliders already clamp to 0–100 and reset to the defaults documented in `EffectsAndColors.md`.
- **ColorPickerSheet** — Presents solid color swatches and, when symbols are active, a gradient editor. Background selection disables gradient controls.
  - The SwiftUI form at `SwiftStarterBundle/Sources/AsciiCameraKit/UI/Components/ColorPickerSheet.swift` enforces symbol-only gradients and provides a two-stop editor expandable to four stops.
- **CaptureConfirmationBanner** — Temporary overlay that confirms save success or failure after a capture. Animated slide-in/out with accessible VoiceOver announcements.
  - Implemented banner sits in `SwiftStarterBundle/Sources/AsciiCameraKit/UI/Components/CaptureConfirmationBanner.swift` and reuses the success copy from Android.
- **SettingsHandle** — Drag handle on the overlay that opens the effect sheet; implemented as `SwiftStarterBundle/Sources/AsciiCameraKit/UI/Components/SettingsHandle.swift`.

## Component Reference
| Component | SwiftUI Type | Responsibilities | State Inputs | User Actions |
| --- | --- | --- | --- | --- |
| `CameraPreviewContainer` | `View` wrapping glyph-grid fallback (Metal texture pending) | Render live ASCII frame with per-line gradients, apply reveal animation, handle permissions & loading indicator | `AppViewModel.previewFrame`, `AppViewModel.previewStatus`, `PaletteState` | Tap to focus (future), respond to orientation updates |
| `ControlOverlay` | `View` | Show primary camera buttons and quick effect chips, reflect disabled states | `AppViewModel.selectedEffect`, `AppViewModel.isCaptureInFlight` | `importTapped`, `captureTapped`, `flipCameraTapped`, `selectEffect`, `openColors` |
| `EffectSettingsSheet` | `View` in sheet | Allow slider adjustments (Cell, Jitter, Softy, Edge), enforce 0–100 limits, display numeric labels, provide effect picker | `AppViewModel.parameters`, `AppViewModel.selectedEffect` | `setSliderValue`, `setEffect`, `resetDefaults` |
| `ColorPickerSheet` | `View` in sheet | Manage background vs. symbol selection, show gradient editor only when symbols selected, reflect disabled state icons | `PaletteState`, `AppViewModel.selectedColorTarget`, `AppViewModel.symbolGradientStops` | `selectColorTarget`, `setSolidColor`, `toggleGradient`, `editGradientStop` |
| `CaptureConfirmationBanner` | `View` | Display save success/failure with timer-based auto-dismiss | `AppViewModel.captureStatus` | Auto-dismiss timer restart |
| `SettingsHandle` | `View` | Drag handle to open settings sheet from overlay | n/a | `openSettings` |

## Interaction Contracts
- **Slider Feedback** — Each slider must show live value (0–100) beside the thumb and provide haptic feedback on major ticks (multiples of 10).
- **Effect Switching** — Selecting a new effect triggers `AppViewModel.selectEffect`, updates Metal parameters, and plays a subtle crossfade animation.
- **Color Workflow** — Switching to background immediately disables gradient toggle and greys out secondary color slots. Symbol selection re-enables gradient editing with deterministic preview updates.
- **Camera Flip** — Button triggers flip animation on preview (3D rotation) and swaps `CameraService` device; state must block re-entry until completion.
- **Capture Flow** — Capture button enters loading state, disables other controls, and shows `CaptureConfirmationBanner` (with optional share action) once `captureStatus` resolves.

## Accessibility & Layout Rules
- Primary buttons ≥56pt, slider knobs ≥44pt diameter, text uses SF Mono for glyph previews.
- Support Dynamic Type by scaling fonts and spacing while keeping glyph grid aligned.
- Provide VoiceOver labels describing effect names, slider values, and gradient status.
- Ensure contrast ratios meet WCAG 4.5:1 for UI chrome regardless of selected theme colors.

## Dependencies & Assets
- Uses shared icon set (`Assets.xcassets`) mirroring Android glyphs.
- Relies on `AsciiEngine` preview textures; falls back to text rendering when Metal unavailable.
- Requires `HapticFeedbackClient` (in `AsciiSupport`) for slider haptics and capture confirmations.

## Implementation Hooks & State Mapping
- **View Model Contracts:** Each component binds to intents defined in `AppViewModel` (`selectEffect`, `updateSlider`, `toggleGradient`, `capture`). Keep method names aligned with reducers documented in `MigrationChecklist.md` so UI and domain evolve together.
- **Environment Wiring:** Inject `AppViewModel` via `@StateObject` at the root and pass references using `@EnvironmentObject` to nested sheets/overlays. This matches the Compose pattern of hoisting state.
- **Preview Synchronization:** `CameraPreviewContainer` observes `AppViewModel.previewFrame` updates and forwards configuration changes (cell size, gradient colors) to Metal via `AsciiEngine` bindings described in `MetalEngine.md`.
- **Accessibility Pipeline:** Reuse localized strings and numeric formatting helpers from `AsciiSupport` to guarantee VoiceOver parity with Android’s content descriptions.
- **Testing Hooks:** Snapshot identifiers (e.g., `RootView_default`, `EffectSheet_softyMax`) are declared here to keep UI tests traceable to entries in `MigrationChecklist.md`.

## Android Cross-References
When generating Swift components, review the matching Compose specs for parity:
- `FILES/SCREENS/MainScreen.md` — Layout composition and modal behavior.
- `FILES/COMPONENTS/CameraControls.md` — Button grouping, disabled states, animations.
- `FILES/COMPONENTS/EffectSettings.md` — Slider rules, numeric display, parameter mapping.
- `FILES/COMPONENTS/ColorPickers.md` — Foreground/background logic, gradient constraints.
- `FILES/INTERACTIONS.md` — Event sequences for capture, color changes, and effect switching.
