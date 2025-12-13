import SwiftUI
import AsciiSupport

// MARK: - Primary Onboarding Button

@available(iOS 13.0, *)
struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playShort()
            SoundManager.shared.playClick()
            action()
        }) {
            Text(title)
                .font(.custom("IBMPlexMono-SemiBold", size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(DesignColor.black)
                .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                .background(
                    EllipticalGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.46, green: 0.94, blue: 0.54), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.32, green: 0.82, blue: 0.35), location: 1.00)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.5)
                    )
                )
                .cornerRadius(DesignRadius.md)
                .shadow(
                    color: Color(red: 0.7, green: 1, blue: 0.77).opacity(0.45),
                    radius: 4,
                    x: 0,
                    y: 0
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.md)
                        .inset(by: 0.5)
                        .stroke(DesignColor.white20, lineWidth: 1)
                )
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }
}

// MARK: - Skip Button

@available(iOS 13.0, *)
struct OnboardingSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playMedium()
            SoundManager.shared.playClick()
            action()
        }) {
            Text("Skip")
                .font(.custom("IBMPlexMono-Medium", size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(DesignColor.greyActive)
                .padding(.horizontal, DesignSpacing.xl)
                .padding(.vertical, DesignSpacing.md)
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }
}

#if DEBUG
@available(iOS 13.0, *)
#Preview("Onboarding Buttons") {
    VStack(spacing: 20) {
        OnboardingPrimaryButton(title: "Next") {}
            .padding()

        OnboardingSkipButton {}
    }
    .frame(maxWidth: .infinity)
    .background(DesignColor.black.ignoresSafeArea())
}
#endif
