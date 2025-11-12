import SwiftUI

private enum DesignSize {
    static let iconButton: CGFloat = 52
    static let iconButtonIcon: CGFloat = 24
}

public struct DesignPressFeedbackStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

public struct DesignIconButton: View {
    public enum Style {
        case normal
        case subtle
    }

    private let icon: DesignIcon
    private let style: Style
    private let isEnabled: Bool
    private let accessibilityLabel: String?
    private let action: () -> Void

    public init(
        icon: DesignIcon,
        style: Style = .normal,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                    .fill(buttonFill)

                DesignIconView(icon, color: iconColor, size: DesignSize.iconButtonIcon)
                    .frame(width: DesignSize.iconButtonIcon, height: DesignSize.iconButtonIcon)
            }
            .frame(width: DesignSize.iconButton, height: DesignSize.iconButton, alignment: .center)
            .shadow(color: DesignColor.black.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(DesignPressFeedbackStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(accessibilityLabel ?? icon.rawValue)
    }

    private var buttonFill: Color {
        switch style {
        case .normal:
            return DesignColor.white20
        case .subtle:
            return DesignColor.white04
        }
    }

    private var iconColor: Color {
        DesignColor.white
    }
}

public struct DesignPrimaryButton: View {
    public enum Mode: Equatable {
        case capture
        case save(title: String, icon: DesignIcon = .save)
    }

    public enum State {
        case idle
        case processing
    }

    private let mode: Mode
    private let state: State
    private let isEnabled: Bool
    private let action: () -> Void

    public init(
        mode: Mode,
        state: State = .idle,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.mode = mode
        self.state = state
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                switch mode {
                case .capture:
                    captureButton
                case .save(let title, let icon):
                    saveButton(title: title, icon: icon)
                }
            }
            .frame(width: 120, height: 60)
        }
        .buttonStyle(DesignPressFeedbackStyle())
        .disabled(!isEnabled || state == .processing)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch mode {
        case .capture:
            return state == .processing ? "Capturing photo" : "Capture photo"
        case .save(let title, _):
            return state == .processing ? "Saving photo" : title
        }
    }

    private var captureButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignColor.white20)
                .shadow(color: DesignColor.black.opacity(0.25), radius: 14, x: 0, y: 6)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DesignColor.white20, lineWidth: 2)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(state == .processing ? DesignColor.white20 : DesignColor.white)
                .padding(4)

            if state == .processing {
                progressIndicator(tint: DesignColor.black)
            }
        }
    }

    private func saveButton(title: String, icon: DesignIcon) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignColor.white20)
                .shadow(color: DesignColor.black.opacity(0.25), radius: 14, x: 0, y: 6)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DesignColor.white20, lineWidth: 2)

            HStack(spacing: DesignSpacing.sm) {
                if state == .processing {
                    progressIndicator(tint: DesignColor.white)
                } else {
                    DesignIconView(icon, color: DesignColor.white, size: 16)
                }
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func progressIndicator(tint: Color) -> some View {
        if #available(iOS 16.0, *) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(tint)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .accentColor(tint)
        }
    }
}

public struct DesignActionBar: View {
    public enum Mode {
        case camera
        case `import`
    }

    private let mode: Mode
    private let primaryState: DesignPrimaryButton.State
    private let isLocked: Bool
    private let onLeft: () -> Void
    private let onPrimary: () -> Void
    private let onRight: () -> Void

    public init(mode: Mode,
                primaryState: DesignPrimaryButton.State = .idle,
                isLocked: Bool = false,
                onLeft: @escaping () -> Void,
                onPrimary: @escaping () -> Void,
                onRight: @escaping () -> Void) {
        self.mode = mode
        self.primaryState = primaryState
        self.isLocked = isLocked
        self.onLeft = onLeft
        self.onPrimary = onPrimary
        self.onRight = onRight
    }

    public var body: some View {
        HStack(spacing: DesignSpacing.base) {
            DesignIconButton(icon: leftIcon,
                             style: .normal,
                             isEnabled: !isLocked,
                             accessibilityLabel: leftLabel,
                             action: onLeft)

            DesignPrimaryButton(
                mode: primaryMode,
                state: primaryState,
                isEnabled: !isLocked,
                action: onPrimary
            )

            DesignIconButton(icon: rightIcon,
                             style: .normal,
                             isEnabled: !isLocked,
                             accessibilityLabel: rightLabel,
                             action: onRight)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSpacing.xl)
        .padding(.vertical, DesignSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                .fill(DesignColor.mainGrey.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                        .stroke(DesignColor.white20.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: DesignColor.black.opacity(0.35), radius: 24, x: 0, y: 12)
        )
        .accessibilityElement(children: .contain)
        .accessibilityHint(mode == .camera ? "Camera controls" : "Image import controls")
    }

    private var primaryMode: DesignPrimaryButton.Mode {
        switch mode {
        case .camera:
            return .capture
        case .import:
            return .save(title: "SAVE IMAGE")
        }
    }

    private var rightIcon: DesignIcon {
        switch mode {
        case .camera:
            return .rotateCamera
        case .import:
            return .delete
        }
    }

    private var leftIcon: DesignIcon { .upload }

    private var leftLabel: String { "Import photo" }

    private var rightLabel: String {
        switch mode {
        case .camera:
            return "Flip camera"
        case .import:
            return "Discard imported photo"
        }
    }
}

#if DEBUG
private struct DesignButtonsPreviewContext {
    static func prepare() {
        DesignSystem.bootstrap()
    }
}

private struct IconButtonStylesPreview: View {
    init() {
        DesignButtonsPreviewContext.prepare()
    }

    var body: some View {
        VStack(spacing: DesignSpacing.lg) {
            DesignIconButton(icon: .upload) {}
            DesignIconButton(icon: .delete) {}
            DesignIconButton(icon: .question, style: .subtle, isEnabled: false) {}
        }
        .padding()
        .background(DesignColor.mainGrey.ignoresSafeArea())
    }
}

private struct ActionBarCameraPreview: View {
    init() {
        DesignButtonsPreviewContext.prepare()
    }

    var body: some View {
        DesignActionBar(
            mode: .camera,
            primaryState: .idle,
            onLeft: {},
            onPrimary: {},
            onRight: {}
        )
        .padding()
        .background(DesignColor.black.ignoresSafeArea())
    }
}

private struct ActionBarImportPreview: View {
    init() {
        DesignButtonsPreviewContext.prepare()
    }

    var body: some View {
        DesignActionBar(
            mode: .import,
            primaryState: .processing,
            isLocked: true,
            onLeft: {},
            onPrimary: {},
            onRight: {}
        )
        .padding()
        .background(DesignColor.black.ignoresSafeArea())
    }
}

#Preview("Icon Button Styles") {
    IconButtonStylesPreview()
}

#Preview("Action Bar – Camera") {
    ActionBarCameraPreview()
}

#Preview("Action Bar – Import Locked") {
    ActionBarImportPreview()
}
#endif
