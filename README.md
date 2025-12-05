# MonoArt

<div align="center">
  <img src="FILES/Icons monoart/About Icons/Icon app.png" alt="MonoArt Icon" width="120" height="120">
  
  **Transform your world into ASCII art in real-time**
  
  [![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://www.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Xcode](https://img.shields.io/badge/Xcode-17.0+-blue.svg)](https://developer.apple.com/xcode/)
</div>

## 📱 About

MonoArt is a powerful iOS camera & photo app that transforms your live camera preview and imported images into stunning ASCII art. Tweak characters, colors, and contrast in real-time, then capture or import photos and save glitch-style shots right on your device.

## ✨ Features

### 🎨 Real-Time ASCII Rendering
- **GPU-Accelerated Preview**: 60 FPS real-time Metal rendering
- **CPU Fallback**: Automatic fallback for unsupported devices
- **Multiple Effect Types**:
  - ASCII (`.:-=+*#%@`)
  - Blocks (`░▒▓█`)
  - Braille patterns
  - Dense extended ASCII
  - Minimal (`. '`)
  - Numeric (`0-9`)

### 🎛️ Customization
- **Cell Size Control**: Adjust ASCII character density
- **Edge Detection**: Fine-tune edge threshold and softness
- **Jitter Effects**: Add randomness for glitch-style aesthetics
- **Color Customization**:
  - Background color
  - Symbol/Foreground color
  - Gradient support for symbols
  - Preset color palettes

### 📸 Capture & Import
- **Live Camera Preview**: Real-time ASCII transformation
- **Photo Import**: Transform existing photos from your library
- **High-Quality Export**: Save processed images to Photos
- **Camera Flip**: Switch between front and back cameras

### 🎯 User Interface
- **Modern SwiftUI Design**: Clean, intuitive interface
- **Dark Theme**: Easy on the eyes
- **Custom Design System**: Consistent IBM Plex Mono typography
- **Responsive Layout**: Optimized for all iPhone sizes

## 🛠️ Technology Stack

### Core Technologies
- **Language**: Swift 6.0 (Swift Concurrency)
- **UI Framework**: SwiftUI
- **Graphics**: Metal (GPU acceleration)
- **Camera**: AVFoundation
- **Architecture**: MVVM with modular Swift Package design

### Dependencies
- **PocketSVG** (2.8.0) - SVG icon rendering

### Package Architecture

```
MonoArt/
├── AsciiCameraKit (Main Package)
│   ├── AsciiEngine        # Core rendering engine with Metal support
│   ├── AsciiDomain        # Domain models and ViewModels
│   ├── AsciiUI            # SwiftUI components and design system
│   ├── AsciiCamera        # Camera service and frame capture
│   └── AsciiSupport       # Logging and utilities
```

## 📋 Requirements

- **iOS**: 16.0 or later
- **Xcode**: 17.0 or later
- **Swift**: 6.0 or later
- **Metal**: Required for GPU preview (automatic fallback if unavailable)

## 🚀 Installation

### Clone the Repository

```bash
git clone https://github.com/Barryalien23/MonoArt_swift_new.git
cd MonoArt_swift_new
```

### Open in Xcode

```bash
open MonoArt.xcodeproj
```

### Build and Run

1. Select your target device or simulator
2. Press `⌘+R` to build and run
3. Grant camera permissions when prompted

## 🏗️ Architecture

### GPU Preview Pipeline

```
Camera → CVPixelBuffer → MTLTexture → Metal Shader → 60fps Display
```

### CPU Fallback Pipeline

```
Camera → ASCII Processing → SwiftUI Text Rendering
```

### Capture Pipeline

```
Camera/Import → High-Quality CPU Processing → Photos Library
```

## 🎨 Design System

### Typography
- **Font Family**: IBM Plex Mono
- **Weights**: Medium, SemiBold, Bold
- **Styles**: Body1 (12pt), Body2 (12pt SemiBold), Head1 (14pt SemiBold)

### Color Palette
- **Main Grey**: `#1A1A1A`
- **Accent Green**: `#62F469`
- **Black**: `#000000`
- **White Variants**: 60%, 40%, 20%, 12%, 8%, 4%

### Spacing Scale
```
xs(3pt) | s(4pt) | sm(6pt) | md(8pt) | lg(10pt) | base(12pt) | xl(16pt) | xxl(20pt)
```

## 📊 Performance

### GPU Preview Mode
- **Frame Rate**: 60 FPS
- **CPU Usage**: < 15%
- **GPU Usage**: ~20-30%
- **Memory**: ~50-80 MB

### CPU Fallback Mode
- **Frame Rate**: 15-30 FPS
- **CPU Usage**: ~40-60%
- **Memory**: ~40-60 MB

## 🧪 Testing

### Run Tests

```bash
# Main app tests
xcodebuild test -project MonoArt.xcodeproj -scheme MonoArt -destination 'platform=iOS Simulator,name=iPhone 15'

# Package tests
swift test --package-path MonoArt/Packages/AsciiCameraKit
```

## 📝 Development

### Project Structure

```
MonoArt/
├── MonoArt/                    # Main iOS app target
├── MonoArtTests/              # Unit tests
├── MonoArtUITests/            # UI tests
├── Packages/
│   └── AsciiCameraKit/        # Core functionality package
│       ├── Sources/
│       │   ├── AsciiCameraKit/   # Main module
│       │   ├── AsciiEngine/      # Rendering engine
│       │   ├── AsciiDomain/      # Models & ViewModels
│       │   ├── AsciiUI/          # UI components
│       │   ├── AsciiCamera/      # Camera service
│       │   └── AsciiSupport/     # Utilities
│       └── Tests/
└── FILES/                      # Design assets and icons
```

### Key Components

- **AsciiEngine**: Core rendering logic with Metal GPU support
- **AppViewModel**: Main view model managing app state
- **GPUPreviewPipeline**: Real-time 60fps Metal rendering pipeline
- **DesignSystem**: Custom UI components and tokens
- **CameraService**: AVFoundation camera capture

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Workflow

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift 6 language mode
- Prefer value types and immutability
- Use structured concurrency (async/await, actors)
- Document public APIs with DocC

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Alexandr Raschektaev**

- Portfolio: [raux.framer.website](https://raux.framer.website)
- Telegram: [@AlexandrComp](https://t.me/AlexandrComp)
- Channel: [@Okolo_designov](https://t.me/Okolo_designov)

## 🙏 Acknowledgments

- **IBM Plex Mono** font by IBM
- **PocketSVG** library for SVG rendering
- Metal framework by Apple for GPU acceleration

## 📱 App Store

Coming soon!

---

<div align="center">
  Made with ❤️ and Swift
</div>

