#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

@available(iOS 15.0, *)
public struct ParameterEditingOverlay: View {
    @ObservedObject private var viewModel: AppViewModel
    private let selectedParameter: EffectParameter
    private let onBack: () -> Void
    private let onImport: () -> Void
    private let onCapture: () -> Void
    private let onFlip: () -> Void
    private let onSaveImport: (() -> Void)?
    private let onCancelImport: (() -> Void)?
    
    @State private var isDragging = false
    
    public init(
        viewModel: AppViewModel,
        selectedParameter: EffectParameter,
        onBack: @escaping () -> Void,
        onImport: @escaping () -> Void,
        onCapture: @escaping () -> Void,
        onFlip: @escaping () -> Void,
        onSaveImport: (() -> Void)? = nil,
        onCancelImport: (() -> Void)? = nil
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.selectedParameter = selectedParameter
        self.onBack = onBack
        self.onImport = onImport
        self.onCapture = onCapture
        self.onFlip = onFlip
        self.onSaveImport = onSaveImport
        self.onCancelImport = onCancelImport
    }
    
    public var body: some View {
        VStack(spacing: DesignSpacing.md) {
            // Action bar with upload, capture, and flip/delete buttons
            DesignActionBar(
                mode: viewModel.isImportMode ? .import : .camera,
                primaryState: viewModel.isCaptureInFlight ? .processing : .idle,
                isLocked: false,
                onLeft: onImport,
                onPrimary: viewModel.isImportMode ? (onSaveImport ?? onCapture) : onCapture,
                onRight: viewModel.isImportMode ? (onCancelImport ?? onFlip) : onFlip
            )
            
            // Parameter editing container
            VStack(spacing: DesignSpacing.base) {
                // Tabs for parameter selection
                parameterTabs
                
                // Slider container
                sliderContainer
            }
            .padding(.horizontal, DesignSpacing.xl)
            .padding(.top, DesignSpacing.xl)
            .padding(.bottom, DesignSpacing.base)
            .background(DesignColor.black)
            .shadow(color: DesignColor.black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }
    
    private var parameterTabs: some View {
        HStack(spacing: DesignSpacing.md) {
            ForEach(EffectParameter.allCases, id: \.self) { parameter in
                ParameterTabButton(
                    parameter: parameter,
                    isSelected: parameter == selectedParameter,
                    isEnabled: viewModel.selectedEffect.supportedParameters.contains(parameter),
                    action: {
                        if viewModel.selectedEffect.supportedParameters.contains(parameter) {
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.selectParameterForEditing(parameter)
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var sliderContainer: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background with rounded corners
                RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                    .fill(DesignColor.mainGrey)
                
                // Progress bar - прямоугольный, без скругления и тени
                Rectangle()
                    .fill(DesignColor.greyActive)
                    .frame(width: progressWidth(totalWidth: geometry.size.width))
                
                // Content layer
                HStack {
                    // Value display (0-100)
                    DesignTokens.Typography.head1.text("\(Int(currentValue))")
                        .foregroundColor(DesignColor.white)
                    
                    Spacer()
                    
                    // Back arrow button (50×50 container, 16px icon aligned to right)
                    Button(action: onBack) {
                        HStack(spacing: 0) {
                            Spacer()
                            DesignIconView(.arrowBack, color: DesignColor.white, size: 16)
                        }
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSpacing.xxl)
            }
            .frame(height: 76)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                        }
                        updateValue(for: gesture.location.x, totalWidth: geometry.size.width)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 76)
    }
    
    private var currentValue: Double {
        switch selectedParameter {
        case .cell:
            return viewModel.parameters.cell.rawValue
        case .jitter:
            return viewModel.parameters.jitter.rawValue
        case .softy:
            return viewModel.parameters.softy.rawValue
        }
    }
    
    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let progress = currentValue / 100.0
        return max(0, totalWidth * progress)
    }
    
    private func updateValue(for locationX: CGFloat, totalWidth: CGFloat) {
        let progress = max(0, min(1, locationX / totalWidth))
        let newValue = progress * 100.0
        let roundedValue = newValue.rounded()
        
        // Apply clamping for specific effects
        let finalValue: Double
        if viewModel.selectedEffect == .circle && selectedParameter == .jitter {
            // Circle effect clamps jitter to multiples of 5
            finalValue = (roundedValue / 5.0).rounded() * 5.0
        } else {
            finalValue = roundedValue
        }
        
        viewModel.updateParameter(selectedParameter, value: finalValue)
    }
}

@available(iOS 15.0, *)
private struct ParameterTabButton: View {
    let parameter: EffectParameter
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.sm) {
                DesignIconView(
                    icon(for: parameter),
                    color: textColor,
                    size: 16
                )
                
                DesignTokens.Typography.body2.text(parameter.displayName.uppercased())
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.md)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
    
    private var textColor: Color {
        if !isEnabled {
            return DesignColor.white40
        }
        return isSelected ? DesignColor.white : DesignColor.white40
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignColor.greyActive
        }
        return DesignColor.greyDisable
    }
    
    private func icon(for parameter: EffectParameter) -> DesignIcon {
        switch parameter {
        case .cell: return .settingCell
        case .jitter: return .settingJitter
        case .softy: return .settingContrast
        }
    }
}

#endif

