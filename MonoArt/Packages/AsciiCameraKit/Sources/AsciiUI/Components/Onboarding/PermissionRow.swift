#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import AsciiDomain

@available(iOS 13.0, *)
struct PermissionRow: View {
    let permissionType: PermissionType
    @Binding var isGranted: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DesignSpacing.base) {
            // Icon
            iconView
                .frame(width: 24, height: 24)

            // Text content
            VStack(alignment: .leading, spacing: DesignSpacing.s) {
                Text(permissionType.title)
                    .font(.custom("IBMPlexMono-SemiBold", size: 14))
                    .foregroundColor(DesignColor.white)
                    .textCase(.uppercase)
                    .lineSpacing(4)

                Text(permissionType.description)
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(DesignColor.white60)
                    .lineSpacing(0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                // Request permission when tapping the text area
                if !isGranted {
                    onToggle()
                }
            }

            // Toggle switch
            PermissionToggleSwitch(isOn: $isGranted, action: onToggle)
        }
        .padding(DesignSpacing.base)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.md)
                .fill(DesignColor.mainGrey)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = loadIcon() {
            Image(uiImage: iconImage)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(DesignColor.white)
                .scaledToFit()
                .frame(width: 24, height: 24)
        } else {
            // Fallback icon
            Image(systemName: permissionType == .camera ? "camera.fill" : "photo.fill")
                .resizable()
                .foregroundColor(DesignColor.white)
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }

    private func loadIcon() -> UIImage? {
        // Try to load from module bundle
        let fileName = permissionType.iconName
        if let image = UIImage(named: fileName, in: .module, compatibleWith: nil) {
            return image
        }

        return nil
    }
}

#if DEBUG
import AsciiDomain

@available(iOS 13.0, *)
#Preview("Permission Row") {
    VStack(spacing: DesignSpacing.base) {
        PermissionRow(
            permissionType: .camera,
            isGranted: .constant(false),
            onToggle: {}
        )

        PermissionRow(
            permissionType: .photoLibrary,
            isGranted: .constant(true),
            onToggle: {}
        )
    }
    .padding()
    .background(DesignColor.black.ignoresSafeArea())
}
#endif
#endif
