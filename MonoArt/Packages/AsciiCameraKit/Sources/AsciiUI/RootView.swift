#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import Dispatch
import SwiftUI

public struct RootView: View {
    @StateObject private var viewModel: AppViewModel
    private let useDemoPreviewOnAppear: Bool
    private let captureAction: () -> Void
    private let flipAction: () -> Void
    private let importAction: () -> Void
    private let shareAction: (() -> Void)?

    public init(
        viewModel: AppViewModel = AppViewModel(),
        useDemoPreviewOnAppear: Bool = true,
        captureAction: (() -> Void)? = nil,
        flipAction: (() -> Void)? = nil,
        importAction: (() -> Void)? = nil,
        shareAction: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.useDemoPreviewOnAppear = useDemoPreviewOnAppear
        self.captureAction = captureAction ?? { viewModel.simulateCapture() }
        self.flipAction = flipAction ?? { viewModel.toggleCameraFacing() }
        self.importAction = importAction ?? { viewModel.presentColorPicker(for: .background) }
        self.shareAction = shareAction
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewContainer(
                status: viewModel.previewStatus,
                frame: viewModel.previewFrame,
                palette: viewModel.palette
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
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

            if let status = viewModel.captureStatus {
                CaptureConfirmationBanner(status: status, onDismiss: {
                    viewModel.dismissCaptureStatus()
                }, onShare: shareAction)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.dismissCaptureStatus()
                    }
                }
            }
        }
        .onAppear {
            if useDemoPreviewOnAppear {
                viewModel.startDemoPreviewIfNeeded()
            }
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            EffectSettingsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.isColorPickerPresented) {
            ColorPickerSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
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

