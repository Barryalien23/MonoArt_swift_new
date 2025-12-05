#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import AsciiSupport
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Color picker sheet matching Figma design with HSV picker, opacity slider, and gradient support
@available(iOS 16.0, *)
public struct ColorPickerSheet: View {
    @ObservedObject private var viewModel: AppViewModel
    @State private var selectedTab: ColorTab = .bgColor
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var opacity: Double = 1
    @State private var selectedGradientKnob: Int = 0
    
    public let onImport: (() -> Void)?
    public let onCapture: (() -> Void)?
    public let onFlip: (() -> Void)?
    public let onSaveImport: (() -> Void)?
    public let onCancelImport: (() -> Void)?
    
    public init(
        viewModel: AppViewModel,
        onImport: (() -> Void)? = nil,
        onCapture: (() -> Void)? = nil,
        onFlip: (() -> Void)? = nil,
        onSaveImport: (() -> Void)? = nil,
        onCancelImport: (() -> Void)? = nil
    ) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSaveImport = onSaveImport
        self.onCancelImport = onCancelImport
        
        // Set initial tab based on what user clicked
        // selectedColorTarget tells us which button was pressed
        if viewModel.selectedColorTarget == .background {
            _selectedTab = State(initialValue: .bgColor)
        } else {
            // User clicked COLOR #2 or GRADIENT
            // Open color1 tab (user wants to edit mono color or switch from gradient)
            _selectedTab = State(initialValue: .color1)
        }
    }
    
    public var body: some View {
        VStack(spacing: DesignSpacing.md) {
            // Action bar (same as effect selection)
            DesignActionBar(
                mode: viewModel.isImportMode ? .import : .camera,
                primaryState: viewModel.isCaptureInFlight ? .processing : .idle,
                isLocked: false,
                onLeft: onImport ?? {},
                onPrimary: viewModel.isImportMode ? (onSaveImport ?? onCapture ?? {}) : (onCapture ?? {}),
                onRight: viewModel.isImportMode ? (onCancelImport ?? onFlip ?? {}) : (onFlip ?? {})
            )
            
            // Color picker block
            colorPickerBlock
        }
        .onAppear {
            updateHSVFromCurrentColor()
        }
    }
    
    private var colorPickerBlock: some View {
        VStack(spacing: DesignSpacing.md) {
            // Three-tab selector
            tabSelector
            
            // Gradient slider (only visible in gradient mode)
            if selectedTab == .gradient {
                gradientSlider
            }
            
            // Color picker panels
            colorPickerPanels
            
            // Hue slider and back button
            bottomControls
        }
        .padding(DesignSpacing.xl)
        .background(DesignColor.black)
        .shadow(color: DesignColor.black.opacity(0.4), radius: 24, x: 0, y: 12)
    }
    
    private var tabSelector: some View {
        HStack(spacing: DesignSpacing.md) {
            tabButton(.bgColor, "BG COLOR", bgColorIndicator)
            tabButton(.color1, "COLOR #2", color1Indicator)
            tabButton(.gradient, "GRADIENT", gradientIndicator)
        }
    }
    
    private func tabButton(_ tab: ColorTab, _ title: String, _ indicator: some View) -> some View {
        Button {
            HapticManager.shared.playMicro()
            SoundManager.shared.playClick()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
                
                // Initialize gradient when switching to gradient tab
                if tab == .gradient, case .solid = viewModel.palette.symbols {
                    viewModel.selectColorTarget(.symbols)
                    viewModel.setSymbolGradientEnabled(true)
                }
                
                updateHSVFromCurrentColor()
            }
        } label: {
            HStack(spacing: DesignSpacing.sm) {
                indicator
                    .frame(width: 16, height: 16)
                DesignTokens.Typography.body2.text(title)
                    .foregroundColor(selectedTab == tab ? DesignColor.white : DesignColor.white40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.sm, style: .continuous)
                    .fill(selectedTab == tab ? DesignColor.greyActive : DesignColor.greyDisable)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var bgColorIndicator: some View {
        colorIndicatorView(for: viewModel.palette.background, isActive: selectedTab == .bgColor)
    }
    
    private var color1Indicator: some View {
        Group {
            if case .solid(let color) = viewModel.palette.symbols {
                colorIndicatorView(for: color, isActive: selectedTab == .color1)
            } else {
                // Disabled mono indicator when gradient is active
                ZStack {
                    Circle()
                        .strokeBorder(DesignColor.white20, lineWidth: 1)
                    Circle()
                        .fill(DesignColor.white)
                        .padding(3)
                }
                .opacity(0.4)
            }
        }
    }
    
    private var gradientIndicator: some View {
        Group {
            if case .gradient(let stops) = viewModel.palette.symbols {
                gradientIndicatorView(stops: stops, isActive: selectedTab == .gradient)
            } else {
                // Disabled gradient indicator
                ZStack {
                    Circle()
                        .strokeBorder(DesignColor.white20, lineWidth: 1)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignColor.white40, DesignColor.white20],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(3)
                }
                .opacity(0.4)
            }
        }
    }
    
    private func colorIndicatorView(for color: ColorDescriptor, isActive: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(DesignColor.white, lineWidth: 1)
            Circle()
                .fill(color.swiftUIColor)
                .padding(3)
        }
        .opacity(isActive ? 1.0 : 0.4)
    }
    
    private func gradientIndicatorView(stops: [GradientStop], isActive: Bool) -> some View {
        let colors = stops.map { $0.color.swiftUIColor }
        return ZStack {
            Circle()
                .strokeBorder(DesignColor.white, lineWidth: 1)
            Circle()
                .fill(
                    LinearGradient(
                        colors: colors.isEmpty ? [.white, .white] : colors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(3)
        }
        .opacity(isActive ? 1.0 : 0.4)
    }
    
    // MARK: - Gradient Slider
    
    private var gradientSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient background
                if case .gradient(let stops) = viewModel.palette.symbols {
                    let colors = stops.map { $0.color.swiftUIColor }
                    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colors.isEmpty ? [.white, .white] : colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Two knobs
                    ForEach(0..<stops.count, id: \.self) { index in
                        gradientKnob(index: index, totalWidth: geometry.size.width)
                    }
                }
            }
        }
        .frame(height: 40)
    }
    
    private func gradientKnob(index: Int, totalWidth: CGFloat) -> some View {
        let stops = viewModel.symbolGradientStops
        guard stops.indices.contains(index) else {
            return AnyView(EmptyView())
        }
        
        let position = stops[index].position
        let xOffset = position * (totalWidth - 40)
        let isActive = selectedGradientKnob == index
        
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .strokeBorder(isActive ? DesignColor.white : DesignColor.white60, lineWidth: 3)
                    .padding(2)
            }
            .frame(width: 40, height: 40)
            .offset(x: xOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if selectedGradientKnob != index {
                            HapticManager.shared.playMicro()
                        }
                        selectedGradientKnob = index
                        let newPosition = max(0, min(1, value.location.x / totalWidth))
                        viewModel.updateSymbolGradientPosition(at: index, position: newPosition)
                        updateHSVFromGradientStop(index)
                    }
            )
            .onTapGesture {
                HapticManager.shared.playMicro()
                SoundManager.shared.playClick()
                selectedGradientKnob = index
                updateHSVFromGradientStop(index)
            }
        )
    }
    
    // MARK: - Color Picker Panels
    
    private var colorPickerPanels: some View {
        HStack(spacing: DesignSpacing.md) {
            // Saturation/Value panel
            saturationValuePanel
            
            // Opacity slider
            opacitySlider
        }
        .frame(height: 118)
    }
    
    private var saturationValuePanel: some View {
        GeometryReader { geometry in
            ZStack {
                // Base hue color
                Rectangle()
                    .fill(Color(hue: hue, saturation: 1, brightness: 1))
                
                // White to transparent (saturation)
                LinearGradient(
                    colors: [.white, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                // Transparent to black (brightness)
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Knob with 2pt padding
                ZStack {
                    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                        .strokeBorder(DesignColor.white, lineWidth: 3)
                        .padding(2)
                }
                .frame(width: 40, height: 40)
                .position(
                    x: saturation * geometry.size.width,
                    y: (1 - brightness) * geometry.size.height
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let widthValue = Double(geometry.size.width)
                        let heightValue = Double(geometry.size.height)
                        let newSaturation = max(0, min(1, Double(value.location.x) / widthValue))
                        let newBrightness = max(0, min(1, 1.0 - (Double(value.location.y) / heightValue)))
                        
                        // Play progressive haptic based on brightness level
                        if abs(newSaturation - saturation) > 0.02 || abs(newBrightness - brightness) > 0.02 {
                            HapticManager.shared.playSliderFeedback(progress: newBrightness)
                        }
                        
                        saturation = newSaturation
                        brightness = newBrightness
                        applyColorChange()
                    }
            )
        }
    }
    
    private var opacitySlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Checkerboard background
                checkerboardPattern
                
                // Color with opacity gradient
                LinearGradient(
                    colors: [
                        Color(hue: hue, saturation: saturation, brightness: brightness),
                        Color(hue: hue, saturation: saturation, brightness: brightness).opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Knob with 2pt padding
                ZStack {
                    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                        .strokeBorder(DesignColor.white, lineWidth: 3)
                        .padding(2)
                }
                .frame(width: 40, height: 40)
                .offset(y: (1 - opacity) * (geometry.size.height - 40))
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let heightValue = Double(geometry.size.height)
                        let newOpacity = max(0, min(1, 1.0 - (Double(value.location.y) / heightValue)))
                        
                        // Play progressive haptic based on opacity level
                        if abs(newOpacity - opacity) > 0.02 {
                            HapticManager.shared.playSliderFeedback(progress: newOpacity)
                        }
                        
                        opacity = newOpacity
                        applyColorChange()
                    }
            )
        }
        .frame(width: 40)
    }
    
    private var checkerboardPattern: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let squareSize: CGFloat = 8
                let rows = Int(ceil(size.height / squareSize))
                let cols = Int(ceil(size.width / squareSize))
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let isEven = (row + col) % 2 == 0
                        let rect = CGRect(
                            x: CGFloat(col) * squareSize,
                            y: CGFloat(row) * squareSize,
                            width: squareSize,
                            height: squareSize
                        )
                        context.fill(
                            Path(rect),
                            with: .color(isEven ? Color(white: 0.9) : Color(white: 0.7))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        HStack(spacing: DesignSpacing.md) {
            // Hue slider
            hueSlider
            
            // Back button with 16pt icon
            Button {
                HapticManager.shared.playMedium()
                SoundManager.shared.playClick()
                viewModel.dismissColorPicker()
            } label: {
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(DesignColor.mainGrey)
                    .frame(width: 40, height: 40)
                    .overlay(
                        DesignIconView(.arrowBack16, color: DesignColor.white)
                            .offset(x: -6, y: -2)
                    )
            }
            .buttonStyle(DesignPressFeedbackStyle())
        }
        .frame(height: 40)
    }
    
    private var hueSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Rainbow gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hue: 0, saturation: 1, brightness: 1),
                        Color(hue: 0.17, saturation: 1, brightness: 1),
                        Color(hue: 0.33, saturation: 1, brightness: 1),
                        Color(hue: 0.5, saturation: 1, brightness: 1),
                        Color(hue: 0.67, saturation: 1, brightness: 1),
                        Color(hue: 0.83, saturation: 1, brightness: 1),
                        Color(hue: 1, saturation: 1, brightness: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous))
                
                // Knob with 2pt padding
                ZStack {
                    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                        .strokeBorder(DesignColor.white, lineWidth: 3)
                        .padding(2)
                }
                .frame(width: 40, height: 40)
                .offset(x: hue * (geometry.size.width - 40))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newHue = max(0, min(1, value.location.x / geometry.size.width))
                        
                        // Play progressive haptic based on hue position
                        if abs(newHue - hue) > 0.02 {
                            HapticManager.shared.playSliderFeedback(progress: newHue)
                        }
                        
                        hue = newHue
                        applyColorChange()
                    }
            )
        }
    }
    
    // MARK: - Color Management
    
    private func updateHSVFromCurrentColor() {
        let color: ColorDescriptor
        
        switch selectedTab {
        case .bgColor:
            color = viewModel.palette.background
        case .color1:
            if case .solid(let solidColor) = viewModel.palette.symbols {
                color = solidColor
            } else {
                color = .preset(.white)
            }
        case .gradient:
            if case .gradient(let stops) = viewModel.palette.symbols {
                if stops.isEmpty {
                    color = .preset(.white)
                } else if stops.indices.contains(selectedGradientKnob) {
                    color = stops[selectedGradientKnob].color
                } else {
                    selectedGradientKnob = 0
                    color = stops[0].color
                }
            } else {
                // Fallback (should not happen as gradient is initialized in tabButton)
                color = .preset(.white)
            }
        }
        
        let (h, s, b, a) = colorToHSV(color)
        hue = h
        saturation = s
        brightness = b
        opacity = a
    }
    
    private func updateHSVFromGradientStop(_ index: Int) {
        guard case .gradient(let stops) = viewModel.palette.symbols,
              stops.indices.contains(index) else { return }
        
        let color = stops[index].color
        let (h, s, b, a) = colorToHSV(color)
        hue = h
        saturation = s
        brightness = b
        opacity = a
    }
    
    private func applyColorChange() {
        let newColor = ColorDescriptor(
            red: colorComponent(hue: hue, saturation: saturation, brightness: brightness, index: 0),
            green: colorComponent(hue: hue, saturation: saturation, brightness: brightness, index: 1),
            blue: colorComponent(hue: hue, saturation: saturation, brightness: brightness, index: 2),
            alpha: opacity
        )
        
        switch selectedTab {
        case .bgColor:
            // First set the target, then update the color
            viewModel.selectColorTarget(.background)
            viewModel.setSolidColor(newColor)
        case .color1:
            // First set the target, then update the color
            viewModel.selectColorTarget(.symbols)
            // When changing mono color, reset gradient
            if case .gradient = viewModel.palette.symbols {
                viewModel.setSymbolGradientEnabled(false)
            }
            viewModel.setSolidColor(newColor)
        case .gradient:
            viewModel.selectColorTarget(.symbols)
            // Ensure gradient is enabled
            if case .solid = viewModel.palette.symbols {
                viewModel.setSymbolGradientEnabled(true)
            }
            viewModel.updateSymbolGradientColor(at: selectedGradientKnob, color: newColor)
        }
    }
    
    // MARK: - Color Conversion Helpers
    
    private func colorToHSV(_ color: ColorDescriptor) -> (h: Double, s: Double, b: Double, a: Double) {
        #if canImport(UIKit)
        let uiColor = UIColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b), Double(a))
        #else
        return (0, 1, 1, 1)
        #endif
    }
    
    private func colorComponent(hue: Double, saturation: Double, brightness: Double, index: Int) -> Double {
        #if canImport(UIKit)
        let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [Double(r), Double(g), Double(b)][index]
        #else
        return 0
        #endif
    }
}

// MARK: - ColorTab Enum

private enum ColorTab: String, CaseIterable {
    case bgColor = "BG COLOR"
    case color1 = "COLOR #1"
    case gradient = "GRADIENT"
}

// MARK: - Helper Extension

private extension SymbolColor {
    var solidColor: ColorDescriptor? {
        if case .solid(let color) = self {
            return color
        }
        return nil
    }
}

#endif
