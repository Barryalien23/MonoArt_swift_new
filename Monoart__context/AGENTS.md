# AGENTS.md — Repository-Wide Guidance

## Mission
This repository tracks the migration of the Android ASCII Camera app to a native Swift/SwiftUI implementation. Follow the documentation set under `SwiftStarterBundle/Docs/Swift/` and the Android reference corpus in `FILES/` to maintain feature parity while replacing the platform-specific codebase.

## Required Reading Sequence
1. `SwiftStarterBundle/Docs/Swift/ProjectOverview.md`
2. `SwiftStarterBundle/Docs/Swift/Architecture.md`
3. `SwiftStarterBundle/Docs/Swift/EffectsAndColors.md`
4. `SwiftStarterBundle/Docs/Swift/MetalEngine.md`
5. `SwiftStarterBundle/Docs/Swift/UIComponents.md`
6. `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md`
7. Android specs in `FILES/` (`EFFECTS.md`, `COMPONENTS/`, `SCREENS/`, `INTERACTIONS.md`) plus the archived notes now grouped in `FILES/LegacyAndroidNotes/`.

## Rules & Constraints
- Preserve Android behavior: gradients belong to symbol glyphs only, sliders remain 0–100 with visible numeric labels, and camera controls stay accessible.
- When removing legacy Android build files, ensure reference documentation in `FILES/` remains intact for parity checks.
- Keep migration status current by updating `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md` and linking commits/PRs to checklist items.
- Reference Metal and AVFoundation dependencies explicitly when adding engine or camera guidance.

## Deliverable Expectations
- Documentation changes must cite corresponding Android sources when behavior parity is enforced.
- Swift code or stubs should live under future Swift-specific directories (e.g., `Sources/`, `AsciiCameraKit/`) rather than Android module paths.
- Before code generation tasks, verify that the Swift docs plus Android references provide enough context; update them if gaps are discovered.
