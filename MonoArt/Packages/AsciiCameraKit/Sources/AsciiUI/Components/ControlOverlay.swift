#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import AsciiSupport
import SwiftUI

private enum ControlOverlayMetrics {
    static let tileHeight: CGFloat = 56
    static let tileMinWidth: CGFloat = 80
    static let effectTileWidth: CGFloat = 64
    static let stackSpacing: CGFloat = DesignSpacing.md

    static var stackedTileHeight: CGFloat {
        (tileHeight * 2) + stackSpacing
    }
}

@available(iOS 15.0, *)
public struct ControlOverlay: View {
    public let selectedEffect: EffectType
    public let availableEffects: [EffectType]
    public let isCaptureInFlight: Bool
    public let isImportMode: Bool
    public let palette: PaletteState
    public let parameters: EffectParameters
    public let selectedColorTarget: ColorTarget
    public let onImport: () -> Void
    public let onCapture: () -> Void
    public let onFlip: () -> Void
    public let onSaveImport: (() -> Void)?
    public let onCancelImport: (() -> Void)?
    public let onSelectEffect: (EffectType) -> Void
    public let onSelectColorTarget: (ColorTarget) -> Void
    public let onShowEffects: () -> Void
    public let onShowSettings: (EffectParameter) -> Void
    public let onShowColors: () -> Void
    public let onParameterChange: ((EffectParameter, Double) -> Void)?

    public init(
        selectedEffect: EffectType,
        availableEffects: [EffectType] = EffectType.allCases,
        isCaptureInFlight: Bool,
        isImportMode: Bool,
        palette: PaletteState,
        parameters: EffectParameters,
        selectedColorTarget: ColorTarget,
        onImport: @escaping () -> Void,
        onCapture: @escaping () -> Void,
        onFlip: @escaping () -> Void,
        onSaveImport: (() -> Void)? = nil,
        onCancelImport: (() -> Void)? = nil,
        onSelectEffect: @escaping (EffectType) -> Void,
        onSelectColorTarget: @escaping (ColorTarget) -> Void,
        onShowEffects: @escaping () -> Void,
        onShowSettings: @escaping (EffectParameter) -> Void,
        onShowColors: @escaping () -> Void,
        onParameterChange: ((EffectParameter, Double) -> Void)? = nil
    ) {
        self.selectedEffect = selectedEffect
        self.availableEffects = availableEffects
        self.isCaptureInFlight = isCaptureInFlight
        self.isImportMode = isImportMode
        self.palette = palette
        self.parameters = parameters
        self.selectedColorTarget = selectedColorTarget
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSaveImport = onSaveImport
        self.onCancelImport = onCancelImport
        self.onSelectEffect = onSelectEffect
        self.onSelectColorTarget = onSelectColorTarget
        self.onShowEffects = onShowEffects
        self.onShowSettings = onShowSettings
        self.onShowColors = onShowColors
        self.onParameterChange = onParameterChange
    }

    public var body: some View {
        VStack(spacing: DesignSpacing.md) {
            DesignActionBar(
                mode: isImportMode ? .import : .camera,
                primaryState: isCaptureInFlight ? .processing : .idle,
                isLocked: false,
                onLeft: onImport,
                onPrimary: isImportMode ? (onSaveImport ?? onCapture) : onCapture,
                onRight: isImportMode ? (onCancelImport ?? onFlip) : onFlip
            )

            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                HStack(alignment: .top, spacing: DesignSpacing.md) {
                    effectTile

                    VStack(alignment: .leading, spacing: DesignSpacing.md) {
                        settingsRow
                            .zIndex(10) // Settings row значительно выше
                        colorRow
                            .zIndex(0) // Color row ниже
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, DesignSpacing.xl)
            .padding(.top, DesignSpacing.xl)
            .padding(.bottom, DesignSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(controllerBackground)
            .shadow(color: DesignColor.black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }

    private var controllerBackground: Color {
        DesignColor.black
    }

    private var effectTile: some View {
        DesignEffectTile(
            icon: effectIcon(for: selectedEffect),
            title: selectedEffect.displayTitle,
            action: onShowEffects
        )
    }

    private var settingsRow: some View {
        HStack(spacing: DesignSpacing.md) {
            DesignParameterTile(
                icon: .settingCell,
                title: "CELL",
                progress: parameters.cell.rawValue / 100.0,
                action: { onShowSettings(.cell) },
                onValueChange: { newValue in
                    onParameterChange?(.cell, newValue)
                }
            )
            DesignParameterTile(
                icon: .settingJitter,
                title: "JITTER",
                progress: parameters.jitter.rawValue / 100.0,
                action: { onShowSettings(.jitter) },
                onValueChange: { newValue in
                    onParameterChange?(.jitter, newValue)
                }
            )
            DesignParameterTile(
                icon: .settingContrast,
                title: "CONTRAST",
                progress: parameters.softy.rawValue / 100.0,
                action: { onShowSettings(.softy) },
                onValueChange: { newValue in
                    onParameterChange?(.softy, newValue)
                }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var colorRow: some View {
        HStack(spacing: DesignSpacing.md) {
            DesignColorTile(
                title: "BG COLOR",
                indicator: .solid(palette.background.swiftUIColor),
                indicatorState: .default,
                isActive: selectedColorTarget == .background,
                action: {
                    onSelectColorTarget(.background)
                    onShowColors()
                }
            )

            DesignColorTile(
                title: "COLOR #2",
                indicator: symbolIndicator,
                indicatorState: symbolIndicatorState,
                isActive: selectedColorTarget == .symbols && !isGradientActive,
                action: {
                    onSelectColorTarget(.symbols)
                    onShowColors()
                }
            )

            DesignColorTile(
                title: "GRADIENT",
                indicator: gradientIndicator,
                indicatorState: isGradientActive ? .default : .disabled,
                isActive: isGradientActive,
                action: {
                    onSelectColorTarget(.symbols)
                    onShowColors()
                }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var symbolIndicator: DesignColorIndicator.Kind {
        switch palette.symbols {
        case .solid(let descriptor):
            return .solid(descriptor.swiftUIColor)
        case .gradient:
            // When gradient is active, show white color in disabled state
            return .solid(DesignColor.white)
        }
    }

    private var symbolIndicatorState: DesignColorIndicator.State {
        if case .gradient = palette.symbols {
            return .disabled
        }
        return .default
    }

    private var gradientIndicator: DesignColorIndicator.Kind {
        switch palette.symbols {
        case .gradient(let stops):
            return .gradient(gradient(from: stops))
        case .solid:
            return .solid(DesignColor.white20)
        }
    }

    private var isGradientActive: Bool {
        if case .gradient = palette.symbols { return true }
        return false
    }

    private func gradient(from stops: [GradientStop]) -> Gradient {
        if stops.isEmpty {
            return Gradient(colors: [DesignColor.white, DesignColor.white60])
        }
        let gradientStops = stops.map {
            Gradient.Stop(color: $0.color.swiftUIColor, location: $0.position)
        }
        return Gradient(stops: gradientStops)
    }

    private func effectIcon(for effect: EffectType) -> DesignIcon {
        switch effect {
        case .ascii: return .effectASCII
        case .shapes: return .effectShapes
        case .circle: return .effectCircle
        case .square: return .effectSquare
        case .triangle: return .effectTriangle
        case .diamond: return .effectDiamond
        }
    }
}

@available(iOS 15.0, *)
private struct DesignEffectTile: View {
    let icon: DesignIcon
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playMedium()
            SoundManager.shared.playClick()
            action()
        }) {
            VStack(spacing: DesignSpacing.s) {
                DesignIconView(icon, color: DesignColor.white, size: 18)
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: ControlOverlayMetrics.effectTileWidth, height: ControlOverlayMetrics.stackedTileHeight)
            .background(tileBackground)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

@available(iOS 15.0, *)
private struct DesignParameterTile: View {
    let icon: DesignIcon
    let title: String
    let progress: Double
    let action: () -> Void
    let onValueChange: ((Double) -> Void)?
    
    @State private var isLongPressing: Bool = false
    @State private var isDragging: Bool = false
    @State private var currentProgress: Double
    @State private var gestureStartProgress: Double = 0
    @State private var gestureStartLocation: CGPoint = .zero
    @State private var longPressTask: Task<Void, Never>?
    
    init(icon: DesignIcon, title: String, progress: Double, action: @escaping () -> Void, onValueChange: ((Double) -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.progress = progress
        self.action = action
        self.onValueChange = onValueChange
        _currentProgress = State(initialValue: progress)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Progress bar background
                Rectangle()
                    .fill(DesignColor.greyActive)
                    .frame(width: geometry.size.width * currentProgress)
                
                // Content layer
                VStack(spacing: isElevated ? DesignSpacing.s + 2 : DesignSpacing.s) {
                    DesignIconView(icon, color: DesignColor.white, size: isElevated ? 20 : 16)
                    
                    DesignTokens.Typography.body1.text(title)
                        .font(.system(size: isElevated ? 15 : 12, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignColor.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(minWidth: ControlOverlayMetrics.tileMinWidth, maxWidth: .infinity)
            .frame(height: ControlOverlayMetrics.tileHeight)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous))
            .scaleEffect(isElevated ? 1.4 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isElevated)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value, in: geometry)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
        }
        .frame(minWidth: ControlOverlayMetrics.tileMinWidth, maxWidth: .infinity)
        .frame(height: ControlOverlayMetrics.tileHeight)
        .zIndex(isElevated ? 9999 : 0)
        .onChange(of: progress) { newValue in
            if !isDragging {
                currentProgress = newValue
            }
        }
        .onDisappear {
            cancelLongPress()
            resetState()
        }
    }
    
    private var isElevated: Bool {
        isLongPressing || isDragging
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(
                color: DesignColor.black.opacity(isElevated ? 0.8 : 0.25),
                radius: isElevated ? 20 : 4,
                x: 0,
                y: isElevated ? 8 : 0
            )
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        // First touch - start long press timer
        if !isLongPressing && !isDragging && longPressTask == nil {
            gestureStartLocation = value.location
            gestureStartProgress = currentProgress
            
            // Start async timer for long press
            longPressTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                
                guard !Task.isCancelled else { return }
                
                // Check if finger hasn't moved too much
                let distance = hypot(value.location.x - gestureStartLocation.x,
                                    value.location.y - gestureStartLocation.y)
                
                if distance < 10 {
                    // Activate long press
                    isLongPressing = true
                    HapticManager.shared.playMedium()
                    SoundManager.shared.playClick()
                }
            }
        }
        
        // If already long pressing, check for drag
        if isLongPressing && !isDragging {
            let dragDistance = abs(value.location.x - gestureStartLocation.x)
            if dragDistance > 3 {
                isDragging = true
            }
        }
        
        // Update parameter while dragging
        if isDragging {
            let dragOffset = value.location.x - gestureStartLocation.x
            let progressDelta = dragOffset / geometry.size.width
            let newProgress = min(max(gestureStartProgress + progressDelta, 0), 1)
            
            if abs(newProgress - currentProgress) > 0.005 {
                let oldProgress = currentProgress
                currentProgress = newProgress
                onValueChange?(newProgress * 100.0)
                
                // Haptic every 5%
                if Int(newProgress * 20) != Int(oldProgress * 20) {
                    HapticManager.shared.playMicro()
                }
            }
        }
    }
    
    private func handleDragEnded() {
        // Check if it was a quick tap
        let wasQuickTap = longPressTask != nil && !isLongPressing && !isDragging
        
        // Cancel the timer
        cancelLongPress()
        
        if wasQuickTap {
            // Quick tap - open sheet
            HapticManager.shared.playMedium()
            SoundManager.shared.playClick()
            action()
        } else if isLongPressing || isDragging {
            // Was elevated - play feedback
            HapticManager.shared.playMedium()
            SoundManager.shared.playClick()
        }
        
        // Reset state
        resetState()
    }
    
    private func cancelLongPress() {
        longPressTask?.cancel()
        longPressTask = nil
    }
    
    private func resetState() {
        isLongPressing = false
        isDragging = false
        gestureStartProgress = 0
        gestureStartLocation = .zero
    }
}

@available(iOS 15.0, *)
private struct DesignColorTile: View {
    let title: String
    let indicator: DesignColorIndicator.Kind
    let indicatorState: DesignColorIndicator.State
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playMedium()
            SoundManager.shared.playClick()
            action()
        }) {
            VStack(spacing: DesignSpacing.s) {
                DesignColorIndicator(kind: indicator, state: indicatorState)
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: ControlOverlayMetrics.tileMinWidth, maxWidth: .infinity)
            .frame(height: ControlOverlayMetrics.tileHeight)
            .background(tileBackground)
            .opacity(isActive ? 1 : 0.9)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
            .fill(DesignColor.mainGrey)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

@available(iOS 15.0, *)
private struct DesignColorIndicator: View {
    enum Kind {
        case solid(Color)
        case gradient(Gradient)
    }

    enum State {
        case `default`
        case disabled
    }

    private let kind: Kind
    private let state: State
    private let size: CGFloat
    private let innerPadding: CGFloat = 3
    private let borderWidth: CGFloat = 1

    init(kind: Kind, state: State = .default, size: CGFloat = 16) {
        self.kind = kind
        self.state = state
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(borderColor, lineWidth: borderWidth)
            fillLayer
                .padding(innerPadding)
        }
        .frame(width: size, height: size)
        .opacity(indicatorOpacity)
    }

    @ViewBuilder
    private var fillLayer: some View {
        switch kind {
        case .solid(let color):
            Circle()
                .fill(color)
        case .gradient(let gradient):
            Circle()
                .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var borderColor: Color {
        switch state {
        case .default:
            return DesignColor.white
        case .disabled:
            return DesignColor.white20
        }
    }

    private var indicatorOpacity: Double {
        switch state {
        case .default:
            return 1
        case .disabled:
            return 0.4
        }
    }
}

#endif

