#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import AsciiEngine
import Dispatch
import SwiftUI

@available(iOS 16.0, *)
public struct RootView: View {
    @StateObject private var viewModel: AppViewModel
    private let useDemoPreviewOnAppear: Bool
    private let captureAction: () -> Void
    private let flipAction: () -> Void
    private let importAction: () -> Void
    private let shareAction: (() -> Void)?
    private let engine: AsciiEngine?
    private let useGPUPreview: Bool

    public init(
        viewModel: AppViewModel = AppViewModel(),
        useDemoPreviewOnAppear: Bool = true,
        captureAction: (() -> Void)? = nil,
        flipAction: (() -> Void)? = nil,
        importAction: (() -> Void)? = nil,
        shareAction: (() -> Void)? = nil,
        engine: AsciiEngine? = nil,
        useGPUPreview: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.useDemoPreviewOnAppear = useDemoPreviewOnAppear
        self.captureAction = captureAction ?? { viewModel.simulateCapture() }
        self.flipAction = flipAction ?? { viewModel.toggleCameraFacing() }
        self.importAction = importAction ?? { viewModel.presentColorPicker(for: .background) }
        self.shareAction = shareAction
        self.engine = engine
        self.useGPUPreview = useGPUPreview && engine != nil
    }

    public var body: some View {
        ZStack {
            // Background layer: Camera preview
            if useGPUPreview, let engine = engine {
                MetalPreviewView(engine: engine, effect: viewModel.selectedEffect)
                    .ignoresSafeArea()
            } else {
                CameraPreviewContainer(
                    status: viewModel.previewStatus,
                    frame: viewModel.previewFrame,
                    palette: viewModel.palette
                )
                .ignoresSafeArea()
            }

            // Bottom controls layer
            VStack(spacing: 12) {
                Spacer() // Push controls to bottom
                SettingsHandle { viewModel.presentSettingsSheet() }
                ControlOverlay(
                    selectedEffect: viewModel.selectedEffect,
                    isCaptureInFlight: viewModel.isCaptureInFlight,
                    onImport: importAction,
                    onCapture: captureTapped,
                    onFlip: flipTapped,
                    onSelectEffect: viewModel.selectEffect,
                    onShowColors: { viewModel.presentColorPicker(for: .symbols) }
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 24)

            // Top notification layer
            if let status = viewModel.captureStatus {
                VStack {
                    CaptureConfirmationBanner(status: status, onDismiss: {
                        viewModel.dismissCaptureStatus()
                    }, onShare: shareAction)
                    .padding(.horizontal, 16) // 16px horizontal padding as requested
                    .padding(.top, 16) // Top padding for safe area
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            viewModel.dismissCaptureStatus()
                        }
                    }
                    
                    Spacer() // Push banner to top
                }
            }
        }
        .onAppear {
            if useDemoPreviewOnAppear {
                viewModel.startDemoPreviewIfNeeded()
            }
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            if #available(iOS 16.0, *) {
                EffectSettingsSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            } else {
                EffectSettingsSheet(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isColorPickerPresented) {
            if #available(iOS 16.0, *) {
                ColorPickerSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            } else {
                ColorPickerSheet(viewModel: viewModel)
            }
        }
    }

    private func captureTapped() {
        captureAction()
    }

    private func flipTapped() {
        flipAction()
    }
}
#endif

