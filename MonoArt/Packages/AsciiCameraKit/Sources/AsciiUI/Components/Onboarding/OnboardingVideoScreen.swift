#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import AsciiDomain

@available(iOS 14.0, *)
struct OnboardingVideoScreen: View {
    let step: OnboardingStep
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

            // Video + Text Block combined (pinned to bottom like step bar to top)
            VStack(spacing: 8) {
                // Video layout container (centered, flexible height, video 682px in overlay)
                Color.clear
                    .frame(width: 327)
                    .frame(minHeight: 200)
                    .overlay(
                        ZStack {
                            // Shadow behind video
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
                                .offset(y: 70)

                            // Video player (full 682px height)
                            ZStack {
                                if let videoName = step.videoName {
                                    OnboardingVideoPlayer(videoName: videoName)
                                } else {
                                    Color.gray.opacity(0.3)
                                }

                                // Overlay gradient - darkens video from top
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.black, location: 0.16417),
                                        .init(color: Color.clear, location: 0.59515)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .frame(width: 327, height: 682)
                            .clipShape(RoundedRectangle(cornerRadius: 62, style: .continuous))
                        },
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
#Preview("Video Screen 1") {
    OnboardingVideoScreen(step: .video1, safeAreaBottom: 34, onNext: {})
}
#endif
#endif
