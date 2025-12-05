#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI
import UIKit

@available(iOS 16.0, *)
public struct AboutSheet: View {
    @ObservedObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            DesignColor.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Grabber
                    grabber
                        .padding(.top, DesignSpacing.xs)
                        .padding(.bottom, DesignSpacing.lg)
                    
                    // Title bar with close button
                    titleBar
                        .padding(.bottom, DesignSpacing.lg)
                    
                // Content
                VStack(spacing: DesignSpacing.xxl) {
                    appInfoSection
                    descriptionSection
                    linksSection
                }
                .padding(.bottom, DesignSpacing.xxl)
            }
            .padding(.horizontal, DesignSpacing.xl)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.height(740)])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Components
    
    private var grabber: some View {
        RoundedRectangle(cornerRadius: 100, style: .continuous)
            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
            .frame(width: 36, height: 5)
    }
    
    private var titleBar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color(red: 0.47, green: 0.47, blue: 0.50).opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    )
            }
            .buttonStyle(DesignPressFeedbackStyle())
            
            Spacer()
            
            // Title
            DesignTokens.Typography.head1.text("About")
                .foregroundColor(DesignColor.white)
            
            Spacer()
            
            // Spacer to balance close button
            Color.clear.frame(width: 44, height: 44)
        }
        .frame(height: 44)
    }
    
    private var appInfoSection: some View {
        HStack(spacing: DesignSpacing.base) {
            // App icon
            appIcon
            
            // App name and version
            VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                Text("MonoArt")
                    .font(.custom("IBMPlexMono-Bold", size: 16))
                    .foregroundColor(Color(red: 0.385, green: 0.957, blue: 0.412)) // #62F469
                
                Text("Version 1.0")
                    .font(.custom("IBMPlexMono-Medium", size: 12))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .textCase(.uppercase)
            }
            
            Spacer()
        }
        .padding(.top, DesignSpacing.md)
    }
    
    private var appIcon: some View {
        Group {
            if let iconImage = UIImage(named: "Icon app", in: .module, compatibleWith: nil) {
                Image(uiImage: iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous))
                    .shadow(color: DesignColor.black.opacity(0.3), radius: 0.408, x: 0, y: 0.136)
            } else {
                // Fallback if image not found
                RoundedRectangle(cornerRadius: DesignRadius.xl, style: .continuous)
                    .fill(DesignColor.mainGrey)
                    .frame(width: 48, height: 48)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.base) {
            DesignTokens.Typography.head1.text("Description")
                .foregroundColor(Color(red: 0.385, green: 0.957, blue: 0.412)) // #62F469
            
            Text("MonoArt is a camera & photo app that turns your live preview and imported images into ASCII art. Tweak characters, colors and contrast in real time, then capture or import photos and save glitch-style shots right on your device.")
                .font(.custom("IBMPlexMono-Medium", size: 12))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                .lineSpacing(4)
        }
    }
    
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.base) {
            DesignTokens.Typography.head1.text("Links & Support")
                .foregroundColor(Color(red: 0.385, green: 0.957, blue: 0.412)) // #62F469
            
            VStack(spacing: DesignSpacing.md) {
                LinkButton(
                    icon: .question,
                    title: "How It Works",
                    action: {
                        // TODO: Implement onboarding later
                    }
                )
                
                LinkButton(
                    icon: .star,
                    title: "Rate the app",
                    action: {
                        openURL("https://apps.apple.com/app/idYOUR_APP_ID?action=write-review")
                    }
                )
                
                LinkButton(
                    icon: .shield,
                    title: "Privacy Policy",
                    action: {
                        // TODO: Add Privacy Policy link later
                    }
                )
                
                LinkButton(
                    icon: .monoart,
                    title: "App Website",
                    action: {
                        openURL("https://raux.framer.website")
                    }
                )
                
                LinkButton(
                    icon: .mail,
                    title: "Contact Developer",
                    action: {
                        openURL("https://t.me/AlexandrComp")
                    }
                )
                
                LinkButton(
                    icon: .raLogo,
                    title: "Portfolio",
                    action: {
                        openURL("https://raux.framer.website")
                    }
                )
                
                LinkButton(
                    icon: .telegram,
                    title: "Telegram Channel",
                    action: {
                        openURL("https://t.me/Okolo_designov")
                    }
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Link Button Component

@available(iOS 15.0, *)
private struct LinkButton: View {
    let icon: DesignIcon
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.base) {
                // Icon
                DesignIconView(icon, color: DesignColor.white, size: 24)
                    .frame(width: 24, height: 24)
                
                // Title
                DesignTokens.Typography.body1.text(title)
                    .foregroundColor(DesignColor.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow (using 16pt size for better proportions)
                DesignIconView(.arrowRight, color: DesignColor.white, size: 16)
                    .frame(width: 16, height: 16)
                    .offset(x: -8, y: -2)
            }
            .padding(.horizontal, DesignSpacing.base)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(DesignColor.mainGrey)
            )
        }
        .buttonStyle(DesignPressFeedbackStyle())
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview("About Sheet") {
    AboutSheet(viewModel: AppViewModel())
        .background(DesignColor.black.ignoresSafeArea())
}
#endif
#endif

