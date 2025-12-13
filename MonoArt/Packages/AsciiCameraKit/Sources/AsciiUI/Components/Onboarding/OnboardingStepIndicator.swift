import SwiftUI

@available(iOS 13.0, *)
struct OnboardingStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: DesignSpacing.s) {
            ForEach(0..<totalSteps, id: \.self) { index in
                StepLine(isActive: index <= currentStep)
            }
        }
    }
}

@available(iOS 13.0, *)
private struct StepLine: View {
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: DesignRadius.sm)
            .fill(isActive ? Color(red: 0.46, green: 0.94, blue: 0.54) : DesignColor.mainGrey)
            .frame(height: 4)
            .shadow(
                color: isActive ? Color(red: 0.7, green: 1, blue: 0.77).opacity(0.45) : .clear,
                radius: 8,
                x: 0,
                y: 0
            )
    }
}

#if DEBUG
@available(iOS 13.0, *)
#Preview("Step Indicator") {
    VStack(spacing: 20) {
        OnboardingStepIndicator(currentStep: 0, totalSteps: 4)
            .padding()
        OnboardingStepIndicator(currentStep: 1, totalSteps: 4)
            .padding()
        OnboardingStepIndicator(currentStep: 2, totalSteps: 4)
            .padding()
        OnboardingStepIndicator(currentStep: 3, totalSteps: 4)
            .padding()
    }
    .frame(maxWidth: .infinity)
    .background(DesignColor.black.ignoresSafeArea())
}
#endif
