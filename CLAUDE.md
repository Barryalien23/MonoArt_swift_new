# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Open the project in Xcode
open MonoArt.xcodeproj

# Build from command line
xcodebuild -project MonoArt.xcodeproj -scheme MonoArt -configuration Debug

# Run tests
xcodebuild test -project MonoArt.xcodeproj -scheme MonoArt -destination 'platform=iOS Simulator,name=iPhone 15'

# Swift Package tests (for AsciiCameraKit)
swift test --package-path MonoArt/Packages/AsciiCameraKit
```

### Quick Start
```bash
# Launch in Xcode and run
cd /Users/barryalien/Documents/code/MonoArt
open MonoArt.xcodeproj
# Then press ⌘+R to run
```

## Architecture Overview

MonoArt is an iOS app that converts camera feed to ASCII art in real-time using GPU-accelerated rendering. The app uses a modular Swift Package architecture with the main logic contained in `AsciiCameraKit`.

### Core Architecture

**AsciiCameraKit Package Structure:**
- **AsciiCameraKit** (main) - Top-level coordination and pipeline management
- **AsciiEngine** - Core ASCII rendering engine with Metal GPU support  
- **AsciiDomain** - Domain models and view models
- **AsciiUI** - SwiftUI components and design system
- **AsciiCamera** - Camera service and frame capture
- **AsciiSupport** - Logging and utilities

### Key Components

**Preview Pipelines:**
- `GPUPreviewPipeline` - Real-time 60fps Metal rendering (primary)
- `PreviewPipeline` - Text-based fallback for unsupported devices

**Core Engine:**
- `AsciiEngine` - Main rendering engine with GPU and CPU methods
- `GlyphAtlas` - Runtime texture atlas generation for character sets
- Metal shaders for real-time preview rendering

**UI System:**
- `AsciiCameraExperience` - Main camera interface
- `MetalPreviewView` - SwiftUI wrapper for MTKView
- `RootView` - Conditional GPU/Text preview rendering

### Rendering Flow

1. **GPU Preview (Primary)**: Camera → CVPixelBuffer → MTLTexture → Metal Fragment Shader → 60fps display
2. **Text Fallback**: Camera → ASCII processing → SwiftUI Text rendering
3. **Capture**: Always uses CPU path for high-quality text output to Photos

### Effect System

The app supports multiple ASCII effect types:
- ASCII (`.:-=+*#%@`)
- Blocks (`░▒▓█`) 
- Braille patterns
- Dense extended ASCII
- Minimal (`. '`)
- Numeric (`0-9`)

Parameters include cell size, edge threshold, soft edges, and jitter for customization.

## Development Notes

### GPU Preview Requirements
- iOS 15.0+ minimum
- Metal-compatible device
- Automatically falls back to text rendering if GPU unavailable

### Testing
- Main app tests: `MonoArtTests/`
- Package tests: Available via Swift Package Manager
- UI tests: `MonoArtUITests/`

### Performance Targets
- GPU Preview: 60 FPS, <15% CPU, ~20-30% GPU
- Memory usage: ~50-80 MB
- Fallback text preview: 15-30 FPS

### Key Files to Understand

**Core Pipeline:**
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiCameraKit/App/GPUPreviewPipeline.swift`
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiEngine/AsciiEngine.swift`

**UI Entry Points:**
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiCameraKit/UI/AsciiCameraExperience.swift`
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiUI/RootView.swift`

**Metal Rendering:**
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiUI/Components/MetalPreviewView.swift`
- `MonoArt/Packages/AsciiCameraKit/Sources/AsciiEngine/Shaders/` (Metal shaders)

## Dependencies

- **PocketSVG** (2.8.0) - SVG rendering for icons
- **Metal** - GPU rendering framework
- **AVFoundation** - Camera capture
- **SwiftUI** - Modern UI framework

---

## Visual Architecture & UI System

### Screen Hierarchy

```
AsciiCameraExperience (Main Entry Point)
├── Pipeline Management
│   ├── GPUPreviewPipeline (Metal GPU rendering)
│   └── PreviewPipeline (Text-based fallback)
├── Photo Picker Integration
└── RootView (UI Container)
    ├── Background Layer
    │   ├── previewImage (imported photo)
    │   ├── MetalPreviewView (GPU) OR CameraPreviewContainer (CPU)
    │   └── Loading/Error states
    ├── Header Toolbar
    │   ├── GalleryPreviewButton (last saved image)
    │   └── Help IconButton
    ├── Effect Selection Sheet (Modal)
    ├── Settings Sheet (Modal)
    ├── Color Picker Sheet (Modal)
    └── Bottom Control Overlay
        ├── DesignActionBar
        ├── Effect tile
        ├── Parameter tiles (Cell, Jitter, Contrast)
        └── Color tiles (BG, Symbol, Gradient)
```

### RootView Layer Structure

**File**: `AsciiUI/RootView.swift` (Lines 9-343)

RootView uses ZStack for layered composition:

1. **Background Layer** (Lines 48-82):
   - GPU Metal preview or CPU text preview
   - Import loading state handling

2. **Header Layer** (Lines 84-88):
   - `topToolbar()` with gallery button and help icon
   - Safe area aware positioning (80pt top for notch devices, 36pt for older)

3. **Bottom Controls** (Lines 91-125):
   - EffectSelectionView or ControlOverlay (state-dependent)
   - Dynamic padding based on safe area insets

### Camera Preview Components

| Component | File | Description |
|-----------|------|-------------|
| MetalPreviewView | `MetalPreviewView.swift:8-26` | UIViewRepresentable wrapping MTKView, 60fps |
| CameraPreviewContainer | `CameraPreviewContainer.swift:7-168` | Text-based fallback with gradient support |
| GPUCameraPreviewContainer | `GPUCameraPreviewContainer.swift:9-65` | Metal wrapper with status overlay |

### Control Overlay

**File**: `ControlOverlay.swift` (Lines 17-294)

**Structure**:
- **Action Bar**: Import, Capture/Save, Flip Camera/Delete
- **Settings Grid**:
  - Left: Effect Tile (64×120pt)
  - Right: Parameter tiles (Cell, Jitter, Contrast) + Color tiles (BG, Symbol, Gradient)

**Modes**:
- `camera`: Normal capture mode with flip camera button
- `import`: Photo import mode with delete button

### Modal Sheets

| Sheet | File | Purpose |
|-------|------|---------|
| EffectSelectionView | `EffectSelectionView.swift:6-136` | Horizontal scrollable effect tiles, 152pt height |
| EffectSettingsSheet | `EffectSettingsSheet.swift:6-122` | Segmented effect selector + parameter sliders |
| ColorPickerSheet | `ColorPickerSheet.swift:9-259` | Preset colors + custom picker + gradient editor |

---

## Design System

### Design Tokens

**File**: `DesignTokens.swift` (Lines 8-35)

**Colors**:
```swift
mainGrey:   #1A1A1A (0.102, 0.102, 0.102)
greyActive: #151515 (0.145, 0.145, 0.145)
greyDisable:#141414 (0.08, 0.08, 0.08)

// White opacity variants
white60, white40, white20, white12, white08, white04
```

**Spacing Scale**:
```
zero(0) | xxs(2) | xs(3) | s(4) | sm(6) | md(8) | lg(10) | base(12) | xl(16) | xxl(20)
```

**Corner Radius**:
```
sm(8) | md(12) | lg(16) | xl(20)
```

### Typography

**Font**: IBM Plex Mono (custom registered via `FontRegistrar.swift`)

| Style | Size | Weight | Line Height |
|-------|------|--------|-------------|
| body1 | 12pt | medium | 16pt, UPPERCASE |
| body2 | 12pt | semibold | 16pt, UPPERCASE |
| head1 | 14pt | semibold | 18pt, UPPERCASE |

### Surface Styles

**File**: `DesignSurface.swift` (Lines 42-101)

| Style | Radius | Border | Fill |
|-------|--------|--------|------|
| glassButton | 16pt | 1.5pt white20 | ultraThinMaterial + white8 |
| glassTile | 12pt | 1pt white8 | mainGrey + white4 |
| glassCard | 20pt | 1pt white12 | ultraThinMaterial + white8 |

### Shadow System
```
block: radius 16, y: -30, opacity 0.3
knob:  radius 3,  y: 0,   opacity 0.1
blur:  radius 8,  y: 0,   opacity 0.1
glass: radius 12, y: 0,   opacity 0.18
```

---

## UI Components

### Buttons

**File**: `DesignButtons.swift`

| Component | Size | Lines |
|-----------|------|-------|
| IconButton | 52×52pt (icon 24×24) | 19-85 |
| PrimaryButton | 120×60pt (capture) | 87-196 |
| DesignActionBar | Full width, 3 columns | 198-291 |

**Press Feedback**: 0.95 scale + 0.85 opacity

### Controls

**File**: `DesignControls.swift`

| Component | Description | Lines |
|-----------|-------------|-------|
| SegmentedControl | Horizontal scroll, spring animation | 56-109 |
| SliderView | 40×40pt knob, continuous drag | 152-286 |

### Icon System

**File**: `DesignIcon.swift` (Lines 5-170)

**16pt Icons** (Settings): effectASCII, effectCircle, effectDiamond, settingCell, settingJitter, settingContrast, save

**24pt Icons** (Actions): arrowBack, delete, question, rotateCamera, upload

**Implementation**: SVG-based via PocketSVG with caching (`SVGCache`)

---

## State Management

**File**: `AppViewModel.swift` (Lines 13-378)

**Key Properties**:
- `selectedEffect`, `parameters`, `palette`, `cameraFacing`
- `previewStatus`, `previewFrame`, `previewImage`
- `isSettingsPresented`, `isColorPickerPresented`, `isEffectSelectionPresented`

---

## Key UI Files Reference

| Component | Path | Lines |
|-----------|------|-------|
| Main Entry | `AsciiCameraKit/UI/AsciiCameraExperience.swift` | 11-232 |
| Root Container | `AsciiUI/RootView.swift` | 9-343 |
| Control Overlay | `AsciiUI/Components/ControlOverlay.swift` | 17-294 |
| Metal Preview | `AsciiUI/Components/MetalPreviewView.swift` | 8-26 |
| Text Preview | `AsciiUI/Components/CameraPreviewContainer.swift` | 7-168 |
| Effect Selection | `AsciiUI/Components/EffectSelectionView.swift` | 6-136 |
| Settings Sheet | `AsciiUI/Sheets/EffectSettingsSheet.swift` | 6-122 |
| Color Picker | `AsciiUI/Sheets/ColorPickerSheet.swift` | 9-259 |
| Design Tokens | `AsciiUI/DesignSystem/DesignTokens.swift` | 7-166 |
| Buttons | `AsciiUI/DesignSystem/DesignButtons.swift` | 19-291 |
| Controls | `AsciiUI/DesignSystem/DesignControls.swift` | 56-286 |
| Surface Styles | `AsciiUI/DesignSystem/DesignSurface.swift` | 42-101 |
| Icons | `AsciiUI/DesignSystem/DesignIcon.swift` | 5-170 |
| ViewModel | `AsciiDomain/ViewModels/AppViewModel.swift` | 13-378 |

---

## Accessibility

- `accessibilityLabel` on all interactive elements
- `accessibilityHint` for complex controls
- `accessibilityElement(children: .contain)` for groups
- High contrast (white on dark backgrounds)

---

- Never hallucinate or fabricate information. If you're unsure about anything, you MUST explicitly state your uncertainty. Say "I don't know" rather than guessing or making assumptions. Honesty about limitations is required.