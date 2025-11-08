# SwiftStarterBundle

This directory packages the SwiftPM workspace that should be copied into an Xcode project or shared with an LLM when generating Swift code. It collects every file required for the iOS migration while keeping the Android corpus in the repository root as reference material.

## Contents
- `Package.swift` — Defines the `AsciiCameraKit` Swift package.
- `Sources/AsciiCameraKit/` — Domain models, `AppViewModel`, SwiftUI scaffolding, and resource placeholders aligned with the Android behavior.
- `Tests/AsciiCameraKitTests/` — XCTest targets validating effect defaults, parameter clamping, and gradient enforcement.
- `Docs/Swift/` — Migration documentation set (overview, architecture, effects/colors, Metal pipeline, UI catalog, and checklist).
- `Docs/AGENTS.md` — Documentation-scope agent guidance that enforces reading order and parity rules.

## Usage
1. Open the package in Xcode:
   ```bash
   open SwiftStarterBundle/Package.swift
   ```
2. Run the tests from the repository root or any workspace by pointing SwiftPM at this directory:
   ```bash
   swift test --package-path SwiftStarterBundle
   ```
3. When prompting an LLM, provide this folder (plus the Android references under `FILES/` if behavioral parity is needed) to ensure the agent reads the authoritative Swift guidance first.

## Copying into Another Project
- To integrate with an existing Xcode workspace, drag `SwiftStarterBundle` into the workspace and enable “Create folder references”.
- Alternatively, move the contents of this folder into your project root and run `swift package init --type library` to regenerate project files tailored to your app, using the bundled sources and docs as the baseline.

