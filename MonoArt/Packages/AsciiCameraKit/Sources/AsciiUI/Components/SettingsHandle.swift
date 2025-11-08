#if canImport(SwiftUI) && os(iOS)
import SwiftUI

public struct SettingsHandle: View {
    public let onTap: () -> Void

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            if #available(iOS 15.0, *) {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 56, height: 6)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
            } else {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 56, height: 6)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open effect settings")
    }
}
#endif

