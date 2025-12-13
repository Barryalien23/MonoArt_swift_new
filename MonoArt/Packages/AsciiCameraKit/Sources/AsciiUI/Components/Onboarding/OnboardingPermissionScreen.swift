#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import AsciiDomain

@available(iOS 14.0, *)
struct OnboardingPermissionScreen: View {
    let step: OnboardingStep
    @ObservedObject var viewModel: OnboardingViewModel
    let safeAreaBottom: CGFloat
    let onNext: () -> Void

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // ASCII pattern background at 50% opacity
            if let patternImage = UIImage(named: "Ascii pattern", in: .module, compatibleWith: nil) {
                Image(uiImage: patternImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                    .ignoresSafeArea()
            }

            // Permission block + Text Block combined (pinned to bottom like step bar to top)
            VStack(spacing: 8) {
                // Permission layout container (centered, flexible height)
                Color.clear
                    .frame(width: 327)
                    .frame(minHeight: 200)
                    .overlay(
                        ZStack(alignment: .center) {
                            // Shadow behind permission block
                            Ellipse()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.8),
                                            Color.black.opacity(0.4),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 80,
                                        endRadius: 220
                                    )
                                )
                                .frame(width: 400, height: 400)

                            // Permission rows
                            VStack(spacing: 12) {
                                PermissionRow(
                                    permissionType: .camera,
                                    isGranted: $viewModel.hasCameraPermission,
                                    onToggle: {
                                        viewModel.requestCameraPermission()
                                    }
                                )

                                PermissionRow(
                                    permissionType: .photoLibrary,
                                    isGranted: $viewModel.hasPhotoLibraryPermission,
                                    onToggle: {
                                        viewModel.requestPhotoLibraryPermission()
                                    }
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                        }
                        .frame(width: 327, height: 682),
                        alignment: .bottom
                    )

                // Text and button block (fills width like step bar)
                VStack(spacing: 0) {
                    // Text container
                    VStack(alignment: .leading, spacing: 8) {
                        // Title - IBM Plex Mono Semibold 16pt
                        Text(step.title)
                            .font(.custom("IBMPlexMono-SemiBold", size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.46, green: 0.94, blue: 0.54),
                                        Color(red: 0.32, green: 0.82, blue: 0.35)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .textCase(.uppercase)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Description - IBM Plex Mono Medium 20pt
                        Text(step.description)
                            .font(.custom("IBMPlexMono-Medium", size: 20))
                            .tracking(-0.8)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Button container
                    OnboardingPrimaryButton(title: "Next", action: onNext)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, safeAreaBottom)
        }
    }
}

#if DEBUG
@available(iOS 14.0, *)
#Preview("Permission Screen") {
    OnboardingPermissionScreen(
        step: .permissions,
        viewModel: OnboardingViewModel(),
        safeAreaBottom: 34,
        onNext: {}
    )
}
#endif
#endif
