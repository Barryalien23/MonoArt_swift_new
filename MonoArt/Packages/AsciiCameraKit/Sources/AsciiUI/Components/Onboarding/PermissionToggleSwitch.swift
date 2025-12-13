import SwiftUI

@available(iOS 13.0, *)
struct PermissionToggleSwitch: View {
    @Binding var isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if !isOn {
                action()
            }
        }) {
            HStack(spacing: 0) {
                if isOn {
                    Spacer()
                }

                RoundedRectangle(cornerRadius: DesignRadius.sm)
                    .fill(isOn ? DesignColor.white : DesignColor.white60)
                    .frame(width: 20, height: 20)
                    .shadow(color: DesignColor.black.opacity(0.1), radius: 3, x: 0, y: 0)

                if !isOn {
                    Spacer()
                }
            }
            .padding(.horizontal, 2)
            .frame(width: 44, height: 24)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.sm)
                    .fill(
                        isOn
                        ? AnyShapeStyle(EllipticalGradient(
                            stops: [
                                Gradient.Stop(color: Color(red: 0.46, green: 0.94, blue: 0.54), location: 0.00),
                                Gradient.Stop(color: Color(red: 0.32, green: 0.82, blue: 0.35), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.5)
                        ))
                        : AnyShapeStyle(DesignColor.greyActive)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .disabled(isOn)
    }
}

#if DEBUG
@available(iOS 13.0, *)
#Preview("Toggle Switch") {
    VStack(spacing: 20) {
        PermissionToggleSwitch(isOn: .constant(false)) {}
        PermissionToggleSwitch(isOn: .constant(true)) {}
    }
    .padding()
    .background(DesignColor.black.ignoresSafeArea())
}
#endif
