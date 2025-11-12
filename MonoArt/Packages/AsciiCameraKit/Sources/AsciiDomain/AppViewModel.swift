#if canImport(Combine)
import Combine
#endif
import Dispatch
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Observable reducer that mirrors the Android MainViewModel intent surface.
/// Implementation intentionally minimal; refer to SwiftStarterBundle/Docs/Swift/Architecture.md before extending.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class AppViewModel: ObservableObject {
    @Published public private(set) var selectedEffect: EffectType
    @Published public private(set) var parameters: EffectParameters
    @Published public private(set) var palette: PaletteState
    @Published public private(set) var cameraFacing: CameraFacing
    @Published public private(set) var previewStatus: PreviewStatus
    @Published public private(set) var previewFrame: PreviewFrame?
#if canImport(UIKit)
    @Published public private(set) var previewImage: UIImage?
    @Published public private(set) var importedImage: UIImage?
    @Published public private(set) var isImportMode: Bool = false
    @Published public private(set) var lastSavedImage: UIImage?
#endif
    @Published public private(set) var isCaptureInFlight: Bool
    @Published public private(set) var captureStatus: CaptureStatus?
    @Published public private(set) var selectedColorTarget: ColorTarget

    @Published public var isSettingsPresented: Bool
    @Published public var isColorPickerPresented: Bool
    @Published public var isEffectSelectionPresented: Bool

    public init(
        selectedEffect: EffectType = .ascii,
        parameters: EffectParameters = EffectParameters(),
        palette: PaletteState = PaletteState(),
        cameraFacing: CameraFacing = .back,
        previewStatus: PreviewStatus = .idle,
        previewFrame: PreviewFrame? = nil,
        isCaptureInFlight: Bool = false,
        captureStatus: CaptureStatus? = nil,
        selectedColorTarget: ColorTarget = .symbols,
        isSettingsPresented: Bool = false,
        isColorPickerPresented: Bool = false,
        isEffectSelectionPresented: Bool = false
    ) {
        self.selectedEffect = selectedEffect
        self.parameters = AppViewModel.normalizedParameters(for: selectedEffect, existing: parameters)
        self.palette = palette
        self.cameraFacing = cameraFacing
        self.previewStatus = previewStatus
        self.previewFrame = previewFrame
#if canImport(UIKit)
        self.previewImage = nil
#endif
#if canImport(UIKit)
        self.importedImage = nil
#endif
#if canImport(UIKit)
        self.isImportMode = false
#endif
#if canImport(UIKit)
        self.lastSavedImage = nil
#endif
        self.isCaptureInFlight = isCaptureInFlight
        self.captureStatus = captureStatus
        self.selectedColorTarget = selectedColorTarget
        self.isSettingsPresented = isSettingsPresented
        self.isColorPickerPresented = isColorPickerPresented
        self.isEffectSelectionPresented = isEffectSelectionPresented

        if previewFrame == nil && previewStatus == .running {
            self.previewStatus = .idle
        }
    }

    // MARK: - Effect Selection & Parameters

    public func selectEffect(_ effect: EffectType) {
        guard effect != selectedEffect else { return }
        selectedEffect = effect
        // Keep current parameters when switching effects (user preference preservation)
        // No need to reset to defaults - user settings should persist
    }

    public func updateParameter(_ parameter: EffectParameter, value: Double) {
        let adjustedValue: Double
        if selectedEffect == .circles && parameter == .jitter {
            // Circles effect clamps jitter to multiples of five for deterministic animation, matching Android logic.
            adjustedValue = (value / 5.0).rounded() * 5.0
        } else {
            adjustedValue = value
        }
        parameters.update(parameter, value: adjustedValue)
    }

    public func resetParametersToDefaults() {
        parameters = AppViewModel.applyDefaults(for: selectedEffect, onto: parameters)
    }

    // MARK: - Camera Controls

    public func toggleCameraFacing() {
        cameraFacing = cameraFacing == .back ? .front : .back
    }

    // MARK: - Preview Lifecycle

    public func beginPreviewLoading() {
        previewStatus = .loading
        previewFrame = nil
#if canImport(UIKit)
        previewImage = nil
        importedImage = nil
        isImportMode = false
#endif
    }

    public func updatePreview(with frame: PreviewFrame) {
        previewFrame = frame
        previewStatus = .running
#if canImport(UIKit)
        if !isImportMode {
            previewImage = nil
            importedImage = nil
        }
#endif
    }

    public func failPreview(message: String) {
        previewStatus = .failed(.init(message: message))
        previewFrame = nil
#if canImport(UIKit)
        previewImage = nil
        importedImage = nil
        isImportMode = false
#endif
    }

#if canImport(UIKit)
    public func updatePreviewImage(_ image: UIImage?) {
        if let image {
            previewImage = image
            previewFrame = nil
            previewStatus = .running
        } else {
            previewImage = nil
        }
    }

    public func beginImport(previewImage image: UIImage?) {
        importedImage = image
        isImportMode = true
        previewFrame = nil
        if let image {
            previewImage = image
            previewStatus = .running
        } else {
            previewImage = nil
            previewStatus = .loading
        }
    }

    public func cancelImport() {
        importedImage = nil
        isImportMode = false
        previewImage = nil
        previewFrame = nil
        previewStatus = .idle
    }

    public func completeImport() {
        importedImage = nil
        isImportMode = false
        previewImage = nil
        previewFrame = nil
        previewStatus = .loading
    }
#endif

    // MARK: - Capture Flow

    public func beginCapture() {
        guard !isCaptureInFlight else { return }
        isCaptureInFlight = true
        captureStatus = nil
    }

    public func simulateCapture() {
        beginCapture()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            self.isCaptureInFlight = false
            self.captureStatus = .success(message: "Saved to Photos")
        }
    }

    public func resolveCapture(with status: CaptureStatus) {
        isCaptureInFlight = false
        captureStatus = status
    }

#if canImport(UIKit)
    public func updateLastSavedImage(_ image: UIImage?) {
        lastSavedImage = image
    }
#endif

    public func dismissCaptureStatus() {
        captureStatus = nil
    }

    // MARK: - Sheet Presentation

    public func presentSettingsSheet() {
        isSettingsPresented = true
    }

    public func dismissSettingsSheet() {
        isSettingsPresented = false
    }

    public func presentColorPicker(for target: ColorTarget) {
        selectedColorTarget = target
        isColorPickerPresented = true
    }

    public func dismissColorPicker() {
        isColorPickerPresented = false
    }

    public func presentEffectSelection() {
        isEffectSelectionPresented = true
    }

    public func dismissEffectSelection() {
        isEffectSelectionPresented = false
    }

    // MARK: - Color Management

    public var isGradientEditingEnabled: Bool {
        selectedColorTarget == .symbols
    }

    public var isSymbolGradientEnabled: Bool {
        if case .gradient = palette.symbols { return true }
        return false
    }

    public var symbolGradientStops: [GradientStop] {
        if case let .gradient(stops) = palette.symbols {
            return stops
        }
        return []
    }

    public func selectColorTarget(_ target: ColorTarget) {
        selectedColorTarget = target
    }

    public func setSolidColor(_ descriptor: ColorDescriptor) {
        switch selectedColorTarget {
        case .background:
            palette.background = descriptor
        case .symbols:
            palette.symbols = .solid(descriptor)
        }
    }

    public func setSymbolGradientEnabled(_ isEnabled: Bool) {
        guard selectedColorTarget == .symbols else { return }
        if isEnabled {
            if case .gradient = palette.symbols { return }
            let baseColor: ColorDescriptor
            switch palette.symbols {
            case .solid(let descriptor):
                baseColor = descriptor
            case .gradient(let stops):
                baseColor = stops.first?.color ?? .preset(.white)
            }
            let fallback = GradientStop(position: 0, color: baseColor)
            let end = GradientStop(position: 1, color: baseColor)
            palette.symbols = .gradient([fallback, end])
        } else {
            switch palette.symbols {
            case .solid:
                break
            case .gradient(let stops):
                let firstColor = stops.first?.color ?? .preset(.white)
                palette.symbols = .solid(firstColor)
            }
        }
    }

    public func updateSymbolGradientColor(at index: Int, color: ColorDescriptor) {
        guard selectedColorTarget == .symbols else { return }
        guard case var .gradient(stops) = palette.symbols, stops.indices.contains(index) else { return }
        stops[index] = GradientStop(position: stops[index].position, color: color)
        palette.symbols = .gradient(AppViewModel.normalizedGradientStops(stops))
    }

    public func updateSymbolGradientPosition(at index: Int, position: Double) {
        guard selectedColorTarget == .symbols else { return }
        guard case var .gradient(stops) = palette.symbols, stops.indices.contains(index) else { return }
        stops[index] = GradientStop(position: position, color: stops[index].color)
        palette.symbols = .gradient(AppViewModel.normalizedGradientStops(stops))
    }

    public func addSymbolGradientStop() {
        guard selectedColorTarget == .symbols else { return }
        guard case var .gradient(stops) = palette.symbols else { return }
        let mid = GradientStop(position: 0.5, color: stops.last?.color ?? .preset(.white))
        stops.append(mid)
        palette.symbols = .gradient(AppViewModel.normalizedGradientStops(stops))
    }

    public func removeSymbolGradientStop(at index: Int) {
        guard selectedColorTarget == .symbols else { return }
        guard case var .gradient(stops) = palette.symbols, stops.indices.contains(index) else { return }
        guard stops.count > 2 else { return }
        stops.remove(at: index)
        palette.symbols = .gradient(AppViewModel.normalizedGradientStops(stops))
    }

    // MARK: - Demo Helpers

    /// Populates the preview with a synthetic frame so designers can iterate without the engine.
    public func startDemoPreviewIfNeeded() {
        guard previewFrame == nil else { return }
        let demoText = "▒░▒░▒░\n░▒░▒░▒\n▒░▒░▒░"
        let frame = PreviewFrame(
            id: UUID(),
            glyphText: demoText,
            columns: 6,
            rows: 3,
            renderedEffect: selectedEffect
        )
        updatePreview(with: frame)
    }

    // MARK: - Helpers

    private static func normalizedParameters(for effect: EffectType, existing: EffectParameters) -> EffectParameters {
        applyDefaults(for: effect, onto: existing)
    }

    private static func applyDefaults(for effect: EffectType, onto current: EffectParameters) -> EffectParameters {
        guard let defaults = effectDefaults[effect] else { return current }
        var next = current
        if effect.supportedParameters.contains(.cell) {
            next.cell = defaults.cell
        }
        if effect.supportedParameters.contains(.jitter) {
            next.jitter = defaults.jitter
        }
        if effect.supportedParameters.contains(.softy) {
            next.softy = defaults.softy
        }
        return next
    }

    private static func normalizedGradientStops(_ stops: [GradientStop]) -> [GradientStop] {
        let clamped = stops.map { GradientStop(position: min(max($0.position, 0), 1), color: $0.color) }
        return clamped.sorted { $0.position < $1.position }
    }

    private static let effectDefaults: [EffectType: EffectParameters] = [
        .ascii: EffectParameters(),
        .shapes: EffectParameters(),
        .circles: EffectParameters(),
        .squares: EffectParameters(),
        .triangles: EffectParameters(),
        .diamonds: EffectParameters()
    ]
}

public enum CameraFacing: String, Codable, CaseIterable, Sendable {
    case front
    case back
}

public enum PreviewStatus: Equatable, Sendable {
    public struct Failure: Equatable, Sendable {
        public let message: String

        public init(message: String) {
            self.message = message
        }
    }

    case idle
    case loading
    case running
    case failed(Failure)
}

public struct PreviewFrame: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let glyphText: String
    public let columns: Int
    public let rows: Int
    public let renderedEffect: EffectType

    public init(id: UUID, glyphText: String, columns: Int, rows: Int, renderedEffect: EffectType) {
        self.id = id
        self.glyphText = glyphText
        self.columns = columns
        self.rows = rows
        self.renderedEffect = renderedEffect
    }
}

public enum ColorTarget: String, Codable, CaseIterable, Sendable {
    case background
    case symbols
}

public enum CaptureStatus: Equatable, Identifiable, Sendable {
    public var id: UUID {
        switch self {
        case .success(let payload):
            return payload.id
        case .failure(let payload):
            return payload.id
        }
    }

    case success(Payload)
    case failure(Payload)

    public struct Payload: Equatable, Sendable {
        public let id: UUID
        public let message: String

        public init(id: UUID = UUID(), message: String) {
            self.id = id
            self.message = message
        }
    }

    public static func success(message: String) -> CaptureStatus {
        .success(.init(message: message))
    }

    public static func failure(message: String) -> CaptureStatus {
        .failure(.init(message: message))
    }
}

