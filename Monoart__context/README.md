# 📸 ASCII Camera — Swift Migration Workspace

This repository now serves as the staging area for porting the Android ASCII Camera app to SwiftUI and Metal. The legacy Kotlin source has been archived under `FILES/` as reference material, while the Swift package scaffold inside `SwiftStarterBundle/` provides a drop-in starting point for the new implementation.

## 🎯 Goals
- Recreate the Android experience (effects, sliders, gradients, camera controls) with a native SwiftUI interface.
- Implement the ASCII/shape rendering pipeline on top of Metal, matching the behavior documented in the Android engine.
- Maintain feature parity by mirroring models, workflows, and constraints captured in the Android specifications.

## 📁 Repository Layout
| Path | Description |
| ---- | ----------- |
| `SwiftStarterBundle/` | Self-contained SwiftPM workspace ready to be copied into an Xcode project. |
| `SwiftStarterBundle/Docs/Swift/` | Migration guides covering architecture, effects/colors, Metal design, UI catalog, and project checklist. |
| `SwiftStarterBundle/Sources/AsciiCameraKit/` | Swift Package containing domain models, an expanded `AppViewModel`, and SwiftUI component stubs (`RootView`, `CameraPreviewContainer`, `ControlOverlay`, etc.). |
| `SwiftStarterBundle/Tests/AsciiCameraKitTests/` | XCTest targets demonstrating how to validate shared logic (e.g., parameter clamping). |
| `FILES/` | Frozen Android documentation corpus required for parity decisions. Archived root notes now live in `FILES/LegacyAndroidNotes/`. |
| `SwiftStarterBundle/Docs/AGENTS.md`, `AGENTS.md` | Agent guidance that defines required reading order and non-negotiable UX rules (gradient only on symbols, 0–100 sliders, etc.). |
## 🚀 Getting Started
1. Install Xcode 15 or newer (Swift 5.9+).
2. Open the Swift starter bundle directly in Xcode:
   ```bash
   open SwiftStarterBundle/Package.swift
   ```
3. Run the placeholder unit tests to verify the toolchain:
   ```bash
   swift test --package-path SwiftStarterBundle
   ```
4. Follow `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md` to progress through the domain, UI, camera, and engine milestones.

## 📚 Documentation Workflow
Read the Swift documentation set in the prescribed order (see `AGENTS.md`). Each document calls back to the Android specs in `FILES/` when behavior must stay identical. Update the checklist alongside code changes so future contributors and tooling can see migration status at a glance.

## 🧩 Android Reference Snapshot
The Android implementation no longer builds inside this repository, but the Kotlin source and behavioral notes remain in `FILES/`, `ASCIIENGINE_*`, and related markdown files. Use them to confirm effect semantics, camera flows, and edge cases whenever adding Swift code.

## 🔮 Next Steps
- Expand the Swift package with dedicated modules for camera capture and Metal kernels; the SwiftUI scaffolding in `SwiftStarterBundle/Sources/AsciiCameraKit/UI/` is ready to host them.
- Continue porting reducer logic from the Android `MainViewModel` into `AppViewModel`, wiring in camera/engine publishers while keeping gradients symbol-only and sliders numeric.
- Implement preview and capture pipelines per `SwiftStarterBundle/Docs/Swift/MetalEngine.md`, adding performance instrumentation to meet the frame-time targets outlined there.

Refer to `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md` for task-level tracking and required testing coverage.
