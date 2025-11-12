#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import AsciiEngine
import Dispatch
import SwiftUI
import UIKit

@available(iOS 16.0, *)
public struct RootView: View {
    @StateObject private var viewModel: AppViewModel
    private let useDemoPreviewOnAppear: Bool
    private let captureAction: () -> Void
    private let flipAction: () -> Void
    private let importAction: () -> Void
    private let saveImportAction: () -> Void
    private let cancelImportAction: () -> Void
    private let shareAction: (() -> Void)?
    private let engine: AsciiEngine?
    private let useGPUPreview: Bool

    public init(
        viewModel: AppViewModel = AppViewModel(),
        useDemoPreviewOnAppear: Bool = true,
        captureAction: (() -> Void)? = nil,
        flipAction: (() -> Void)? = nil,
        importAction: (() -> Void)? = nil,
        saveImportAction: (() -> Void)? = nil,
        cancelImportAction: (() -> Void)? = nil,
        shareAction: (() -> Void)? = nil,
        engine: AsciiEngine? = nil,
        useGPUPreview: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.useDemoPreviewOnAppear = useDemoPreviewOnAppear
        self.captureAction = captureAction ?? { viewModel.simulateCapture() }
        self.flipAction = flipAction ?? { viewModel.toggleCameraFacing() }
        self.importAction = importAction ?? {}
        self.saveImportAction = saveImportAction ?? self.captureAction
        self.cancelImportAction = cancelImportAction ?? self.flipAction
        self.shareAction = shareAction
        self.engine = engine
        self.useGPUPreview = useGPUPreview && engine != nil
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background layer: Camera preview
                if let previewImage = viewModel.previewImage {
                    Color.black
                        .ignoresSafeArea()
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(previewImage.size, contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else if viewModel.isImportMode {
                    // Show loading state when importing photo
                    ZStack {
                        Color.black
                            .ignoresSafeArea()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                        ProgressView("Processing...")
                            .tint(.white)
                            .foregroundColor(.white)
                    }
                } else if useGPUPreview, let engine = engine {
                    MetalPreviewView(engine: engine, effect: viewModel.selectedEffect)
                        .ignoresSafeArea()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    CameraPreviewContainer(
                        status: viewModel.previewStatus,
                        frame: viewModel.previewFrame,
                        palette: viewModel.palette
                    )
                    .ignoresSafeArea()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                // Header layer
                VStack {
                    topToolbar(proxy: proxy)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Bottom controls layer
                VStack(spacing: DesignSpacing.base) {
                    Spacer()
                    
                    if viewModel.isEffectSelectionPresented {
                        EffectSelectionView(
                            selectedEffect: viewModel.selectedEffect,
                            availableEffects: EffectType.allCases,
                            onSelectEffect: viewModel.selectEffect,
                            onDismiss: { viewModel.dismissEffectSelection() }
                        )
                    } else {
                        ControlOverlay(
                            selectedEffect: viewModel.selectedEffect,
                            availableEffects: EffectType.allCases,
                            isCaptureInFlight: viewModel.isCaptureInFlight,
                            isImportMode: viewModel.isImportMode,
                            palette: viewModel.palette,
                            selectedColorTarget: viewModel.selectedColorTarget,
                            onImport: importAction,
                            onCapture: captureTapped,
                            onFlip: flipTapped,
                            onSaveImport: saveImportAction,
                            onCancelImport: cancelImportAction,
                            onSelectEffect: viewModel.selectEffect,
                            onSelectColorTarget: viewModel.selectColorTarget,
                            onShowEffects: { viewModel.presentEffectSelection() },
                            onShowSettings: { viewModel.presentSettingsSheet() },
                            onShowColors: { viewModel.presentColorPicker(for: viewModel.selectedColorTarget) }
                        )
                    }
                }
                .padding(.horizontal, DesignSpacing.xl)
                .padding(.bottom, proxy.safeAreaInsets.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

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
            .frame(width: proxy.size.width, height: proxy.size.height)
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
        if viewModel.isImportMode {
            saveImportAction()
        } else {
            captureAction()
        }
    }

    private func flipTapped() {
        if viewModel.isImportMode {
            cancelImportAction()
        } else {
            flipAction()
        }
    }

    private func topToolbar(proxy: GeometryProxy) -> some View {
        HStack {
            GalleryPreviewButton(image: galleryImage, action: openPhotosApp)
            Spacer()
            DesignIconButton(icon: .question, action: {})
                .accessibilityLabel("Help")
        }
        .padding(.horizontal, DesignSpacing.xl)
        .padding(.top, proxy.safeAreaInsets.top + DesignSpacing.base)
    }

    private var galleryImage: UIImage? {
        viewModel.lastSavedImage
    }

    private func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

@available(iOS 16.0, *)
private struct GalleryPreviewButton: View {
    let image: UIImage?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                    .fill(DesignColor.white20)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous))
                } else {
                    DesignIconView(.upload, color: DesignColor.white, size: 24)
                }
            }
            .frame(width: 52, height: 52)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }
}
#endif

