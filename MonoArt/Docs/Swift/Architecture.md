# Swift ASCII Camera — Architecture Plan

## Objectives
- Mirror the proven Android layering (UI, state, camera, engine) while embracing Swift and SwiftUI idioms.
- Keep effect parameters, gradients, and interaction flows identical so parity tests can reuse Android scenarios.
- Encapsulate Metal rendering so UI previews and still captures share the same ASCII pipeline with configurable quality tiers.

## High-Level Module Map
| Layer | Swift Module | Responsibilities | Android Source Parity |
| --- | --- | --- | --- |
| Presentation | `AsciiUI` (SwiftUI) | Screens, controls, animations, accessibility, modal routing | `FILES/SCREENS/MainScreen.md`, `FILES/COMPONENTS/*.md` |
| State & Actions | `AsciiDomain` | `ObservableObject` view models, `EffectType`, `EffectParams`, `ColorSelection` models, reducers/tests | `FILES/EFFECTS.md`, `FILES/INTERACTIONS.md` |
| Camera | `AsciiCamera` | `AVCaptureSession`, device switching, permissions, frame publishers | `app/src/.../camera` services (conceptual) |
| Rendering Engine | `AsciiEngine` | Grid planning, luminance sampling, glyph mapping, Metal kernels | `ASCIIENGINE_V2_INTEGRATION.md`, `ASCII_Engine_Analysis.md` |
| Support | `AsciiSupport` | Logging, configuration, DI wrappers, feature flags | Shared utils in Android project |

Each module is packaged as a Swift Package to enable isolated testing and reuse across app and previews.

> **Current status:** the Swift package now exposes dedicated targets `AsciiSupport`, `AsciiDomain`, `AsciiEngine`, `AsciiCamera`, `AsciiUI`, and an umbrella `AsciiCameraKit` target that re-exports them. UI components remain iOS-only for now while the Metal and camera layers ship with stub implementations pending Phase 1/2 work.

## Package & Target Structure
```
AsciiCameraKit.xcodeproj
├─ Packages
│  ├─ AsciiDomain
│  ├─ AsciiEngine
│  ├─ AsciiCamera
│  ├─ AsciiUI
│  └─ AsciiSupport
└─ App
   ├─ ASCIIApp (SwiftUI App entry point)
   └─ ASCIIAppTests
```
- `AsciiDomain` has no Apple-framework dependencies; it exposes models, reducers, and protocols consumed everywhere else.
- `AsciiEngine` depends on Metal & MetalKit; it imports `AsciiDomain` for effect parameters.
- `AsciiCamera` depends on AVFoundation & Combine; emits frames as `FrameEnvelope` objects consumed by `AsciiEngine`.
- `AsciiUI` depends on SwiftUI, Combine, `AsciiDomain`, `AsciiCamera`, and `AsciiEngine` to render the composed UI.

## Data & Event Flow
1. **Frame Intake:** `CameraService` publishes `FrameEnvelope` instances via Combine when new `CVPixelBuffer`s arrive.
2. **Rendering:** `PreviewPipeline` (in `AsciiCameraKit/App/PreviewPipeline.swift`) subscribes to camera frames, invokes `AsciiEngine.renderPreview`, and forwards the resulting `AsciiFrame` to `AppViewModel`.
3. **State Update:** `AppViewModel` (in `AsciiDomain`) listens to engine outputs, updates preview state, and forwards derived data to SwiftUI views.
4. **User Interaction:** SwiftUI controls send intents (e.g., `selectEffect`, `updateSlider`, `toggleGradient`) back to `AppViewModel`, which mutates state and notifies engine/camera services.
5. **Capture Pipeline:** When `capture` is invoked, `AsciiEngine` renders a high-resolution still using the same Metal kernels but larger grid size, then `MediaCoordinator` saves the output to Photos.

## Key Types & Protocols
- `EffectType`, `EffectParams`, `ColorPalette`: Codable structs/enums mirroring Kotlin definitions for consistent serialization tests.
- `AsciiFrame`: Provides optional `MTLTexture`, ASCII glyph text, and grid dimensions for UI layout.
- `CameraServiceProtocol`: Defines publishers for frames, methods to switch camera, pause/resume, and configure orientation.
- `AsciiEngineProtocol`: exposes async `renderPreview` / `renderCapture` receiving `EffectType`, `EffectParameters`, and `PaletteState`.
- `PreviewPipeline`: Bridges `CameraService` and `AsciiEngine`, delivering `AsciiFrame` updates to `AppViewModel`.
- `MediaCoordinatorProtocol`: `func save(frame: AsciiFrame, metadata: CaptureMetadata) async throws` to keep persistence isolated.

## SwiftUI Composition Blueprint
- `RootView` hosts `CameraPreviewContainer`, `ControlOverlay`, and the sheets. The current SwiftUI stub (see `SwiftStarterBundle/Sources/AsciiUI/RootView.swift`) already wires the capture banner and sheet presentation to `AppViewModel`.
- `CameraPreviewContainer` binds to `AsciiFrame` output and displays either a Metal view (via `MTKViewRepresentable`) or a glyph grid rendered as `Text` with monospace font, depending on performance tier. The interim implementation renders glyph text while Metal work is pending.
- `ControlOverlay` replicates three-button cluster and quick effect toggles. Animations reuse `withAnimation(.spring())` to mimic Compose transitions. The stub overlay currently calls into view-model methods to open sheets and simulate captures.
- `EffectSettingsSheet` and `ColorPickerSheet` correspond to Android bottom sheets, using `sheet` modifiers and accessible slider labels showing numeric values. Both files live under `SwiftStarterBundle/Sources/AsciiUI/Components/` and now enforce the gradient-only-on-symbols rule at the reducer layer (`AppViewModel`).

## Metal Engine Integration Points
- Create a shared `MTLDevice` and `MTLCommandQueue` in `AsciiEngine` and inject references where preview/capture views need them.
- Compile compute shaders (`asciiLuminanceKernel`, `asciiGlyphKernel`) and cache pipeline states during app launch.
- Use triple-buffered textures for preview frames; keep CPU/GPU synchronization minimal by reusing `MTLBuffer`s for luminance grids.
- Surface tuning knobs (`maxCellCount`, `jitterSeed`, `softyRadius`) as part of `EngineConfiguration`, reading defaults from `AsciiSupport` feature flags.

## Testing Strategy
- **Domain:** Unit tests verifying reducers clamp values 0–100, enforce foreground-only gradients, and emit intents identical to Android ViewModel tests (see `EffectsAndColors.md`).
- **Engine:** Metal shader tests using `MTLCommandBuffer` capture scopes; compare glyph outputs to reference ASCII bitmaps stored in test fixtures and benchmarks defined in `MetalEngine.md`.
- **Camera:** Simulated frame publisher backed by sample `CVPixelBuffer`s ensures UI previews update without hardware dependencies.
- **UI:** Snapshot tests via iOS 17 XCTest capturing `RootView` states (default, settings open, capture confirmation) following identifiers listed in `UIComponents.md`.
- **Integration:** Automated UI test flows mirroring `FILES/INTERACTIONS.md` scenarios to guarantee parity.

## Migration Checklist
High-level milestones remain embedded here for quick reference; detailed tracking lives in `MigrationChecklist.md`.
- [ ] Default effect loads with reveal animation and ASCII preset parameters.
- [ ] Switching effects propagates to engine within 1 frame (16 ms budget).
- [ ] Gradient toggle locks background picker and exposes symbol gradient editor only.
- [ ] Camera flip executes flip animation and updates preview orientation correctly.
- [ ] Capture flow saves photo to Photos and shows confirmation banner.

Consult `MigrationChecklist.md` for status, owners, and linked tests when updating these entries.
