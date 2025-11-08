# GPU Preview Usage Example

## Quick Start

This guide shows how to integrate the GPU-based ASCII preview into your app.

## Basic Setup

### 1. Initialize Engine and Coordinator

```swift
import AsciiEngine
import AsciiCameraKit
import MetalKit

@available(iOS 15.0, *)
class CameraViewController {
    let engine = AsciiEngine()
    let device = MTLCreateSystemDefaultDevice()!
    var coordinator: GPUPreviewCoordinator?
    var mtkView: MTKView?
    
    func setupGPUPreview() throws {
        // Prepare engine
        try engine.prepare(configuration: EngineConfiguration())
        
        // Create and setup MTKView
        let view = MTKView()
        try engine.setupPreview(on: view, effect: .ascii)
        self.mtkView = view
        
        // Create coordinator for camera frame updates
        coordinator = GPUPreviewCoordinator(engine: engine, device: device)
    }
}
```

### 2. Connect Camera Frames

```swift
// In your AVCaptureVideoDataOutputSampleBufferDelegate
func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    Task { @MainActor in
        coordinator?.updateFrame(pixelBuffer)
    }
}
```

### 3. Update Parameters

```swift
func onParametersChanged(parameters: EffectParameters, palette: PaletteState, effect: EffectType) {
    Task { @MainActor in
        coordinator?.updateParameters(parameters, palette: palette, effect: effect)
    }
}
```

## SwiftUI Integration

### Option A: Use GPUCameraPreviewContainer

```swift
import SwiftUI
import AsciiCameraKit
import AsciiEngine
import AsciiDomain

@available(iOS 15.0, *)
struct GPUPreviewView: View {
    @StateObject var viewModel = AppViewModel()
    let engine: AsciiEngine
    
    var body: some View {
        GPUCameraPreviewContainer(
            engine: engine,
            effect: viewModel.selectedEffect,
            status: viewModel.previewStatus
        )
    }
}
```

### Option B: Direct MetalPreviewView Usage

```swift
@available(iOS 15.0, *)
struct DirectMetalView: View {
    let engine: AsciiEngine
    let effect: EffectType
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            MetalPreviewView(engine: engine, effect: effect)
                .ignoresSafeArea()
        }
    }
}
```

## Complete Example with PreviewPipeline Integration

```swift
import AsciiCameraKit
import AsciiEngine
import AsciiCamera
import AsciiDomain

@available(iOS 15.0, *)
class GPUPreviewPipeline {
    let viewModel: AppViewModel
    let engine: AsciiEngine
    let cameraService: CameraServiceProtocol
    var coordinator: GPUPreviewCoordinator?
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        self.engine = AsciiEngine()
        self.cameraService = CameraService()
    }
    
    func start() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "GPUPreview", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Metal not available"
            ])
        }
        
        // Setup engine
        try engine.prepare(configuration: EngineConfiguration())
        
        // Create coordinator
        coordinator = GPUPreviewCoordinator(engine: engine, device: device)
        
        // Subscribe to camera frames
        cameraService.framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] envelope in
                self?.coordinator?.updateFrame(envelope.pixelBuffer)
            }
        
        // Subscribe to parameter changes
        viewModel.$parameters
            .combineLatest(viewModel.$palette, viewModel.$selectedEffect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] params, palette, effect in
                self?.coordinator?.updateParameters(params, palette: palette, effect: effect)
            }
        
        // Start camera
        Task {
            try await cameraService.startSession()
            await MainActor.run {
                viewModel.beginPreviewLoading()
            }
        }
    }
}
```

## Export Text (Fallback Path)

The text export path remains available for saving ASCII art:

```swift
func exportASCII() async throws -> String {
    guard let pixelBuffer = currentPixelBuffer else {
        throw ExportError.noFrame
    }
    
    let frame = try await engine.renderCapture(
        pixelBuffer: pixelBuffer,
        effect: viewModel.selectedEffect,
        parameters: viewModel.parameters,
        palette: viewModel.palette
    )
    
    return frame.glyphText ?? ""
}
```

## Performance Tips

1. **Reduce texture conversions**: Cache `CVMetalTextureCache` (done automatically in `GPUPreviewCoordinator`)
2. **Throttle parameter updates**: Use Combine's `debounce` to avoid excessive atlas regeneration
3. **Profile with Instruments**: Use Metal System Trace to identify bottlenecks
4. **Consider YUV optimization**: For maximum performance, accept Y-plane directly instead of BGRA

## Troubleshooting

### Black screen on GPU preview

- Ensure `engine.setupPreview(on:effect:)` was called
- Verify camera frames are calling `coordinator.updateFrame()`
- Check that MTKView is properly added to view hierarchy

### Slow frame rate

- Check if atlas is regenerating every frame (should only happen on effect change)
- Verify camera is not blocking main thread
- Profile with Instruments Metal System Trace

### Memory warnings

- Ensure texture cache is properly released when stopping preview
- Check for retain cycles in camera delegate closures

## Next Steps

- See `GPUPreviewImplementation.md` for architecture details
- See `PreviewPipeline.swift` for full integration example
- See `AsciiEngine.swift` for API reference

