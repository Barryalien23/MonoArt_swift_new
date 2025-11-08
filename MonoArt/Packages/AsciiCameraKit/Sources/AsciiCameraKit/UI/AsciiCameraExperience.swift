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
    @State private var pipeline: PreviewPipeline?
    @State private var isImportPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false

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
            importAction: { isImportPickerPresented = true },
            shareAction: shareImage == nil ? nil : { shareTapped() }
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
        guard pipeline == nil else { return }

        let engine = engineFactory()
        let camera = cameraFactory()
        let mediaCoordinator = mediaCoordinatorFactory()
        let renderer = frameRendererFactory()

        let newPipeline = PreviewPipeline(
            viewModel: viewModel,
            engine: engine,
            cameraService: camera,
            configuration: EngineConfiguration(),
            frameRenderer: renderer,
            mediaCoordinator: mediaCoordinator
        )
#if canImport(UIKit)
        newPipeline.onCaptureSuccess = { image in
            shareImage = image
        }
#endif
        pipeline = newPipeline
        newPipeline.start()
    }

    @MainActor
    private func teardownPipeline() {
        pipeline?.stop()
        pipeline = nil
        isImportPickerPresented = false
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            await loadPhoto(from: item)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    selectedPhotoItem = nil
                    viewModel.failPreview(message: "Unable to load image")
                }
                return
            }

            await MainActor.run {
                selectedPhotoItem = nil
                pipeline?.processImportedImage(image)
            }
        } catch {
            await MainActor.run {
                selectedPhotoItem = nil
                viewModel.failPreview(message: error.localizedDescription)
            }
        }
    }

    private func flipCamera() {
        viewModel.toggleCameraFacing()
        pipeline?.switchCamera()
    }

    private func captureTapped() {
        if let pipeline {
            pipeline.capture()
        } else {
            viewModel.simulateCapture()
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
