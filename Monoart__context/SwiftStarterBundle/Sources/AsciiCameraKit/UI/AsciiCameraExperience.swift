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

    private let engineFactory: () -> AsciiEngineProtocol
    private let cameraFactory: () -> CameraServiceProtocol
    private let mediaCoordinatorFactory: () -> MediaCoordinatorProtocol
    private let frameRendererFactory: () -> AsciiFrameRendering

    public init(
        viewModel: AppViewModel = AppViewModel(),
        engineFactory: @escaping () -> AsciiEngineProtocol = DefaultFactories.makeEngine,
        cameraFactory: @escaping () -> CameraServiceProtocol = DefaultFactories.makeCamera,
        mediaCoordinatorFactory: @escaping () -> MediaCoordinatorProtocol = DefaultFactories.makeMediaCoordinator,
        frameRendererFactory: @escaping () -> AsciiFrameRendering = DefaultFactories.makeRenderer
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.engineFactory = engineFactory
        self.cameraFactory = cameraFactory
        self.mediaCoordinatorFactory = mediaCoordinatorFactory
        self.frameRendererFactory = frameRendererFactory
    }

    public var body: some View {
        RootView(
            viewModel: viewModel,
            useDemoPreviewOnAppear: false,
            captureAction: captureTapped,
            flipAction: flipCamera,
            importAction: { isImportPickerPresented = true },
            shareAction: shareImage == nil ? nil : shareTapped
        )
        .onAppear {
            guard pipeline == nil else { return }
            if #available(macOS 11.0, iOS 15.0, tvOS 15.0, *) {
                let engine = engineFactory()
                let camera = cameraFactory()
                let media = mediaCoordinatorFactory()
                let renderer = frameRendererFactory()
                let newPipeline = PreviewPipeline(
                    viewModel: viewModel,
                    engine: engine,
                    cameraService: camera,
                    configuration: EngineConfiguration(),
                    frameRenderer: renderer,
                    mediaCoordinator: media
                )
#if canImport(UIKit)
                newPipeline.onCaptureSuccess = { image in
                    shareImage = image
                }
#endif
                pipeline = newPipeline
                newPipeline.start()
            } else {
                viewModel.startDemoPreviewIfNeeded()
            }
        }
        .onDisappear {
            pipeline?.stop()
            isImportPickerPresented = false
        }
        .photosPicker(isPresented: $isImportPickerPresented, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task {
                defer { selectedPhotoItem = nil }
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        pipeline?.processImportedImage(image)
                    } else {
                        await MainActor.run {
                            viewModel.failPreview(message: "Unable to load image")
                        }
                    }
                } catch {
                    await MainActor.run {
                        viewModel.failPreview(message: error.localizedDescription)
                    }
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private func flipCamera() {
        viewModel.toggleCameraFacing()
        if #available(macOS 11.0, iOS 15.0, tvOS 15.0, *) {
            pipeline?.switchCamera()
        }
    }

    private func captureTapped() {
        if #available(macOS 11.0, iOS 15.0, tvOS 15.0, *) {
            pipeline?.capture()
        } else {
            viewModel.simulateCapture()
        }
    }

    private func shareTapped() {
        isShareSheetPresented = shareImage != nil
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
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
