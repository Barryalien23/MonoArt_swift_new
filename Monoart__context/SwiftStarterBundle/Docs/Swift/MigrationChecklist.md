# Swift ASCII Camera — Migration Checklist & Testing Matrix

This document turns the high-level architecture plan into actionable milestones with traceable test coverage. Update the tables as features are implemented to maintain parity with the Android release.

## Legend
- ✅ Complete
- 🚧 In progress
- ⏳ Blocked / pending dependency

## Domain & State
| Item | Status | Notes | Tests |
| --- | --- | --- | --- |
| Bootstrap Swift Package scaffolding | ✅ | `Package.swift` + SwiftPM targets set up for Xcode integration | `swift test` smoke test |
| Mirror `EffectType`, `EffectParams`, `ColorPalette` models | ✅ | Swift definitions shipped with defaults matching `EffectsAndColors.md`; clamp behavior covered by `EffectParametersTests` | `swift test` (`EffectParametersTests`) |
| Implement `AppViewModel` with published state + intent methods | ✅ | Reducer now drives live preview/capture lifecycle, gradient enforcement, and parameter normalization (`SwiftStarterBundle/Sources/AsciiDomain/AppViewModel.swift`) | `AppViewModelTests`, `PreviewPipelineTests.testParameterChangeTriggersReRender` |
| Persist color selections between launches | ⏳ | Temporary `UserDefaults` storage | Unit tests using `UserDefaults` suite |

## UI Layer
| Item | Status | Notes | Tests |
| --- | --- | --- | --- |
| Build `RootView` composition (preview + overlays) | 🚧 | `CameraPreviewContainer` now renders glyph grids with per-line gradient coloring and accessibility labels; overlay buttons invoke live pipeline actions (`SwiftStarterBundle/Sources/AsciiUI/RootView.swift`) | Snapshot tests (`RootView_default`), `PreviewPipelineTests` |
| Implement `EffectSettingsSheet` with parameter gating | 🚧 | Sheet implemented under `UI/Components`, gating matches supported params | Snapshot + accessibility tests |
| Implement `ColorPickerSheet` gradient workflow | 🚧 | Gradient editor enforces symbol-only rule; supports up to four stops | UI tests verifying disabled states |
| Control overlay interactions (import/capture/flip) | 🚧 | Overlay surfaces VoiceOver hints, drives import/capture/flip intents, and exposes share entry point | UI automation following `INTERACTIONS.md`, `PreviewPipelineTests.testCaptureInvokesOnCaptureSuccessCallback` |

## Camera & Engine
| Item | Status | Notes | Tests |
| --- | --- | --- | --- |
| Set up `AVCaptureSession` with front/back switching | 🚧 | `CameraService` handles device swaps & orientation updates; animation polish pending | Integration test with mock camera |
| Integrate `AsciiEngine` preview pipeline | 🚧 | Preview pipeline streams camera/import frames into engine and re-renders on parameter changes | Performance benchmark (<16 ms) |
| Implement capture path with high-res output | ✅ | `PreviewPipeline.capture()` renders 2K glyph bitmap and saves via `PhotosMediaCoordinator` | `PreviewPipelineTests.testCaptureUsesEngineAndMediaCoordinator` |
| Handle Metal unavailable fallback | ⏳ | Provide text-only render path | Snapshot tests on simulator without Metal |

## Persistence & Sharing
| Item | Status | Notes | Tests |
| --- | --- | --- | --- |
| Save captures to Photos library | ✅ | `PhotosMediaCoordinator` writes captures post-authorization | `PreviewPipelineTests.testCaptureUsesEngineAndMediaCoordinator` |
| Import images via `PhotosPicker` | 🚧 | `AsciiCameraExperience` loads `PhotosPickerItem` into pipeline; add UI automation coverage | UI test covering import → effect change |
| Share exports via `ShareLink` | 🚧 | Interim share sheet presents captured image; evaluate migration to `ShareLink` | Manual QA checklist |

## Cross-Cutting Requirements
| Item | Status | Notes | Tests |
| --- | --- | --- | --- |
| Accessibility labels & Dynamic Type support | ⏳ | Documented in `UIComponents.md` | VoiceOver automation scripts |
| Gradient-only symbols enforcement | ✅ | Reducer + color sheet guard rails enforced; preview renders gradients per line | `AppViewModelTests`, manual QA of `CameraPreviewContainer` |
| Performance parity with Android (fps, capture time) | ⏳ | Targets defined in `MetalEngine.md` | Performance suite + manual QA |

## Test Plan Summary
- **Unit Tests:** Focus on reducers, color validation, and parameter mapping.
- **Snapshot Tests:** Cover major UI states (default, settings expanded, gradient edit, capture confirmation).
- **Integration Tests:** Simulate flows from `FILES/INTERACTIONS.md` including camera flip, parameter adjustments, and photo capture.
- **Performance Benchmarks:** Measure preview frame time, capture latency, and memory footprint under maximum cell density.
- **Manual QA:** Validate accessibility, color accuracy, and Photos permissions handling on actual devices.

## Reporting
Track progress in project management tools by linking checklist items to Git commits/PRs. Include references to Android documents whenever a parity decision is recorded, and update this matrix alongside implementation to keep the migration roadmap current.
