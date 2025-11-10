#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import PhotosUI
import UIKit
import AsciiDomain
import AsciiUI
import AsciiEngine
import AsciiCamera

@available(macOS 11.0, iOS 16.0, tvOS 16.0, *)
public struct AsciiCameraExperience: View {
    @StateObject private var viewModel: AppViewModel
    @State private var gpuPipeline: GPUPreviewPipeline?
    @State private var textPipeline: PreviewPipeline?
    @State private var isImportPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false
    @State private var useGPUPreview: Bool = true

    @MainActor private let engineFactory: () -> AsciiEngineProtocol
    @MainActor private let cameraFactory: () -> CameraServiceProtocol
    @MainActor private let mediaCoordinatorFactory: () -> MediaCoordinatorProtocol
    @MainActor private let frameRendererFactory: () -> AsciiFrameRendering

    public init(
        viewModel: AppViewModel = AppViewModel(),
        engineFactory: (() -> AsciiEngineProtocol)? = nil,
        cameraFactory: (() -> CameraServiceProtocol)? = nil,
        mediaCoordinatorFactory: (() -> MediaCoordinatorProtocol)? = nil,
        frameRendererFactory: (() -> AsciiFrameRendering)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.engineFactory = engineFactory ?? { DefaultFactories.makeEngine() }
        self.cameraFactory = cameraFactory ?? { DefaultFactories.makeCamera() }
        self.mediaCoordinatorFactory = mediaCoordinatorFactory ?? { DefaultFactories.makeMediaCoordinator() }
        self.frameRendererFactory = frameRendererFactory ?? { DefaultFactories.makeRenderer() }
    }

    public var body: some View {
        rootView
            .onAppear(perform: startPipelineIfNeeded)
            .onDisappear(perform: teardownPipeline)
            .photosPicker(
                isPresented: $isImportPickerPresented,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { newValue in
                handlePhotoSelection(newValue)
            }
            .sheet(isPresented: $isShareSheetPresented, onDismiss: { shareImage = nil }) {
                shareSheetContent
            }
    }

    @ViewBuilder
    private var rootView: some View {
        RootView(
            viewModel: viewModel,
            useDemoPreviewOnAppear: false,
            captureAction: captureTapped,
            flipAction: flipCamera,
            importAction: {
                if viewModel.isImportMode {
                    gpuPipeline?.cancelImport()
                    textPipeline?.cancelImport()
                }
                isImportPickerPresented = true
            },
            saveImportAction: saveImportedPhoto,
            cancelImportAction: cancelImport,
            shareAction: shareImage == nil ? nil : { shareTapped() },
            engine: gpuPipeline?.engine,
            useGPUPreview: useGPUPreview
        )
    }

    @ViewBuilder
    private var shareSheetContent: some View {
        if let shareImage {
            ShareSheet(items: [shareImage])
        } else {
            EmptyView()
        }
    }

    @MainActor
    private func startPipelineIfNeeded() {
        guard gpuPipeline == nil && textPipeline == nil else { return }

        let engine = engineFactory()
        let camera = cameraFactory()
        let mediaCoordinator = mediaCoordinatorFactory()
        let renderer = frameRendererFactory()

        // Try to use GPU pipeline first
        if useGPUPreview, let asciiEngine = engine as? AsciiEngine {
            let newGPUPipeline = GPUPreviewPipeline(
                viewModel: viewModel,
                engine: asciiEngine,
                cameraService: camera,
                configuration: EngineConfiguration(),
                frameRenderer: renderer,
                mediaCoordinator: mediaCoordinator
            )
#if canImport(UIKit)
            newGPUPipeline.onCaptureSuccess = { image in
                shareImage = image
            }
#endif
            gpuPipeline = newGPUPipeline
            newGPUPipeline.start()
        } else {
            // Fallback to text pipeline
            useGPUPreview = false
            let newTextPipeline = PreviewPipeline(
                viewModel: viewModel,
                engine: engine,
                cameraService: camera,
                configuration: EngineConfiguration(),
                frameRenderer: renderer,
                mediaCoordinator: mediaCoordinator
            )
#if canImport(UIKit)
            newTextPipeline.onCaptureSuccess = { image in
                shareImage = image
            }
#endif
            textPipeline = newTextPipeline
            newTextPipeline.start()
        }
    }

    @MainActor
    private func teardownPipeline() {
        gpuPipeline?.stop()
        gpuPipeline = nil
        textPipeline?.stop()
        textPipeline = nil
        isImportPickerPresented = false
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        print("📱 AsciiCameraExperience: handlePhotoSelection called, item: \(item != nil ? "present" : "nil")")
        guard let item else {
            print("❌ AsciiCameraExperience: No photo item selected")
            return
        }
        Task {
            await loadPhoto(from: item)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        print("📸 AsciiCameraExperience: loadPhoto started")
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                print("❌ AsciiCameraExperience: Failed to load image data")
                await MainActor.run {
                    selectedPhotoItem = nil
                    viewModel.failPreview(message: "Unable to load image")
                }
                return
            }

            print("✅ AsciiCameraExperience: Image loaded, size: \(image.size)")
            await MainActor.run {
                selectedPhotoItem = nil
                if let gpuPipeline = gpuPipeline {
                    print("🎯 AsciiCameraExperience: Calling gpuPipeline.processImportedImage")
                    gpuPipeline.processImportedImage(image)
                } else if let textPipeline = textPipeline {
                    print("🎯 AsciiCameraExperience: Calling textPipeline.processImportedImage")
                    textPipeline.processImportedImage(image)
                } else {
                    print("❌ AsciiCameraExperience: No pipeline available!")
                }
            }
        } catch {
            print("❌ AsciiCameraExperience: Error loading photo: \(error.localizedDescription)")
            await MainActor.run {
                selectedPhotoItem = nil
                viewModel.failPreview(message: error.localizedDescription)
            }
        }
    }

    private func flipCamera() {
        viewModel.toggleCameraFacing()
        if let gpuPipeline = gpuPipeline {
            gpuPipeline.switchCamera()
        } else if let textPipeline = textPipeline {
            textPipeline.switchCamera()
        }
    }

    private func captureTapped() {
        if let gpuPipeline = gpuPipeline {
            gpuPipeline.capture()
        } else if let textPipeline = textPipeline {
            textPipeline.capture()
        } else {
            viewModel.simulateCapture()
        }
    }

    private func saveImportedPhoto() {
        if let gpuPipeline = gpuPipeline {
            gpuPipeline.saveImportedPhoto()
        } else if let textPipeline = textPipeline {
            textPipeline.saveImportedPhoto()
        } else {
            viewModel.simulateCapture()
        }
    }

    private func cancelImport() {
        if let gpuPipeline = gpuPipeline {
            gpuPipeline.cancelImport()
        } else if let textPipeline = textPipeline {
            textPipeline.cancelImport()
        } else {
            viewModel.cancelImport()
        }
    }

    private func shareTapped() {
        isShareSheetPresented = shareImage != nil
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
@MainActor
private enum DefaultFactories {
    static func makeEngine() -> AsciiEngineProtocol {
        AsciiEngine()
    }

    static func makeCamera() -> CameraServiceProtocol {
        CameraService()
    }

    static func makeMediaCoordinator() -> MediaCoordinatorProtocol {
        PhotosMediaCoordinator()
    }

    static func makeRenderer() -> AsciiFrameRendering {
        AsciiFrameRenderer()
    }
}
#endif
