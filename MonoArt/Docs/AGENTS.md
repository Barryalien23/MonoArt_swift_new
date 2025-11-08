# AGENTS.md — Swift Migration Documentation Scope

## Purpose
This folder contains guidance for porting the Android ASCII camera app to Swift/SwiftUI. When generating or modifying documentation or code under `SwiftStarterBundle/Docs/`, ensure parity with the established Android behavior.

## Required Reading Order
1. `SwiftStarterBundle/Docs/Swift/ProjectOverview.md` — Goals, feature parity, and user flows.
2. `SwiftStarterBundle/Docs/Swift/Architecture.md` — Module map, data flow, and testing plan.
3. `SwiftStarterBundle/Docs/Swift/EffectsAndColors.md` — Parameter semantics, gradient rules, and validation logic.
4. `SwiftStarterBundle/Docs/Swift/MetalEngine.md` — Compute pipeline, parameter mapping, and performance targets.
5. `SwiftStarterBundle/Docs/Swift/UIComponents.md` — SwiftUI component catalog, state contracts, and accessibility rules.
6. `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md` — Implementation progress tracker and testing matrix.
7. Android reference corpus in `FILES/` (including the archived root notes under `FILES/LegacyAndroidNotes/`):
   - `FILES/EFFECTS.md`
   - `FILES/COMPONENTS/*.md`
   - `FILES/SCREENS/MainScreen.md`
   - `FILES/INTERACTIONS.md`
   - `ASCIIENGINE_V2_INTEGRATION.md` and `ASCII_Engine_Analysis.md`

## Rules & Constraints
- Maintain the rule: gradients apply only to symbol glyphs; backgrounds remain solid colors.
- Preserve 0–100 slider ranges and display numeric values alongside sliders.
- Keep camera controls (import, capture, flip) always reachable on the main screen.
- Align new Swift guidance with Android interaction specs before introducing deviations.

## Deliverable Expectations
- Documentation must clearly map Android concepts to Swift equivalents.
- Include cross-references back to the Android docs whenever behavior parity is required.
- Highlight dependencies on AVFoundation, Metal, and SwiftUI where relevant.
- Update `SwiftStarterBundle/Docs/Swift/MigrationChecklist.md` alongside feature work to keep status accurate for future agents.
