#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import AsciiDomain

@available(iOS 14.0, *)
public struct OnboardingView: View {
    @ObservedObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: OnboardingViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()

                // Content layer (below step bar)
                ZStack {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        if step == viewModel.currentStep {
                            screenForStep(step, safeAreaBottom: geometry.safeAreaInsets.bottom)
                                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)

                // Step bar layer (absolute positioned at top)
                VStack {
                    topStepBar
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .zIndex(2)
            }
            .ignoresSafeArea(.all, edges: .top)
        }
    }

    // MARK: - Top Step Bar

    private var topStepBar: some View {
        HStack(spacing: 0) {
            // Step indicator
            OnboardingStepIndicator(
                currentStep: viewModel.stepIndex,
                totalSteps: viewModel.totalSteps
            )
            .padding(.horizontal, DesignSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Skip button
            OnboardingSkipButton(action: {
                viewModel.skipOnboarding()
                dismiss()
            })
        }
        .padding(.top, 76)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }

    // MARK: - Screen Builder

    @ViewBuilder
    private func screenForStep(_ step: OnboardingStep, safeAreaBottom: CGFloat) -> some View {
        if step.isPermissionStep {
            OnboardingPermissionScreen(
                step: step,
                viewModel: viewModel,
                safeAreaBottom: safeAreaBottom,
                onNext: {
                    viewModel.completeOnboarding()
                    dismiss()
                }
            )
        } else {
            OnboardingVideoScreen(
                step: step,
                safeAreaBottom: safeAreaBottom,
                onNext: {
                    viewModel.nextStep()
                }
            )
        }
    }
}

#if DEBUG
@available(iOS 14.0, *)
#Preview("Onboarding") {
    OnboardingView(viewModel: OnboardingViewModel())
}
#endif
#endif
