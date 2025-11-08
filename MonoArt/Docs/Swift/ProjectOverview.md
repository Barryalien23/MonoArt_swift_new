# Swift ASCII Camera — Project Overview

## Purpose
- Rebuild the existing Android ASCII Camera experience natively for iOS using Swift, SwiftUI, AVFoundation, and Metal.
- Preserve signature functionality: real-time camera preview, ASCII/shape-based effects, and granular control over effect parameters (Cell, Jitter, Softy, Edge) within a 0–100 range.
- Keep UX constraints from the Android version, including gradient-only symbol coloring, dedicated camera controls, and accessible slider interactions.

## Target Platforms & Tooling
- **Platforms:** iOS 17+ and iPadOS 17+ (Apple Silicon simulators and physical devices with A12 or newer recommended).
- **Languages & Frameworks:** Swift 5.9+, SwiftUI for UI composition, Combine for reactive state, AVFoundation for camera access, Metal for compute-based ASCII rendering, PhotosUI for saving and gallery integration, CoreImage for preprocessing steps.
- **Project Structure:** Modular Xcode workspace with layers `Domain`, `Engine`, `Camera`, `UI`, and `Support` mirroring the separation used in the Android project.

## Feature Parity Goals
- **Camera Preview:** Instant live feed, default ASCII effect active on launch, with an introductory "effect reveal" animation.
- **Effect Suite:** Six base effects (ASCII, Shapes, Circles, Squares, Triangle, Diamonds) with deterministic parameter handling identical to the Kotlin models.
- **Color System:** Solid background color; foreground symbols support either a solid color or a fixed-direction linear gradient. Gradients must never be applied to the background layer.
- **User Controls:** Three primary buttons (import photo, capture, switch camera), slider-based parameter editing with visible numeric labels, and color pickers reflecting current selections.
- **Media Operations:** Capture high-resolution stills without borders, save to Photos library, and allow importing external images for conversion.

## Core User Flows
1. **Launch & Preview** – Request permissions, start camera session, run default ASCII effect animation.
2. **Tune Effects** – Open settings sheet, adjust sliders (Cell, Jitter, Softy, Edge) while clamping values 0–100 and updating preview in real time.
3. **Color Selection** – Toggle between background and symbol layers, choose solid colors or gradients for symbols, with disabled state visuals when unset.
4. **Capture & Save** – Trigger snapshot pipeline, render ASCII frame via Metal compute, compose with selected colors, write to Photos, confirm success state.
5. **Camera Switching & Import** – Flip between front/back cameras with flip animation; open photo picker, process selected image through the ASCII pipeline.

## System Components Overview
- **State Management (`AppViewModel`):** Swift `ObservableObject` mirroring `MainUiState`, with published properties for selected effect, parameter set, color configuration, camera status, and modal visibility.
- **Rendering Engine (`SKAsciiEngine`):** Metal-based pipeline inspired by `ASCIIEngineV2`: grid planning, luminance sampling, palette mapping, and ASCII glyph selection. Should expose async APIs for live preview and still capture.
- **Camera Layer (`CameraService`):** Encapsulates `AVCaptureSession`, device selection, orientation handling, and integration with SwiftUI preview surfaces.
- **UI Layer:** SwiftUI scenes replicating `MainScreen` composition—camera preview background, overlayed control bar, modal sheets for settings and color pickers, with accessibility-first sizing and numeric value readouts.
- **Persistence & Sharing:** Use `Photos`/`PhotosUI` for saving captures, `ShareLink` for exports, and local caching for quick gallery previews if needed.

## Android Reference Corpus for AI Context
To help large language models replicate existing behavior, surface these Kotlin-focused documents as source-of-truth references when generating Swift equivalents:
- `FILES/EFFECTS.md` — Canonical effect definitions, parameter names, and ranges.
- `FILES/COMPONENTS/*.md` — UI component contracts, required states, and interaction notes for sliders, pickers, and buttons.
- `FILES/SCREENS/MainScreen.md` — Layout blueprint for the combined camera, settings, and control overlays.
- `FILES/INTERACTIONS.md` — Event flows covering effect switching, color application, and capture lifecycle.
- `ASCIIENGINE_V2_INTEGRATION.md` & `ASCII_Engine_Analysis.md` — Engine architecture, grid planning strategy, and performance constraints that must be preserved.

These files should accompany the Swift documentation set so the model retains full context of legacy behavior while drafting iOS-specific implementations.

## Deliverables & Next Steps
- Finalize architecture diagrams and component contracts (see `Architecture.md`).
- Prototype Metal rendering pipeline to validate ASCII fidelity and performance targets.
- Draft migration checklist covering parity of every Android interaction and effect (see `MigrationChecklist.md`).
- Coordinate documentation for effects/color handling (`EffectsAndColors.md`), UI catalog (`UIComponents.md`), Metal guidance (`MetalEngine.md`), and keep them referenced in `Docs/AGENTS.md` for future contributors.
