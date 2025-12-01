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
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .background(Color.black)
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
                        .clipped()
                } else {
                    CameraPreviewContainer(
                        status: viewModel.previewStatus,
                        frame: viewModel.previewFrame,
                        palette: viewModel.palette
                    )
                    .ignoresSafeArea()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }

                // Header layer
                VStack(alignment: .leading, spacing: 0) {
                    topToolbar(proxy: proxy)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Bottom controls layer
                VStack(spacing: DesignSpacing.base) {
                    Spacer()
                    
                    if viewModel.isParameterEditingPresented {
                        ParameterEditingOverlay(
                            viewModel: viewModel,
                            selectedParameter: viewModel.selectedEditingParameter,
                            onBack: { viewModel.dismissParameterEditing() },
                            onImport: importAction,
                            onCapture: captureTapped,
                            onFlip: flipTapped,
                            onSaveImport: saveImportAction,
                            onCancelImport: cancelImportAction
                        )
                        .padding(.bottom, bottomPadding(for: proxy.safeAreaInsets.bottom))
                    } else if viewModel.isEffectSelectionPresented {
                        EffectSelectionView(
                            selectedEffect: viewModel.selectedEffect,
                            availableEffects: EffectType.allCases,
                            isCaptureInFlight: viewModel.isCaptureInFlight,
                            isImportMode: viewModel.isImportMode,
                            onSelectEffect: viewModel.selectEffect,
                            onDismiss: { viewModel.dismissEffectSelection() },
                            onImport: importAction,
                            onCapture: captureTapped,
                            onFlip: flipTapped,
                            onSaveImport: saveImportAction,
                            onCancelImport: cancelImportAction
                        )
                        .padding(.bottom, bottomPadding(for: proxy.safeAreaInsets.bottom, internalVerticalPadding: DesignSpacing.xl))
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
                            onShowSettings: { parameter in viewModel.presentParameterEditing(for: parameter) },
                            onShowColors: { viewModel.presentColorPicker(for: viewModel.selectedColorTarget) }
                        )
                        .padding(.bottom, bottomPadding(for: proxy.safeAreaInsets.bottom))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
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
        // Альтернативный метод через .safeAreaInset (раскомментировать, если VStack не работает)
        // .safeAreaInset(edge: .top, spacing: 0) {
        //     HStack(spacing: DesignSpacing.md) {
        //         GalleryPreviewButton(image: galleryImage, action: openPhotosApp)
        //         Spacer(minLength: DesignSpacing.zero)
        //         DesignIconButton(icon: .question, action: {})
        //             .accessibilityLabel("Help")
        //     }
        //     .padding(.horizontal, DesignSpacing.xl)
        //     .padding(.vertical, DesignSpacing.xxl)
        //     .background(Color.clear)
        // }
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

    /// Вычисляет горизонтальные отступы с учётом safe area
    /// Цель: обеспечить согласованные отступы на всех устройствах, включая iPad
    /// - Parameters:
    ///   - safeAreaInsets: Safe area insets для определения боковых зон
    /// - Returns: Горизонтальный отступ в точках
    private func horizontalPadding(for safeAreaInsets: EdgeInsets) -> CGFloat {
        // Базовый отступ 16pt
        let baseHorizontalPadding: CGFloat = DesignSpacing.xl
        
        // Если есть боковые safe area (например, landscape на iPhone или iPad)
        // добавляем их к базовому отступу
        let leftInset = safeAreaInsets.leading
        let rightInset = safeAreaInsets.trailing
        
        // Используем максимальный из боковых отступов
        let maxSideInset = max(leftInset, rightInset)
        
        // Если safe area больше базового отступа, используем safe area
        // Иначе используем базовый отступ
        return max(baseHorizontalPadding, maxSideInset + DesignSpacing.md)
    }
    
    /// Вычисляет отступ снизу с учётом safe area
    /// Цель: всегда 16pt визуального отступа от нижнего края устройства
    /// - Parameters:
    ///   - safeAreaBottom: Высота safe area снизу (обычно ~34pt на iPhone X и новее)
    ///   - internalVerticalPadding: Внутренний вертикальный padding компонента (12pt для ControlOverlay, 20pt для EffectSelectionView)
    private func bottomPadding(for safeAreaBottom: CGFloat, internalVerticalPadding: CGFloat = DesignSpacing.base) -> CGFloat {
        // На устройствах с home indicator (iPhone X и новее)
        // safeAreaBottom обычно ~34pt
        // Нам нужно 16pt визуального отступа от края устройства
        // Но компоненты уже имеют внутренний вертикальный padding
        // Поэтому возвращаем: safeAreaBottom - внутренний padding
        if safeAreaBottom > 0 {
            // max гарантирует, что не будет отрицательного значения
            return max(safeAreaBottom - internalVerticalPadding, 0)
        }
        // На старых устройствах без home indicator
        // Добавляем фиксированный отступ 16pt
        return DesignSpacing.xl
    }

    /// Top toolbar с Gallery и Help кнопками
    private func topToolbar(proxy: GeometryProxy) -> some View {
        HStack(spacing: DesignSpacing.md) {
            GalleryPreviewButton(image: galleryImage, action: openPhotosApp)
            Spacer(minLength: DesignSpacing.zero)
            DesignIconButton(icon: .question, action: {})
                .accessibilityLabel("Help")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, horizontalPadding(for: proxy.safeAreaInsets))
        .padding(.top, topPadding(for: proxy.safeAreaInsets.top, screenHeight: proxy.size.height))
    }

    /// Вычисляет адаптивный отступ сверху для toolbar
    /// 
    /// Использует комбинацию фиксированных и адаптивных значений с учетом размера экрана.
    ///
    /// **Логика расчета:**
    /// - Для устройств с notch/Dynamic Island: базовый отступ 80pt, 
    ///   но не более 12% от высоты экрана для компактных размеров
    /// - Для старых устройств: статус-бар (20pt) + комфортный отступ (16pt) = 36pt
    ///
    /// - Parameters:
    ///   - safeAreaTop: Значение safeAreaInsets.top
    ///   - screenHeight: Высота экрана для определения типа устройства и адаптации
    /// - Returns: Отступ в точках
    private func topPadding(for safeAreaTop: CGFloat, screenHeight: CGFloat) -> CGFloat {
        // Определяем, является ли устройство современным (с notch/Dynamic Island)
        let isModernDevice = safeAreaTop > 0 || screenHeight >= 800
        
        if isModernDevice {
            // Устройства с notch/Dynamic Island
            // Базовый отступ 80pt, но адаптируем для маленьких экранов
            let baseTopPadding: CGFloat = 80
            let maxTopPaddingRatio: CGFloat = 0.12 // Максимум 12% от высоты экрана
            let maxAllowedPadding = screenHeight * maxTopPaddingRatio
            
            // Используем минимум из базового и максимального допустимого
            return min(baseTopPadding, maxAllowedPadding)
        } else {
            // Старые устройства без notch (iPhone SE, 8, 7 и т.д.)
            // Высота статус-бара (20pt) + комфортный отступ (16pt)
            return 20 + DesignSpacing.xl // 36pt
        }
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
            DesignSurface(.glassButton, cornerRadius: DesignRadius.lg)
                .overlay(
                    Group {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                        .stroke(DesignColor.white, lineWidth: 2)
                )
                .frame(width: 52, height: 52)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }
}
#if DEBUG
@MainActor
private enum RootViewPreviewFactory {
    static func makeViewModel(showCaptureConfirmation: Bool = false) -> AppViewModel {
        DesignSystem.bootstrap()

        let palette = PaletteState(
            background: .preset(.yellow),
            symbols: .solid(.preset(.magenta))
        )

        let viewModel = AppViewModel(
            selectedEffect: .ascii,
            palette: palette,
            previewStatus: .running,
            captureStatus: showCaptureConfirmation ? .success(message: "Saved to Photos") : nil
        )

        viewModel.updatePreview(with: sampleFrame)
        return viewModel
    }

    private static var sampleFrame: PreviewFrame {
        PreviewFrame(
            id: UUID(),
            glyphText: sampleGlyphs,
            columns: 8,
            rows: 4,
            renderedEffect: .ascii
        )
    }

    private static let sampleGlyphs = """
@@##**++
##**++@@
**++@@##
+@@##**
"""
}

@available(iOS 17.0, *)
#Preview("Root View") {
    RootView(
        viewModel: RootViewPreviewFactory.makeViewModel(),
        useDemoPreviewOnAppear: false
    )
    .background(Color.black.ignoresSafeArea())
}

@available(iOS 17.0, *)
#Preview("Root View – Capture Confirmation") {
    RootView(
        viewModel: RootViewPreviewFactory.makeViewModel(showCaptureConfirmation: true),
        useDemoPreviewOnAppear: false
    )
    .background(Color.black.ignoresSafeArea())
}
#endif
#endif
